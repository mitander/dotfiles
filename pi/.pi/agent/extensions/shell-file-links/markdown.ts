import type { Token } from "@earendil-works/pi-tui";
import { isAbsolute } from "node:path";

const MARKDOWN_CHARS_MAX = 64 * 1024;
const TOKENS_MAX = 2048;
const LINKS_MAX = 64;
const CONTROL = /[\x00-\x1f\x7f-\x9f]/;

/** Resolve URL paths lexically. Never reinterpret a root path as project-relative. */
export function localFileUrl(href: string, cwd: string, home: string): string | undefined {
    if (
        !isAbsolute(cwd) ||
        !isAbsolute(home) ||
        !href ||
        href.startsWith("#") ||
        href.startsWith("//") ||
        /^[a-z][a-z0-9+.-]*:/i.test(href) ||
        href.includes("?")
    ) {
        return undefined;
    }
    const hash = href.indexOf("#");
    let fragment: string;
    let path: string;
    try {
        fragment = hash < 0 ? "" : decodeURIComponent(href.slice(hash + 1));
        path = decodeURIComponent(hash < 0 ? href : href.slice(0, hash));
    } catch (error) {
        if (error instanceof URIError) return undefined;
        throw error;
    }
    if (path.startsWith("~") && !path.startsWith("~/")) return undefined;
    path = path.startsWith("~/")
        ? `${home}/${path.slice(2)}`
        : isAbsolute(path)
          ? path
          : `${cwd}/${path}`;
    if (CONTROL.test(path) || CONTROL.test(fragment) || Buffer.byteLength(path, "utf8") > 4096) {
        return undefined;
    }
    try {
        // Like shell links, preserve symlink/../ semantics instead of using path.resolve.
        const suffix = hash < 0 ? "" : `#${encodeURIComponent(fragment)}`;
        return `file://${path.split("/").map(encodeURIComponent).join("/")}${suffix}`;
    } catch (error) {
        if (error instanceof URIError) return undefined;
        throw error;
    }
}

// Marked removes bracket escapes from link.text. Recover its original spelling
// by matching that decoded text, without reparsing nested label syntax ourselves.
function rawLinkLabel(raw: string, text: string): string | undefined {
    if (!raw.startsWith("[")) return undefined;
    let end = 1;
    for (let index = 0; index < text.length; index++) {
        if (raw[end] === "\\" && (raw[end + 1] === "[" || raw[end + 1] === "]")) end++;
        if (raw[end] !== text[index]) return undefined;
        end++;
    }
    return raw[end] === "]" ? raw.slice(1, end) : undefined;
}

/** Rewrite only parser-recognized links, leaving code, HTML and transcript data alone. */
export function linkMarkdown(
    markdown: string,
    cwd: string,
    home: string,
    lex: (source: string) => Token[],
): string {
    if (markdown.length > MARKDOWN_CHARS_MAX) return markdown;
    let remaining = TOKENS_MAX;
    let links = 0;
    let exhausted = false;

    function rewriteContainer(raw: string, text: string, tokens: Token[], depth: number): string {
        const sourceLines = raw.split("\n");
        const textLines = text.split("\n");
        const prefixes: string[] = [];
        for (const [index, line] of textLines.entries()) {
            const source = sourceLines[index];
            if (source === undefined || !source.endsWith(line)) return raw;
            const prefix = source.slice(0, source.length - line.length);
            if (!/^(?:[ \t>]|[-+*] |\d+[.)] |\[[ xX]\] )*$/.test(prefix)) return raw;
            prefixes.push(prefix);
        }
        if (sourceLines.slice(textLines.length).some((line) => line !== "")) return raw;
        const rewritten = rewrite(text, tokens, depth).split("\n");
        if (rewritten.length !== textLines.length) return raw;
        return rewritten
            .map((line, index) => prefixes[index] + line)
            .concat(sourceLines.slice(textLines.length))
            .join("\n");
    }

    function rewrite(source: string, tokens: Token[], depth: number): string {
        if (depth > 32) {
            exhausted = true;
            return source;
        }
        let end = 0;
        let result = "";
        for (const token of tokens) {
            if (--remaining < 0) {
                exhausted = true;
                return source;
            }
            const start = source.indexOf(token.raw, end);
            // Never search outside the containing token or guess at source alignment.
            if (start < 0) return source;
            let replacement = token.raw;
            if (token.type === "link" && links < LINKS_MAX) {
                const target = localFileUrl(token.href, cwd, home);
                const label = rawLinkLabel(token.raw, token.text);
                if (target && label !== undefined) {
                    const title = token.title
                        ? ` "${token.title.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`
                        : "";
                    replacement = `[${label}](<${target}>${title})`;
                    links++;
                }
            } else if (token.type === "blockquote" || token.type === "list_item") {
                replacement = rewriteContainer(
                    token.raw,
                    token.text,
                    token.tokens ?? [],
                    depth + 1,
                );
            } else if (token.type === "list") {
                replacement = rewrite(token.raw, token.items, depth + 1);
            } else if (token.type === "table") {
                const cells = [...token.header, ...token.rows.flat()];
                replacement = rewrite(
                    token.raw,
                    cells.flatMap((cell) => cell.tokens),
                    depth + 1,
                );
            } else if (token.type !== "image" && "tokens" in token && Array.isArray(token.tokens)) {
                replacement = rewrite(token.raw, token.tokens, depth + 1);
            }
            result += source.slice(end, start) + replacement;
            end = start + token.raw.length;
        }
        return result + source.slice(end);
    }

    const result = rewrite(markdown, lex(markdown), 0);
    return exhausted ? markdown : result;
}
