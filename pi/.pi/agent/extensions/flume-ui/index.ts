import type {
    ExtensionAPI,
    ExtensionContext,
    ReadonlyFooterDataProvider,
    Theme,
    ThemeColor,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { basename } from "node:path";

const ANSI_PATTERN = /\x1B(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1B\\)|[@-Z\\-_])/g;
const CONTEXT_WARNING_PERCENT = 70;
const CONTEXT_DANGER_PERCENT = 90;

type Phase = "idle" | "thinking" | "tools";

let phase: Phase = "idle";
let turnCount = 0;
let requestRender: (() => void) | undefined;

function fmtNumber(n: number): string {
    if (!Number.isFinite(n) || n <= 0) return "0";
    if (n < 1_000) return `${Math.round(n)}`;
    if (n < 1_000_000) return `${(n / 1_000).toFixed(n < 10_000 ? 1 : 0)}k`;
    return `${(n / 1_000_000).toFixed(1)}m`;
}

function collectUsage(ctx: ExtensionContext): { input: number; output: number; cost: number } {
    let input = 0;
    let output = 0;
    let cost = 0;

    for (const entry of ctx.sessionManager.getBranch()) {
        if (entry.type !== "message" || entry.message.role !== "assistant") continue;
        input += entry.message.usage?.input ?? 0;
        output += entry.message.usage?.output ?? 0;
        cost += entry.message.usage?.cost?.total ?? 0;
    }

    return { input, output, cost };
}

function contextLabel(ctx: ExtensionContext): { text: string; color: ThemeColor } {
    const usage = ctx.getContextUsage();
    const usagePercent = usage?.percent;
    const tokens = usage?.tokens;
    const window = usage?.contextWindow ?? ctx.model?.contextWindow;

    if (typeof usagePercent === "number" && Number.isFinite(usagePercent)) {
        const percent = Math.round(usagePercent);
        const color =
            percent >= CONTEXT_DANGER_PERCENT
                ? "error"
                : percent >= CONTEXT_WARNING_PERCENT
                  ? "warning"
                  : "muted";
        return { text: `ctx ${percent}%`, color };
    }

    if (typeof tokens === "number" && Number.isFinite(tokens)) {
        return { text: `ctx ${fmtNumber(tokens)}`, color: "muted" };
    }

    return { text: window ? "ctx ?%" : "ctx ?", color: "muted" };
}

function isContextStatus(value: string): boolean {
    const plain = value.replace(ANSI_PATTERN, "").trim();
    return /^(?:⚠\s*)?(?:ctx|Context)\s+(?:\d+(?:\.\d+)?|\?)%?/i.test(plain);
}

function phaseLabel(theme: Theme): string {
    switch (phase) {
        case "idle":
            return `${theme.fg("success", "○")} ${theme.fg("dim", "idle")}`;
        case "thinking":
            return `${theme.fg("thinkingMedium", "◐")} ${theme.fg("muted", `turn ${turnCount}`)}`;
        case "tools":
            return theme.fg("warning", "◆ tools");
    }
}

function renderFooterLine(
    width: number,
    ctx: ExtensionContext,
    theme: Theme,
    footerData: ReadonlyFooterDataProvider,
): string[] {
    const usage = collectUsage(ctx);
    const cwd = basename(ctx.cwd) || ctx.cwd;
    const branch = footerData.getGitBranch();
    const statuses = Array.from(footerData.getExtensionStatuses().values()).filter(
        (value) => value.length > 0 && !isContextStatus(value),
    );
    const ctxText = contextLabel(ctx);
    const sep = theme.fg("borderMuted", " │ ");

    const location = branch ? theme.fg("success", branch) : theme.fg("accent", cwd);
    const left = [
        theme.fg("accent", "π"),
        phaseLabel(theme),
        location,
        theme.fg(ctxText.color, ctxText.text),
    ].join(sep);

    const right = [
        theme.fg("syntaxKeyword", ctx.model?.id ?? "no-model"),
        theme.fg("muted", `↑${fmtNumber(usage.input)} ↓${fmtNumber(usage.output)}`),
        usage.cost > 0 ? theme.fg("warning", `$${usage.cost.toFixed(3)}`) : undefined,
    ]
        .filter((part): part is string => Boolean(part))
        .join(sep);

    const statusRaw = statuses.length > 0 ? statuses.join(sep) : "";
    const innerPadding = 1;
    const contentWidth = Math.max(1, width - innerPadding * 2);
    const reserved = visibleWidth(left) + visibleWidth(right) + 1;
    const statusMax = Math.max(0, contentWidth - reserved - (statusRaw ? visibleWidth(sep) : 0));
    const middle =
        statusRaw && statusMax > 8 ? sep + truncateToWidth(statusRaw, statusMax, "…") : "";
    const core = left + middle;
    const gap = " ".repeat(Math.max(1, contentWidth - visibleWidth(core) - visibleWidth(right)));
    const line = " ".repeat(innerPadding) + core + gap + right + " ".repeat(innerPadding);

    // A terminal-width blank line below the footer reduces tmux redraw artifacts.
    return [truncateToWidth(line, width, ""), " ".repeat(Math.max(0, width))];
}

export default function flumeUi(pi: ExtensionAPI): void {
    pi.on("session_start", (_event, ctx) => {
        phase = "idle";
        turnCount = 0;
        if (ctx.mode !== "tui") return;

        ctx.ui.setFooter((tui, theme, footerData) => {
            requestRender = () => tui.requestRender();
            const unsubscribeBranch = footerData.onBranchChange(requestRender);

            return {
                dispose() {
                    requestRender = undefined;
                    unsubscribeBranch();
                },
                invalidate() {},
                render: (width) => renderFooterLine(width, ctx, theme, footerData),
            };
        });
    });

    pi.on("session_shutdown", (_event, ctx) => {
        requestRender = undefined;
        if (ctx.mode === "tui") ctx.ui.setFooter(undefined);
    });

    pi.on("agent_start", () => {
        phase = "thinking";
        requestRender?.();
    });

    pi.on("turn_start", () => {
        turnCount += 1;
        phase = "thinking";
        requestRender?.();
    });

    pi.on("tool_execution_start", () => {
        phase = "tools";
        requestRender?.();
    });

    pi.on("agent_end", () => {
        phase = "idle";
        requestRender?.();
    });

    pi.on("model_select", () => requestRender?.());
    pi.on("thinking_level_select", () => requestRender?.());
    pi.on("message_end", () => requestRender?.());
}
