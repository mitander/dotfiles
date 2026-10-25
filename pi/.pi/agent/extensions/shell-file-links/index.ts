import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getCapabilities, hyperlink } from "@earendil-works/pi-tui";
import { homedir } from "node:os";
import { linkShellCommand } from "./links.ts";

interface CachedCommand {
    command: string;
    cwd: string;
    linked: string;
}

export default function shellFileLinks(pi: ExtensionAPI): void {
    const cache = new WeakMap<object, CachedCommand>();
    const home = homedir();
    pi.registerToolRenderer((toolName, next) => {
        const renderers = next();
        if (toolName !== "bash" || !renderers?.renderCall) return renderers;
        const renderCall = renderers.renderCall.bind(renderers);
        return {
            ...renderers,
            renderCall(args, theme, context) {
                if (
                    !getCapabilities().hyperlinks ||
                    typeof args !== "object" ||
                    args === null ||
                    !("command" in args) ||
                    typeof args.command !== "string"
                ) {
                    return renderCall(args, theme, context);
                }
                const cwd = context.cwd;
                if (typeof cwd !== "string") return renderCall(args, theme, context);
                let entry = cache.get(context.state);
                if (!entry || entry.command !== args.command || entry.cwd !== cwd) {
                    entry = {
                        command: args.command,
                        cwd,
                        linked: linkShellCommand(args.command, cwd, home, hyperlink),
                    };
                    cache.set(context.state, entry);
                }
                // Copy rendering arguments only. Never change context.args, tool input, or execution.
                return renderCall({ ...args, command: entry.linked }, theme, context);
            },
        };
    });
}
