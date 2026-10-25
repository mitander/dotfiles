import { isAbsolute } from "node:path";

const COMMAND_CHARS_MAX = 64 * 1024;
const WORDS_MAX = 256;
const LINKS_MAX = 64;
const SHELL_WHITESPACE = /[ \t\n]/;

interface ShellWord {
    start: number;
    end: number;
    value: string;
    literal: boolean;
}

// This is a literal-word scanner, not a shell evaluator. Decline constructs whose
// word boundaries need a full grammar, including substitutions, groups and here-docs.
function literalWords(command: string): ShellWord[] {
    const words: ShellWord[] = [];
    let index = 0;
    while (index < command.length) {
        const character = command.charAt(index);
        if (SHELL_WHITESPACE.test(character) || ";&|<>".includes(character)) {
            if (command.startsWith("<<", index)) return [];
            index++;
            continue;
        }
        if (character === "#") {
            const newline = command.indexOf("\n", index);
            index = newline < 0 ? command.length : newline + 1;
            continue;
        }
        const start = index;
        let value = "";
        let quote: "'" | '"' | undefined;
        let literal = true;
        while (index < command.length) {
            const character = command.charAt(index);
            if (!quote && (SHELL_WHITESPACE.test(character) || ";&|<>".includes(character))) break;
            if (quote !== "'") {
                if (
                    character === "`" ||
                    (character === "$" && "({'\"".includes(command[index + 1] ?? "\0")) ||
                    (!quote && "()".includes(character))
                ) {
                    return [];
                }
                if (character === "\\") {
                    const next = command[index + 1];
                    if (next === undefined) return [];
                    if (!quote || '$`"\\\n'.includes(next)) {
                        if (next !== "\n") value += next;
                        index += 2;
                        continue;
                    }
                }
                if (character === "$" || (!quote && "*?[]{}!".includes(character))) literal = false;
            }
            if (character === quote) {
                quote = undefined;
            } else if (!quote && (character === "'" || character === '"')) {
                quote = character;
            } else {
                value += character;
            }
            index++;
        }
        if (quote || words.length === WORDS_MAX) return [];
        words.push({ start, end: index, value, literal });
    }
    return words;
}

function fileTarget(
    word: ShellWord,
    command: string,
    cwd: string,
    home: string,
): string | undefined {
    const value = word.value;
    if (!word.literal || !value || /[\x00-\x1f\x7f-\x9f]/.test(value)) return undefined;
    if (value.startsWith("-") || /^[a-z_][a-z_0-9]*=/i.test(value)) return undefined;
    if (/^[a-z][a-z0-9+.-]*:/i.test(value)) return undefined;

    const explicit = /^(?:\/|\.\.?\/|~\/)/.test(value);
    if (!explicit && (/[(){}<>|]/.test(value) || !/[/.]/.test(value))) return undefined;
    if (value.endsWith("/") || value === "." || value === "..") return undefined;
    // Only a wholly unquoted ~/ prefix expands. Decline mixed quoting and other users' homes.
    const raw = command.slice(word.start, word.end);
    if (raw.startsWith("~") && !raw.startsWith("~/")) return undefined;
    const expanded = raw.startsWith("~/");
    const path = expanded
        ? `${home}/${value.slice(2)}`
        : isAbsolute(value)
          ? value
          : `${cwd}/${value}`;
    if (Buffer.byteLength(path, "utf8") > 4096) return undefined;
    try {
        // Do not use path.resolve/pathToFileURL: collapsing symlink/../ can target a different file.
        return `file://${path.split("/").map(encodeURIComponent).join("/")}`;
    } catch (error) {
        if (error instanceof URIError) return undefined;
        throw error;
    }
}

/** Decorate literal path-like words only. Command text, separators and execution stay unchanged. */
export function linkShellCommand(
    command: string,
    cwd: string,
    home: string,
    hyperlink: (label: string, target: string) => string,
): string {
    if (
        command.length > COMMAND_CHARS_MAX ||
        // Continuations can join operators and comment markers across scanner boundaries.
        command.includes("\\\n") ||
        !isAbsolute(cwd) ||
        !isAbsolute(home) ||
        /[\x00-\x08\x0b-\x1f\x7f-\x9f]/.test(command)
    ) {
        return command;
    }
    let relativePaths = true;
    let previous = "";
    let end = 0;
    let links = 0;
    let result = "";
    for (const word of literalWords(command)) {
        const assignment = /^[a-z_][a-z_0-9]*=/i.test(word.value);
        const changesHome = /^(?:HOME|PWD|CDPATH)=/.test(word.value);
        if (
            ["cd", "pushd", "popd", "source", ".", "eval", "-C"].includes(word.value) ||
            changesHome ||
            (!word.literal && !assignment)
        ) {
            relativePaths = false;
        }
        const embeddedScript = ["-c", "-e", "--command", "--eval"].includes(previous);
        previous = word.value;
        if (embeddedScript || (!relativePaths && !isAbsolute(word.value))) continue;
        const target = fileTarget(word, command, cwd, home);
        if (!target || links === LINKS_MAX) continue;
        result +=
            command.slice(end, word.start) + hyperlink(command.slice(word.start, word.end), target);
        end = word.end;
        links++;
    }
    return result + command.slice(end);
}
