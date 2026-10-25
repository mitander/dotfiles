import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { homedir, tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { stripVTControlCharacters } from "node:util";

const agentDirectory = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi/agent");
let packageDirectory = process.env.PI_PACKAGE_DIR;
if (!packageDirectory) {
    const version = readFileSync(join(agentDirectory, "install/current-version"), "utf8").trim();
    packageDirectory = join(
        agentDirectory,
        "install/releases",
        version,
        "node_modules/@earendil-works/pi-coding-agent",
    );
}
const require = createRequire(join(packageDirectory, "package.json"));
const tuiPath = require.resolve("@earendil-works/pi-tui");
const root = resolve(fileURLToPath(new URL("..", import.meta.url)));

// Bind types to the installed host without checking machine-local paths into tsconfig.json.
const typecheckDirectory = mkdtempSync(join(tmpdir(), "dotfiles-types-"));
try {
    const config = join(typecheckDirectory, "tsconfig.json");
    writeFileSync(
        config,
        JSON.stringify({
            extends: join(root, "tsconfig.json"),
            compilerOptions: {
                paths: {
                    "@earendil-works/pi-coding-agent": [join(packageDirectory, "dist/index.d.ts")],
                    "@earendil-works/pi-tui": [join(dirname(tuiPath), "index.d.ts")],
                },
                typeRoots: [dirname(dirname(require.resolve("@types/node/package.json")))],
            },
        }),
    );
    execFileSync("tsc", ["--project", config], { cwd: root, stdio: "inherit" });
} finally {
    rmSync(typecheckDirectory, { recursive: true, force: true });
}
console.log("PASS: strict TypeScript checks against the installed Pi host");

const tui = await import(pathToFileURL(tuiPath).href);
const pi = await import(pathToFileURL(join(packageDirectory, "dist/index.js")).href);
const { theme } = await import(
    pathToFileURL(join(packageDirectory, "dist/modes/interactive/theme/theme.js")).href
);
const { createJiti } = require("jiti");
const jiti = createJiti(import.meta.url, {
    moduleCache: false,
    alias: { "@earendil-works/pi-tui": tuiPath },
});
const extension = await jiti.import(
    join(root, "pi/.pi/agent/extensions/shell-file-links/index.ts"),
    { default: true },
);
let resolver;
extension({
    registerToolRenderer(value) {
        resolver = value;
    },
});
assert.equal(typeof resolver, "function");
pi.initTheme("dark", false);
tui.setCapabilityOverrides({ hyperlinks: true });
const original = pi.createBashToolDefinition(root);
const base = {
    renderCall: original.renderCall,
    renderResult: original.renderResult,
    renderShell: original.renderShell,
};
const renderers = resolver("bash", () => base);
assert.equal(renderers.renderResult, base.renderResult);
assert.equal(renderers.renderShell, base.renderShell);
assert.equal(
    resolver("read", () => base),
    base,
);
assert.equal(
    resolver("bash", () => undefined),
    undefined,
);

const args = Object.freeze({
    command: 'tail -16 .build/client-wait.json; exit "$result"',
    timeout: 25,
});
const context = {
    args,
    toolCallId: "fixture",
    invalidate() {},
    state: {},
    cwd: "/workspace/project",
    executionStarted: false,
    argsComplete: true,
    isPartial: true,
    expanded: false,
    showImages: false,
    isError: false,
    outputPad: 1,
};
let component = renderers.renderCall(args, theme, context);
for (const width of [12, 32, 80, 180]) {
    const lines = component.render(width);
    assert.ok(lines.every((line) => tui.visibleWidth(line) <= width));
    assert.ok(lines.join("\n").includes("file:///workspace/project/.build/client-wait.json"));
}
const row = component.render(180)[0];
const plain = stripVTControlCharacters(row);
const file = ".build/client-wait.json";
const column = plain.indexOf(file);
assert.ok(column > 0);
assert.equal(
    tui.getOsc8LinkAtColumn(row, column),
    "file:///workspace/project/.build/client-wait.json",
);
assert.equal(tui.getOsc8LinkAtColumn(row, column + file.length), undefined);
assert.equal(plain.trimEnd(), '$ tail -16 .build/client-wait.json; exit "$result" (timeout 25s)');
assert.equal(context.args, args);
assert.equal(args.command, 'tail -16 .build/client-wait.json; exit "$result"');

context.lastComponent = component;
context.cwd = "/different/project";
component = renderers.renderCall(args, theme, context);
assert.ok(
    component.render(180).join("\n").includes("file:///different/project/.build/client-wait.json"),
);
tui.setCapabilityOverrides({ hyperlinks: false });
component = renderers.renderCall(args, theme, context);
assert.ok(!component.render(180).join("\n").includes("\x1b]8;"));
assert.equal(context.args, args);
tui.setCapabilityOverrides({ hyperlinks: true });
const unicodeArgs = Object.freeze({ command: 'cat "./世界 file.json"; echo done' });
context.args = unicodeArgs;
component = renderers.renderCall(unicodeArgs, theme, context);
for (const width of [10, 16, 80]) {
    assert.ok(component.render(width).every((line) => tui.visibleWidth(line) <= width));
}
assert.equal(context.args, unicodeArgs);
console.log(
    "PASS: installed Pi renderer composition, unmodified inputs, link boundaries, Unicode wrapping, cwd cache, capability fallback",
);

const flumeUi = await jiti.import(join(root, "pi/.pi/agent/extensions/flume-ui/index.ts"), {
    default: true,
});
const handlers = new Map();
flumeUi({
    on(event, handler) {
        handlers.set(event, handler);
    },
});
let footer;
let branchChanged;
let renders = 0;
let unsubscribed = 0;
const footerContext = {
    mode: "tui",
    cwd: "/workspace/project",
    model: { id: "fixture-model", contextWindow: 200000 },
    getContextUsage: () => ({ percent: 25, tokens: 50000, contextWindow: 200000 }),
    sessionManager: {
        getBranch: () => [
            { type: "message", message: { role: "user", content: "hello" } },
            {
                type: "message",
                message: {
                    role: "assistant",
                    usage: { input: 1500, output: 12, cost: { total: 0.125 } },
                },
            },
        ],
    },
    ui: {
        setFooter(factory) {
            footer?.dispose();
            footer = factory?.({ requestRender: () => renders++ }, theme, {
                getGitBranch: () => "topic",
                getExtensionStatuses: () => new Map([["context-watch", "ctx 25%"]]),
                onBranchChange(callback) {
                    branchChanged = callback;
                    return () => unsubscribed++;
                },
            });
        },
    },
};
await handlers.get("session_start")({}, footerContext);
for (const width of [1, 16, 80, 200]) {
    assert.ok(footer.render(width).every((line) => tui.visibleWidth(line) <= width));
}
const footerText = () => stripVTControlCharacters(footer.render(200).join("\n"));
assert.match(footerText(), /idle/);
assert.match(footerText(), /topic.*ctx 25%.*fixture-model.*↑1\.5k ↓12.*\$0\.125/);
assert.equal(footerText().match(/ctx 25%/g).length, 1);
branchChanged();
assert.ok(renders > 0);
await handlers.get("turn_start")({});
assert.match(footerText(), /turn 1/);
await handlers.get("tool_execution_start")({});
assert.match(footerText(), /tools/);
await handlers.get("agent_end")({});
assert.match(footerText(), /idle/);
await handlers.get("session_shutdown")({}, footerContext);
assert.equal(footer, undefined);
assert.equal(unsubscribed, 1);
await handlers.get("session_start")({}, footerContext);
await handlers.get("turn_start")({});
assert.match(footerText(), /turn 1/);
await handlers.get("session_shutdown")({}, footerContext);
for (const mode of ["rpc", "print"]) {
    const nonTerminal = {
        ...footerContext,
        mode,
        ui: { setFooter: () => assert.fail("non-terminal sessions must not install a footer") },
    };
    await handlers.get("session_start")({}, nonTerminal);
    await handlers.get("session_shutdown")({}, nonTerminal);
}
console.log(
    "PASS: installed Pi footer rendering, event updates, session cleanup and non-terminal modes",
);
