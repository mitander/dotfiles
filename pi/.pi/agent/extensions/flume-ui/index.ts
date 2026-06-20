import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { basename } from "node:path";

const ANSI_PATTERN = /\x1B(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1B\\)|[@-Z\\-_])/g;
const ANSI_PREFIX_PATTERN = /^\x1B(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1B\\)|[@-Z\\-_])/;

type Phase = "idle" | "thinking" | "tools";
type IndicatorStyle = "state" | "dot" | "wave" | "spinner";

let enabled = true;
let phase: Phase = "idle";
let indicatorStyle: IndicatorStyle = "state";
let bottomPadding = false;
let turnCount = 0;
let frame = 0;
let requestRender: (() => void) | undefined;
let animationTimer: ReturnType<typeof setInterval> | undefined;

function visibleWidth(text: string): number {
	return text.replace(ANSI_PATTERN, "").length;
}

function truncateToWidth(text: string, width: number, ellipsis = "…"): string {
	if (width <= 0) return "";
	if (visibleWidth(text) <= width) return text;

	const targetWidth = Math.max(0, width - visibleWidth(ellipsis));
	let out = "";
	let used = 0;
	let index = 0;

	while (index < text.length && used < targetWidth) {
		const rest = text.slice(index);
		const ansi = rest.match(ANSI_PREFIX_PATTERN)?.[0];
		if (ansi) {
			out += ansi;
			index += ansi.length;
			continue;
		}

		const char = Array.from(rest)[0] ?? "";
		if (!char) break;
		if (used + 1 > targetWidth) break;
		out += char;
		used += 1;
		index += char.length;
	}

	return out + ellipsis;
}

function fmtNumber(n: number): string {
	if (!Number.isFinite(n) || n <= 0) return "0";
	if (n < 1_000) return `${Math.round(n)}`;
	if (n < 1_000_000) return `${(n / 1_000).toFixed(n < 10_000 ? 1 : 0)}k`;
	return `${(n / 1_000_000).toFixed(1)}m`;
}

function modelLabel(ctx: any): string {
	return ctx.model?.id ?? "no-model";
}

function collectUsage(ctx: any): { input: number; output: number; cost: number } {
	let input = 0;
	let output = 0;
	let cost = 0;

	for (const entry of ctx.sessionManager.getBranch()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;
		const message = entry.message as any;
		input += message.usage?.input ?? 0;
		output += message.usage?.output ?? 0;
		cost += message.usage?.cost?.total ?? 0;
	}

	return { input, output, cost };
}

function contextLabel(ctx: any): { text: string; color: string } | undefined {
	const usage = ctx.getContextUsage?.();
	const tokens = usage?.tokens;
	if (typeof tokens !== "number" || !Number.isFinite(tokens)) return undefined;

	const window = ctx.model?.contextWindow;
	if (typeof window === "number" && window > 0) {
		const percent = Math.round((tokens / window) * 100);
		let color = "thinkingMedium";
		if (percent >= 90) {
			color = "error";
		} else if (percent >= 70) {
			color = "warning";
		}
		return { text: `ctx ${percent}%`, color };
	}

	return { text: `ctx ${fmtNumber(tokens)}`, color: "thinkingMedium" };
}

function phaseColor(): string {
	switch (phase) {
		case "idle":
			return "success";
		case "thinking":
			return "thinkingMedium";
		case "tools":
			return "warning";
	}

	const exhaustive: never = phase;
	return exhaustive;
}

function animatedFrame(frames: string[], idleFrame: string): string {
	return phase === "idle" ? idleFrame : frames[frame % frames.length];
}

function phaseIndicator(theme: any): string {
	switch (indicatorStyle) {
		case "dot":
			return theme.fg(phaseColor(), "●");
		case "wave":
			return theme.fg(phaseColor(), animatedFrame(["·", "•", "●", "•"], "·"));
		case "spinner":
			return theme.fg(phaseColor(), animatedFrame(["-", "\\", "|", "/"], "-"));
		case "state": {
			const symbols: Record<Phase, string> = { idle: "○", thinking: "◐", tools: "◆" };
			return theme.fg(phaseColor(), symbols[phase]);
		}
	}

	const exhaustive: never = indicatorStyle;
	return exhaustive;
}

function phaseLabel(theme: any): string {
	switch (phase) {
		case "idle":
			return theme.fg("dim", "idle");
		case "thinking":
			return theme.fg("muted", `turn ${turnCount}`);
		case "tools":
			return theme.fg("warning", "tools");
	}

	const exhaustive: never = phase;
	return exhaustive;
}

function renderFooterLine(width: number, ctx: any, theme: any, footerData: any): string[] {
	const usage = collectUsage(ctx);
	const cwd = basename(ctx.cwd) || ctx.cwd;
	const branch = footerData.getGitBranch();
	const statuses = Array.from(footerData.getExtensionStatuses().values()).filter(
		(value): value is string => typeof value === "string" && value.length > 0,
	);
	const ctxText = contextLabel(ctx);
	const sep = theme.fg("borderMuted", " │ ");

	const location = branch ? theme.fg("success", branch) : theme.fg("accent", cwd);
	const left = [theme.fg("accent", "π"), `${phaseIndicator(theme)} ${phaseLabel(theme)}`, location].join(sep);

	const right = [
		theme.fg("syntaxKeyword", modelLabel(ctx)),
		ctxText ? theme.fg(ctxText.color, ctxText.text) : undefined,
		theme.fg("muted", `↑${fmtNumber(usage.input)} ↓${fmtNumber(usage.output)}`),
		usage.cost > 0 ? theme.fg("warning", `$${usage.cost.toFixed(3)}`) : undefined,
	]
		.filter((part): part is string => Boolean(part))
		.join(sep);

	const statusRaw = statuses.length > 0 ? statuses.join(sep) : "";
	const innerPadding = 0;
	const contentWidth = Math.max(1, width - innerPadding * 2);
	const reserved = visibleWidth(left) + visibleWidth(right) + 1;
	const statusMax = Math.max(0, contentWidth - reserved - (statusRaw ? visibleWidth(sep) : 0));
	const middle = statusRaw && statusMax > 8 ? sep + truncateToWidth(statusRaw, statusMax, "…") : "";
	const core = left + middle;
	const gap = " ".repeat(Math.max(1, contentWidth - visibleWidth(core) - visibleWidth(right)));
	const line = " ".repeat(innerPadding) + core + gap + right + " ".repeat(innerPadding);

	const renderedLine = truncateToWidth(line, width, "");
	if (!bottomPadding) return [renderedLine];

	// Risky but requested: Pi does not expose footer padding directly, so bottom
	// breathing room means rendering one extra blank footer line. Keep it exactly
	// one line and exactly terminal width to reduce tmux redraw artifacts.
	return [renderedLine, " ".repeat(Math.max(0, width))];
}

function stopAnimation(): void {
	if (!animationTimer) return;
	clearInterval(animationTimer);
	animationTimer = undefined;
}

function syncAnimation(): void {
	const animated = enabled && phase !== "idle" && (indicatorStyle === "wave" || indicatorStyle === "spinner");
	if (!animated) {
		stopAnimation();
		return;
	}

	if (animationTimer) return;
	animationTimer = setInterval(() => {
		frame += 1;
		requestRender?.();
	}, 140);
}

function installFooter(ctx: any): void {
	if (!ctx.hasUI || !enabled) return;

	ctx.ui.setStatus("flume-ui", undefined);
	ctx.ui.setFooter((tui: any, theme: any, footerData: any) => {
		requestRender = () => tui.requestRender();
		const unsubscribeBranch = footerData.onBranchChange(() => tui.requestRender());
		syncAnimation();

		return {
			dispose: () => {
				requestRender = undefined;
				unsubscribeBranch();
				stopAnimation();
			},
			invalidate() {},
			render(width: number): string[] {
				return renderFooterLine(width, ctx, theme, footerData);
			},
		};
	});
}

function uninstallFooter(ctx: any): void {
	if (!ctx.hasUI) return;
	requestRender = undefined;
	stopAnimation();
	ctx.ui.setFooter(undefined);
	ctx.ui.setStatus("flume-ui", undefined);
}

function refresh(): void {
	syncAnimation();
	requestRender?.();
}

function parseToggle(choice: string, current: boolean, resetAliases = false): boolean {
	switch (choice) {
		case "on":
			return true;
		case "off":
			return false;
		case "default":
		case "reset":
			return resetAliases ? false : !current;
		default:
			return !current;
	}
}

export default function flumeUi(pi: ExtensionAPI): void {
	pi.on("session_start", async (_event, ctx) => {
		phase = "idle";
		installFooter(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		uninstallFooter(ctx);
	});

	pi.on("agent_start", async () => {
		phase = "thinking";
		refresh();
	});

	pi.on("turn_start", async () => {
		turnCount += 1;
		phase = "thinking";
		refresh();
	});

	pi.on("tool_execution_start", async () => {
		phase = "tools";
		refresh();
	});

	pi.on("agent_end", async () => {
		phase = "idle";
		refresh();
	});

	pi.on("model_select", async () => refresh());
	pi.on("thinking_level_select", async () => refresh());
	pi.on("message_end", async () => refresh());

	pi.registerCommand("flume-footer", {
		description: "Toggle the Flume one-line footer/statusbar",
		handler: async (args, ctx) => {
			enabled = parseToggle(args.trim().toLowerCase(), enabled, true);

			if (enabled) {
				installFooter(ctx);
				ctx.ui.notify("Flume one-line footer enabled", "info");
			} else {
				uninstallFooter(ctx);
				ctx.ui.notify("Flume footer disabled; default footer restored", "info");
			}
		},
	});

	pi.registerCommand("flume-footer-padding", {
		description: "Toggle risky one-line bottom padding for the Flume footer",
		handler: async (args, ctx) => {
			bottomPadding = parseToggle(args.trim().toLowerCase(), bottomPadding);
			requestRender?.();
			ctx.ui.notify(`Flume footer bottom padding: ${bottomPadding ? "on" : "off"}`, "info");
		},
	});

	pi.registerCommand("flume-footer-style", {
		description: "Set footer indicator style: state, dot, wave, spinner",
		handler: async (args, ctx) => {
			const choice = args.trim().toLowerCase();
			if (["state", "dot", "wave", "spinner"].includes(choice)) {
				indicatorStyle = choice as IndicatorStyle;
			} else if (choice.length === 0) {
				const order: IndicatorStyle[] = ["state", "dot", "wave", "spinner"];
				indicatorStyle = order[(order.indexOf(indicatorStyle) + 1) % order.length];
			} else {
				ctx.ui.notify("Usage: /flume-footer-style state|dot|wave|spinner", "warning");
				return;
			}

			syncAnimation();
			requestRender?.();
			ctx.ui.notify(`Flume footer indicator style: ${indicatorStyle}`, "info");
		},
	});
}
