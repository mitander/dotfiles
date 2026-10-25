import assert from "node:assert/strict";
import test from "node:test";
import { linkShellCommand } from "../pi/.pi/agent/extensions/shell-file-links/links.ts";

const cwd = "/workspace/project";
const home = "/home/example";

function render(command: string) {
    const links: { label: string; target: string }[] = [];
    const text = linkShellCommand(command, cwd, home, (label, target) => {
        links.push({ label, target });
        return `\x1b]8;;${target}\x1b\\${label}\x1b]8;;\x1b\\`;
    });
    // Independent observation: removing only the added OSC 8 sequences must restore every byte.
    assert.equal(text.replace(/\x1b\]8;;[^\x1b]*\x1b\\/g, ""), command);
    return { text, links };
}

test("shell separators stay outside literal file links", () => {
    const command =
        'infra wait > .build/client-wait.json; result=$?; tail -16 .build/client-wait.json; exit "$result"';
    const { text, links } = render(command);
    assert.deepEqual(links, [
        {
            label: ".build/client-wait.json",
            target: "file:///workspace/project/.build/client-wait.json",
        },
        {
            label: ".build/client-wait.json",
            target: "file:///workspace/project/.build/client-wait.json",
        },
    ]);
    assert.ok(text.includes(".build/client-wait.json\x1b]8;;\x1b\\;"));
    const operators = render("cat ./a.json&&cat ./b.json|tee ./out.json\ncat ./last.json#literal");
    assert.deepEqual(
        operators.links.map((link) => link.label),
        ["./a.json", "./b.json", "./out.json", "./last.json#literal"],
    );
});

test("quoted and escaped punctuation remains filename data", () => {
    const { links } = render(
        "cat 'a; b.json' ./a\\;b.json \"./世界 & # %.json\" './$(literal).json'",
    );
    assert.deepEqual(links, [
        { label: "'a; b.json'", target: "file:///workspace/project/a%3B%20b.json" },
        { label: "./a\\;b.json", target: "file:///workspace/project/./a%3Bb.json" },
        {
            label: '\"./世界 & # %.json\"',
            target: "file:///workspace/project/./%E4%B8%96%E7%95%8C%20%26%20%23%20%25.json",
        },
        { label: "'./$(literal).json'", target: "file:///workspace/project/./%24(literal).json" },
    ]);
});

test("Bash treats Unicode spaces as literal filename data", () => {
    for (const [space, encoded] of [
        ["\u00a0", "%C2%A0"],
        ["\u2003", "%E2%80%83"],
        ["\u2028", "%E2%80%A8"],
    ]) {
        const { links } = render(`cat ./a${space}b.json`);
        assert.deepEqual(links, [
            { label: `./a${space}b.json`, target: `file:///workspace/project/./a${encoded}b.json` },
        ]);
    }
});

test("relative and tilde paths preserve their shell meaning", () => {
    const { links } = render("cat link/../file.json ~/a.json '~/b.json' ./file\\ name.json");
    assert.deepEqual(
        links.map((link) => link.target),
        [
            "file:///workspace/project/link/../file.json",
            "file:///home/example/a.json",
            "file:///workspace/project/~/b.json",
            "file:///workspace/project/./file%20name.json",
        ],
    );
    assert.deepEqual(render("cat ~someone/file.json").links, []);
    assert.deepEqual(render("cat ~\"/a.json\" ~''/a.json ~\\//a.json").links, []);
    assert.deepEqual(
        render('cat ~/"a.json" "~"/b.json').links.map((link) => link.target),
        ["file:///home/example/a.json", "file:///workspace/project/~/b.json"],
    );
    assert.deepEqual(render("HOME=/different; cat ~/file.json").links, []);
    assert.deepEqual(render("$command ./sub; cat file.json").links, []);
    const changed = render("cd ./sub; cat file.json /tmp/absolute.json");
    assert.deepEqual(changed.links, [
        { label: "/tmp/absolute.json", target: "file:///tmp/absolute.json" },
    ]);
});

test("comments, scripts, expansions, URLs and option values are not guessed", () => {
    const { links } = render(
        'python -c \'open("./script.json")\'; cat ./real.json # ./comment.json\ncurl https://example.com/a.json --out=other.json "$HOME/a.json" ./glob*.json',
    );
    assert.deepEqual(links, [
        { label: "./real.json", target: "file:///workspace/project/./real.json" },
    ]);
    for (const command of [
        "cat $(echo ./file.json)",
        "cat ${ROOT}/file.json",
        "cat `echo ./file.json`",
        "cat <<'END'\n./not-shell.json;\nEND",
        "(cd sub; cat file.json)",
        "cat 'unclosed.json",
        "cat ./file.json\\",
        "cat $'./file.json'",
    ]) {
        assert.equal(render(command).text, command);
        assert.deepEqual(render(command).links, []);
    }
});

test("line continuations cannot disguise heredocs or comments", () => {
    for (const command of [
        "cat <\\\n<EOF\n./not-shell.json\nEOF",
        "echo ready; \\\n# ./comment.json\ncat ./real.json",
        "cat ./continued\\\n.json",
    ]) {
        const { text, links } = render(command);
        assert.equal(text, command);
        assert.deepEqual(links, []);
    }
});

test("generated shell-like text preserves every visible source byte", () => {
    const alphabet = "abc./_- json;|&<>#'\"\\$`(){}[]*?~\n\t世界";
    let seed = 123456789;
    for (let sample = 0; sample < 500; sample++) {
        let command = "";
        for (let column = 0; column < 80; column++) {
            seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
            command += alphabet[seed % alphabet.length];
        }
        render(command);
    }
});

test("input and output work are bounded without changing fallback text", () => {
    const tooLong = "cat ./file.json " + "x".repeat(65536);
    assert.equal(
        linkShellCommand(tooLong, cwd, home, () => assert.fail()),
        tooLong,
    );
    const words = "cat " + "./file.json ".repeat(257);
    assert.equal(render(words).text, words);
    const links = render("cat " + "./file.json ".repeat(100));
    assert.equal(links.links.length, 64);
    const longPath = "cat /" + "x".repeat(4096) + ".json";
    assert.deepEqual(render(longPath).links, []);
    for (const command of ["cat ./bad\x1b.json", "cat ./bad\0.json", "cat './line\nbreak.json'"]) {
        assert.equal(
            linkShellCommand(command, cwd, home, () => assert.fail()),
            command,
        );
    }
});
