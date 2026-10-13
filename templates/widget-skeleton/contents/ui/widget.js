.pragma library

/*
 * Pure core for the skeleton plasmoid.
 *
 * This file is deliberately free of QML types and of every kind of I/O: nothing
 * here runs a process, reads a file or talks to the network. That is what lets a
 * plain JavaScript engine execute it -- tests/widget.test.mjs evaluates these
 * exact bytes in a bare V8 context -- so command assembly, output parsing and the
 * severity model can be unit tested without a desktop session.
 *
 * Three rules keep it that way:
 *
 *   1. No QML types and no runtime APIs from the QML engine: they do not exist
 *      outside QML. User-facing text is chosen in the QML layer, where the
 *      translation helper lives; this file returns data.
 *   2. No I/O: the shell is reached only through buildStatusCommand() and
 *      buildActionCommand(), and main.qml is the only file that runs them.
 *   3. ES5 on purpose (var, function, no arrow functions, no let/const): the
 *      plasmoid's engine and a bare V8 must both accept these exact bytes.
 *
 * The command surface is exactly two builders. Everything they interpolate goes
 * through shellQuote(), and nothing they build comes from configuration: the
 * probe and the action are fixed constants, and a value a forked widget
 * interpolates is validated here before it is quoted.
 */

/* --- State ---------------------------------------------------------------- */

/*
 * The four words the probe reports on the FIRST line of its stdout. parseStatus()
 * reads exactly these words and degrades anything else to STATE_UNKNOWN, so a
 * probe this widget does not understand never reads as a healthy state.
 */
var STATE_ACTIVE = "active";
var STATE_INACTIVE = "inactive";
var STATE_FAILED = "failed";
var STATE_UNKNOWN = "unknown";

/* --- Severity ------------------------------------------------------------- */

/*
 * The single source of truth for "how bad is this state". The QML layer maps
 * these four values onto theme colours (SeverityDot.qml) and never decides one
 * itself, so the meaning of a state lives here and is unit tested.
 *
 * STATE_UNKNOWN is MUTED and never NEUTRAL: "the probe could not tell" must not
 * read as "everything is fine".
 */
var SEVERITY_POSITIVE = "positive";
var SEVERITY_NEUTRAL = "neutral";
var SEVERITY_NEGATIVE = "negative";
var SEVERITY_MUTED = "muted";

/* --- Actions -------------------------------------------------------------- */

/*
 * The actions the popup's single button can request. QML compares these and never
 * parses them, so their spelling is an internal contract between main.qml and
 * FullRepresentation.qml. buildActionCommand() accepts exactly this set and
 * answers "" for anything else, so an unrecognised action can never reach a
 * shell.
 */
var ACTION_RESTART = "restart";

/* --- Command constants ---------------------------------------------------- */

/*
 * Every one-shot command ends with a trailing shell comment carrying this prefix
 * and a number. The "executable" data engine treats connectedSources as a SET:
 * assigning an identical command string twice is a no-op, so without the token a
 * second click would silently do nothing. Verified against plasma5support 6.7.5
 * by the studio's reference widgets.
 *
 * The token is only safe because every command this file builds finishes its own
 * logic before the comment. Never append it to a command that comes from
 * configuration: the comment ends at the first newline.
 */
var RUN_TOKEN_PREFIX = "plasma-run-";

/* The panel icon used when the setting is empty; the matching kcfg default. */
var ICON_DEFAULT = "folder-symbolic";

/* The detail list is bounded, so a chatty probe cannot stretch the popup. */
var DETAILS_MAX_LINES = 8;
var DETAIL_MAX_LENGTH = 240;

/*
 * The two lines the shipped stand-in probe reports as details. They exist so a
 * fresh install shows a populated detail list and tells whoever forked the
 * skeleton what to replace.
 */
var PROBE_DETAILS = [
    "Skeleton probe: replace buildStatusCommand() with your own command",
    "Keep the payload shape: the state word first, then one line per detail"
];

/* --- Output handling ------------------------------------------------------ */

/**
 * Normalises raw captured output: null/undefined -> "", CRLF -> LF, trimmed.
 * Never throws.
 */
function normalizeOutput(raw) {
    if (raw === undefined || raw === null) {
        return "";
    }
    return String(raw).replace(/\r/g, "").trim();
}

/**
 * The state word for one line, or STATE_UNKNOWN. Matched in lower case after
 * trimming, so "  ACTIVE  " reads the same as "active"; the line must BE the
 * word, so "active maybe" is not a state.
 */
function stateFromWord(word) {
    switch (normalizeOutput(word).toLowerCase()) {
    case STATE_ACTIVE:
        return STATE_ACTIVE;
    case STATE_INACTIVE:
        return STATE_INACTIVE;
    case STATE_FAILED:
        return STATE_FAILED;
    default:
        return STATE_UNKNOWN;
    }
}

/** One bounded line: truncated with an ellipsis rather than dropped. */
function boundedLine(line) {
    if (line.length > DETAIL_MAX_LENGTH) {
        return line.substring(0, DETAIL_MAX_LENGTH - 1) + "\u2026";
    }
    return line;
}

/**
 * Reads the probe's payload: the FIRST non-empty line is the state word, every
 * later non-empty line is a detail. Returns { state, details } and never throws.
 *
 * Empty output, a word this widget does not know, or a non-string all degrade to
 * STATE_UNKNOWN with no details, so a broken probe is reported as unreadable
 * instead of being guessed at.
 */
function parseStatus(raw) {
    var parsed = { state: STATE_UNKNOWN, details: [] };
    var text = normalizeOutput(raw);
    if (text === "") {
        return parsed;
    }

    var lines = text.split("\n");
    var stateRead = false;
    for (var i = 0; i < lines.length; i += 1) {
        var line = lines[i].trim();
        if (line === "") {
            continue;
        }
        if (!stateRead) {
            parsed.state = stateFromWord(line);
            stateRead = true;
            continue;
        }
        if (parsed.details.length < DETAILS_MAX_LINES) {
            parsed.details.push(boundedLine(line));
        }
    }
    return parsed;
}

/**
 * The last non-empty line of one blob of output, bounded. A tool normally leaves
 * its reason on the last line it printed, so that is the line worth showing.
 */
function extractDetail(raw) {
    var text = normalizeOutput(raw);
    if (text === "") {
        return "";
    }
    var lines = text.split("\n");
    var line = "";
    for (var i = 0; i < lines.length; i += 1) {
        var candidate = lines[i].trim();
        if (candidate !== "") {
            line = candidate;
        }
    }
    return boundedLine(line);
}

/**
 * The one detail worth showing for a failed run: the last non-empty line of
 * stderr, or of stdout when stderr said nothing. Bounded, so a chatty failure
 * cannot stretch the popup. The sentence that frames it is composed in QML,
 * where the translation helper lives.
 */
function failureDetail(stderr, stdout) {
    var detail = extractDetail(stderr);
    if (detail !== "") {
        return detail;
    }
    return extractDetail(stdout);
}

/**
 * The severity of the widget's current view, from a state and an explicit error
 * flag.
 *
 * The flag comes first, so a failed probe is negative whatever the last readable
 * state was. It is a flag rather than "is there feedback text" because a
 * successful read that carries a note must stay muted, not red -- and it is
 * compared strictly, so a truthy non-boolean cannot paint the widget red either.
 */
function severityFor(state, isError) {
    if (isError === true) {
        return SEVERITY_NEGATIVE;
    }
    switch (state) {
    case STATE_ACTIVE:
        return SEVERITY_POSITIVE;
    case STATE_INACTIVE:
        return SEVERITY_NEUTRAL;
    case STATE_FAILED:
        return SEVERITY_NEGATIVE;
    default:
        // Unknown is muted, never neutral: an unreadable probe must not read as fine.
        return SEVERITY_MUTED;
    }
}

/**
 * One interpretation of one run, shared by the poller and the one-shot re-read,
 * so the two paths cannot disagree about what a reply means.
 *
 * A state word on the first line is a success whatever the exit code was: the
 * shell reports "inactive" with a non-zero exit exactly as it reports "active"
 * with zero, so the payload is the signal and the exit code only explains a
 * failure. Exit 0 with no readable state word is a success with an unhelpful
 * answer, not a failure -- a healthy probe that reports nothing must not paint
 * the widget red on every poll.
 *
 * Returns { state, details, feedback, isError }. `feedback` is the extracted
 * detail line ("" when there is none) and the sentence around it is QML's job.
 * Never throws.
 */
function interpretStatus(exitCode, stdout, stderr) {
    // Number() throws on a Symbol, so the never-throws contract needs the guard:
    // a value it cannot read fails into the error branch below rather than
    // escaping the function.
    var code;
    try {
        code = Number(exitCode);
    } catch (error) {
        code = NaN;
    }
    var parsed = parseStatus(stdout);
    if (parsed.state !== STATE_UNKNOWN) {
        return {
            state: parsed.state,
            details: parsed.details,
            feedback: "",
            isError: false
        };
    }
    if (code === 0) {
        return {
            state: STATE_UNKNOWN,
            details: [],
            feedback: "",
            isError: false
        };
    }
    return {
        state: STATE_UNKNOWN,
        details: [],
        feedback: failureDetail(stderr, stdout),
        isError: true
    };
}

/* --- Shell command assembly ---------------------------------------------- */

/**
 * Wraps a value in single quotes for /bin/sh. An embedded single quote is closed,
 * escaped and reopened ('it'\''s'), so the value can never end the quoting
 * itself. Never throws.
 */
function shellQuote(value) {
    var text = value === undefined || value === null ? "" : String(value);
    return "'" + text.replace(/'/g, "'\\''") + "'";
}

/**
 * Appends the run token to a command, making each assignment a distinct engine
 * source. See RUN_TOKEN_PREFIX for why.
 *
 * The token is stripped of CR and LF first: a newline would end the trailing
 * comment and let whatever follows run as a command. Every caller passes an
 * integer today; making that a property of this function keeps it from depending
 * on a habit of its callers.
 */
function withRunToken(command, token) {
    var safeToken = String(token).replace(/[\r\n]/g, "");
    return command + " # " + RUN_TOKEN_PREFIX + safeToken;
}

/**
 * The status probe: a FIXED command, never assembled from configuration.
 *
 * The shipped probe is a printf, so the widget runs on a machine with nothing
 * installed and prints exactly the payload parseStatus() reads: the state word on
 * the first line, then one line per detail. A new widget replaces this one
 * command (and only it) with its own probe and keeps the payload shape.
 *
 * Note what is NOT here: no configuration literal, no user input. Everything a
 * forked widget interpolates is validated in this file and quoted with
 * shellQuote() before it reaches the string.
 */
function buildStatusCommand() {
    var command = "printf '%s\\n' " + shellQuote(STATE_ACTIVE);
    for (var i = 0; i < PROBE_DETAILS.length; i += 1) {
        command += " " + shellQuote(PROBE_DETAILS[i]);
    }
    return command;
}

/**
 * The one-shot action command, or "" for anything that is not the declared
 * action.
 *
 * The empty string is the contract "there is no command": an unrecognised action
 * must never be interpolated into a command, and main.qml refuses an empty
 * command before it reaches the engine.
 *
 * The shipped action is a stand-in that prints the action label and mutates
 * nothing, so a fresh install of the skeleton is safe to click. Replace it with
 * the mutation your widget performs, and keep the guard and the run token: a real
 * action usually needs the privileges the underlying tool needs, so the popup
 * button and the command this builder assembles are the whole security surface.
 */
function buildActionCommand(action, token) {
    if (action !== ACTION_RESTART) {
        return "";
    }
    return withRunToken("printf '%s\\n' " + shellQuote(ACTION_RESTART), token);
}

/* --- Configuration resolution -------------------------------------------- */

/**
 * A configured icon name, or the fallback when nothing usable is set. The same
 * function main.qml uses to pick the panel icon and the config page uses for its
 * hint, so the two cannot disagree about whether the setting is effectively empty.
 */
function resolveIconName(configured, fallback) {
    var text = normalizeOutput(configured);
    return text === "" ? fallback : text;
}
