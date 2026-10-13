import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { createContext, runInContext } from "node:vm";

/*
 * Runs the exact shipped widget.js inside a bare V8 context.
 *
 * QML's ".pragma library" directive is not valid JavaScript, so the pragma line
 * is stripped before evaluation. Everything else is the real file, byte for byte,
 * so these tests exercise what actually ships in the plasmoid -- which is only
 * possible because the core has no QML types and no I/O (see the assertion at the
 * bottom of this file).
 */
const sourceUrl = new URL("../contents/ui/widget.js", import.meta.url);

const source = readFileSync(sourceUrl, "utf8").replace(/^\s*\.pragma\b.*$/gm, "");

const sandbox = {};
runInContext(source, createContext(sandbox));

/*
 * Objects built inside the vm context belong to a different realm, so their
 * prototypes are not reference-equal to this realm's Object.prototype and
 * deepStrictEqual rejects them even when the values match. Round-tripping
 * through JSON moves them into this realm so the comparison is meaningful.
 */
const plain = (value) => JSON.parse(JSON.stringify(value));

const {
    STATE_ACTIVE,
    STATE_INACTIVE,
    STATE_FAILED,
    STATE_UNKNOWN,
    SEVERITY_POSITIVE,
    SEVERITY_NEUTRAL,
    SEVERITY_NEGATIVE,
    SEVERITY_MUTED,
    ACTION_RESTART,
    RUN_TOKEN_PREFIX,
    ICON_DEFAULT,
    DETAILS_MAX_LINES,
    DETAIL_MAX_LENGTH,
    PROBE_DETAILS,
    normalizeOutput,
    stateFromWord,
    parseStatus,
    extractDetail,
    failureDetail,
    severityFor,
    interpretStatus,
    resolveIconName,
    shellQuote,
    withRunToken,
    buildStatusCommand,
    buildActionCommand,
} = sandbox;

test("the shipped module exposes the documented constants", () => {
    assert.equal(STATE_ACTIVE, "active");
    assert.equal(STATE_INACTIVE, "inactive");
    assert.equal(STATE_FAILED, "failed");
    assert.equal(STATE_UNKNOWN, "unknown");
    assert.equal(SEVERITY_POSITIVE, "positive");
    assert.equal(SEVERITY_NEUTRAL, "neutral");
    assert.equal(SEVERITY_NEGATIVE, "negative");
    assert.equal(SEVERITY_MUTED, "muted");
    assert.equal(ACTION_RESTART, "restart");
    assert.equal(RUN_TOKEN_PREFIX, "plasma-run-");
    assert.equal(ICON_DEFAULT, "folder-symbolic");
    assert.equal(DETAILS_MAX_LINES, 8);
    assert.ok(DETAIL_MAX_LENGTH > 0);
    assert.equal(PROBE_DETAILS.length, 2);

    // The vocabulary is closed: four states, four severities, one action.
    assert.equal(
        new Set([STATE_ACTIVE, STATE_INACTIVE, STATE_FAILED, STATE_UNKNOWN]).size,
        4,
    );
    assert.equal(
        new Set([SEVERITY_POSITIVE, SEVERITY_NEUTRAL, SEVERITY_NEGATIVE, SEVERITY_MUTED]).size,
        4,
    );
});

test("normalizeOutput trims, strips CR, degrades null and never throws", () => {
    assert.equal(normalizeOutput("  active\r\n  "), "active");
    assert.equal(normalizeOutput("a\r\nb"), "a\nb");
    for (const empty of ["", "   ", undefined, null]) {
        assert.equal(normalizeOutput(empty), "", String(empty));
    }
    assert.doesNotThrow(() => {
        for (const value of [undefined, null, 0, 1, {}, [], true, Symbol("x"), () => {}]) {
            normalizeOutput(value);
        }
    });
});

test("stateFromWord reads the four words case-insensitively and nothing else", () => {
    assert.equal(stateFromWord("active"), STATE_ACTIVE);
    assert.equal(stateFromWord(" INACTIVE "), STATE_INACTIVE);
    assert.equal(stateFromWord("Failed"), STATE_FAILED);
    assert.equal(stateFromWord("unknown"), STATE_UNKNOWN);
    // The line must BE the word: a word followed by prose is not a state.
    for (const bad of ["", "activating", "on", "off", "active maybe", "purple", 7, null, undefined]) {
        assert.equal(stateFromWord(bad), STATE_UNKNOWN, String(bad));
    }
});

test("parseStatus reads the state word and every detail line", () => {
    const parsed = parseStatus("failed\nboom\n  second line  \n\nthird");
    assert.equal(parsed.state, STATE_FAILED);
    assert.deepEqual(plain(parsed.details), ["boom", "second line", "third"]);

    // CRLF input is normalised, so a Windows probe reads the same.
    assert.deepEqual(plain(parseStatus("active\r\none\r\ntwo\r\n").details), ["one", "two"]);
    // The word is matched case-insensitively, and a leading blank line is skipped.
    assert.equal(parseStatus("\n\n  ACTIVE  ").state, STATE_ACTIVE);
    assert.equal(parseStatus("active maybe").state, STATE_UNKNOWN);
});

test("parseStatus degrades unreadable output to unknown with no details", () => {
    for (const raw of [
        "",
        "   ",
        "purple",
        "not json",
        "[]",
        "42",
        '"active"',
        "7",
        null,
        undefined,
        0,
        false,
        {},
        [],
    ]) {
        const parsed = parseStatus(raw);
        assert.equal(parsed.state, STATE_UNKNOWN, JSON.stringify(raw));
        assert.deepEqual(plain(parsed.details), [], JSON.stringify(raw));
    }
});

test("parseStatus bounds the detail list and each detail line", () => {
    const many = [STATE_ACTIVE];
    for (let i = 0; i < DETAILS_MAX_LINES + 4; i += 1) {
        many.push("detail " + i);
    }
    const parsed = parseStatus(many.join("\n"));
    assert.equal(parsed.state, STATE_ACTIVE);
    assert.equal(parsed.details.length, DETAILS_MAX_LINES, "a chatty probe cannot stretch the popup");
    assert.equal(parsed.details[0], "detail 0");

    const huge = parseStatus([STATE_FAILED, "x".repeat(DETAIL_MAX_LENGTH * 3)].join("\n"));
    assert.equal(huge.details.length, 1);
    assert.equal(huge.details[0].length, DETAIL_MAX_LENGTH);
    assert.ok(huge.details[0].endsWith("\u2026"), "a bounded line is truncated, not dropped");
});

test("severityFor maps every state onto a severity", () => {
    assert.equal(severityFor(STATE_ACTIVE, false), SEVERITY_POSITIVE);
    assert.equal(severityFor(STATE_INACTIVE, false), SEVERITY_NEUTRAL);
    assert.equal(severityFor(STATE_FAILED, false), SEVERITY_NEGATIVE);
    assert.equal(severityFor(STATE_UNKNOWN, false), SEVERITY_MUTED);
    // Muted, never neutral: an unreadable probe must not read as "fine".
    assert.notEqual(severityFor(STATE_UNKNOWN, false), SEVERITY_NEUTRAL);
});

test("severityFor produces every severity constant and nothing else", () => {
    const allowed = new Set([
        SEVERITY_POSITIVE,
        SEVERITY_NEUTRAL,
        SEVERITY_NEGATIVE,
        SEVERITY_MUTED,
    ]);
    const produced = new Set();
    for (const state of [STATE_ACTIVE, STATE_INACTIVE, STATE_FAILED, STATE_UNKNOWN, "garbage", undefined, null, 0]) {
        for (const isError of [false, true]) {
            const severity = severityFor(state, isError);
            assert.ok(allowed.has(severity), `unexpected severity ${String(severity)}`);
            produced.add(severity);
        }
    }
    // Every constant is reachable: the four states without an error produce all four.
    assert.deepEqual([...produced].sort(), [...allowed].sort());
});

test("severityFor puts an error above the state", () => {
    // A failed probe is negative whatever the last readable state was, so a stale
    // "active" cannot outlive a failing read.
    assert.equal(severityFor(STATE_ACTIVE, true), SEVERITY_NEGATIVE);
    // The flag is compared strictly, so a truthy non-boolean cannot paint the
    // widget red either.
    assert.equal(severityFor(STATE_ACTIVE, undefined), SEVERITY_POSITIVE);
    assert.equal(severityFor(STATE_ACTIVE, 1), SEVERITY_POSITIVE);
    assert.equal(severityFor(STATE_ACTIVE, "yes"), SEVERITY_POSITIVE);
});

test("interpretStatus reads a readable state as a success whatever the exit code", () => {
    // The shell reports "inactive" with a non-zero exit exactly as it reports
    // "active" with zero, so the payload is the signal and the exit code only
    // explains a failure.
    for (const exitCode of [0, 1, 3, "0", 127]) {
        const result = interpretStatus(exitCode, "active\nprobe line\n", "");
        assert.equal(result.isError, false, String(exitCode));
        assert.equal(result.state, STATE_ACTIVE, String(exitCode));
        assert.deepEqual(plain(result.details), ["probe line"], String(exitCode));
        assert.equal(result.feedback, "", String(exitCode));
        assert.equal(severityFor(result.state, result.isError), SEVERITY_POSITIVE);
    }
});

test("interpretStatus reads exit 0 with no state word as a muted success", () => {
    // A healthy probe that reports nothing useful is not a failure: painting the
    // widget red on every poll would be a lie.
    const result = interpretStatus(0, "no state word here\n", "");
    assert.equal(result.isError, false);
    assert.equal(result.state, STATE_UNKNOWN);
    assert.deepEqual(plain(result.details), []);
    assert.equal(result.feedback, "");
    assert.equal(severityFor(result.state, result.isError), SEVERITY_MUTED);
});

test("interpretStatus reads a failed run as an error carrying the last detail line", () => {
    const result = interpretStatus(3, "", "warning\nprobe unreachable\n");
    assert.equal(result.isError, true);
    assert.equal(result.state, STATE_UNKNOWN);
    assert.equal(result.feedback, "probe unreachable");
    assert.equal(severityFor(result.state, result.isError), SEVERITY_NEGATIVE);

    // stdout is the fallback when stderr said nothing at all.
    assert.equal(interpretStatus(1, "fallback line", "").feedback, "fallback line");
    // A readable state word is still a success, even with a non-zero exit.
    assert.equal(interpretStatus(3, "inactive", "boom").isError, false);
});

test("interpretStatus never throws on garbage", () => {
    assert.doesNotThrow(() => {
        for (const value of [undefined, null, 0, 1, {}, [], true, Symbol("x"), () => {}]) {
            interpretStatus(value, value, value);
        }
    });
});

test("extractDetail and failureDetail take the last non-empty line, stderr first", () => {
    assert.equal(extractDetail(""), "");
    assert.equal(extractDetail("  \n\n"), "");
    assert.equal(extractDetail("first\nsecond\n\nthird\n"), "third");
    assert.equal(failureDetail("why it failed\n", "stdout line"), "why it failed");
    assert.equal(failureDetail("", "stdout line\nsecond"), "second");
    assert.equal(failureDetail("\n\n", "\n"), "");
    // A long line is bounded, so a chatty failure cannot stretch the popup.
    assert.equal(extractDetail("y".repeat(DETAIL_MAX_LENGTH * 2)).length, DETAIL_MAX_LENGTH);
});

test("resolveIconName falls back for an empty value and keeps a real one", () => {
    assert.equal(resolveIconName("folder-symbolic", ICON_DEFAULT), "folder-symbolic");
    for (const empty of ["", "   ", undefined, null]) {
        assert.equal(resolveIconName(empty, ICON_DEFAULT), ICON_DEFAULT, String(empty));
    }
    // The fallback is only used when nothing was configured, so a user who typed the
    // default by hand is not treated as "unset".
    assert.equal(resolveIconName("  " + ICON_DEFAULT + "  ", "other"), ICON_DEFAULT);
});

test("shellQuote wraps a value in single quotes and escapes an embedded quote", () => {
    assert.equal(shellQuote("abc"), "'abc'");
    assert.equal(shellQuote(""), "''");
    assert.equal(shellQuote("/home/x/widget"), "'/home/x/widget'");
    assert.equal(shellQuote(undefined), "''");
    assert.equal(shellQuote(null), "''");
    // Close, escape, reopen: the value can never end the quoting itself.
    assert.equal(shellQuote("it's"), "'it'\\''s'");
    assert.equal(shellQuote("a'b'c"), "'a'\\''b'\\''c'");
});

test("shellQuote round-trips a hostile value through a real shell", () => {
    // The executable engine runs its source through /bin/sh, so quoting is proven
    // against a real shell rather than against a regex.
    const hostile = [
        "plain",
        "it's",
        "'; rm -rf /tmp/should-not-exist; echo '",
        "$(id)",
        "`id`",
        "a b\tc",
        "line1\nline2",
        '"double"',
        "back\\slash",
        "%$\u00e1\u00f1 \u4e2d\u6587",
    ];

    for (const value of hostile) {
        const output = execFileSync("/bin/sh", ["-c", "printf %s " + shellQuote(value)], {
            encoding: "utf8",
        });
        assert.equal(output, value, `shellQuote round-trip failed for ${JSON.stringify(value)}`);
    }
});

test("withRunToken appends the token and strips CR/LF from it", () => {
    assert.equal(withRunToken("cmd", 7), "cmd # " + RUN_TOKEN_PREFIX + "7");
    // A newline would end the trailing comment and let whatever follows run as a
    // command, so the token is sanitised inside the function.
    const tokenised = withRunToken("cmd", "7\nreboot");
    assert.ok(!tokenised.includes("\n"), "a newline would end the comment");
    assert.ok(tokenised.startsWith("cmd # " + RUN_TOKEN_PREFIX), tokenised);
});

test("buildStatusCommand is a fixed command with no configuration literal", () => {
    // The widget's command surface is fixed, so no setting can steer the shell:
    // none of the kcfg entries or their defaults may reach the probe.
    for (const literal of [
        "folder-symbolic",
        "pollInterval",
        "panelIcon",
        "showDetails",
        "15",
        "true",
    ]) {
        assert.ok(!buildStatusCommand().includes(literal), `${literal} must not reach the probe`);
    }
    assert.ok(buildStatusCommand().startsWith("printf "));
    assert.ok(buildStatusCommand().includes(shellQuote(STATE_ACTIVE)));
});

test("buildStatusCommand's payload round-trips through a real shell and parses back", () => {
    // The proof that the shipped probe and parseStatus() agree on the contract:
    // run the command, then read its own output.
    const output = execFileSync("/bin/sh", ["-c", buildStatusCommand()], { encoding: "utf8" });

    const parsed = parseStatus(output);
    assert.equal(parsed.state, STATE_ACTIVE);
    assert.deepEqual(plain(parsed.details), plain(PROBE_DETAILS));
});

test("buildActionCommand appends a run token for the declared action only", () => {
    const command = buildActionCommand(ACTION_RESTART, 3);
    assert.ok(command.startsWith("printf "));
    assert.ok(command.includes(shellQuote(ACTION_RESTART)));
    assert.ok(command.endsWith("# " + RUN_TOKEN_PREFIX + "3"));

    // An unrecognised action must never be interpolated into a command: the empty
    // string is the "there is no command" contract.
    for (const bad of ["status", "on", "off", "toggle", "", undefined, null, 7, {}]) {
        assert.equal(buildActionCommand(bad, 1), "", String(bad));
    }
});

test("the action command runs in a real shell and the token comment is inert", () => {
    const command = buildActionCommand(ACTION_RESTART, 7);
    const output = execFileSync("/bin/sh", ["-c", command], { encoding: "utf8" });
    assert.equal(output.trim(), ACTION_RESTART, "the trailing comment runs nothing");
});

test("the shipped core is pure JavaScript with no I/O", () => {
    const shipped = readFileSync(sourceUrl, "utf8");
    assert.ok(shipped.startsWith(".pragma library"), "the pragma line ships");
    for (const forbidden of ["import ", "require(", "fetch(", "XMLHttpRequest", "Qt.", "i18n("]) {
        assert.ok(!shipped.includes(forbidden), `${forbidden} must not appear in widget.js`);
    }
});
