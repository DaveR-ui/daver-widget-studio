/*
 * The skeleton plasmoid.
 *
 * The boundaries this file encodes, all of them verified against Plasma 6 by the
 * studio's reference widgets (docker-status-widget, tuya-bulb-widget):
 *
 *  1. This is the ONLY file in the package that reads Plasmoid.configuration and
 *     the ONLY place a command string is assembled -- and even here every command
 *     is the output of a builder function in widget.js. Nothing else spells a
 *     flag, a subcommand or a path, and the pure core contains no literal from
 *     configuration, so no setting can steer the shell.
 *
 *  2. The shell is reached ONLY through the org.kde.plasma.plasma5support
 *     DataSource with engine "executable". No process, no file API, no network
 *     call from QML.
 *
 *  3. Every one-shot command carries a run token: the "executable" engine treats
 *     connectedSources as a SET, so assigning an identical command string twice
 *     is a no-op and the second click would silently do nothing. The token is a
 *     trailing shell comment appended by withRunToken() in widget.js, which is
 *     safe precisely because every command this widget builds ends its own logic
 *     before the comment.
 *
 * The poller keeps running through errors: a failed poll shows a negative severity
 * and a message, and the next tick still runs, so the widget heals itself as soon
 * as the probe starts answering again. Plasmoid.status is deliberately NOT
 * overridden: a failing probe is carried by the severity dot, the tooltip and the
 * popup banner, not by a panel icon that would nag forever.
 */

import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support

import "widget.js" as Widget

PlasmoidItem {
    id: root

    // The human name, substituted at scaffold time from the @WIDGET_NAME@ token.
    // A plain display value on purpose: switch these to i18n() calls when the
    // widget grows a translation catalog.
    readonly property string widgetName: "@WIDGET_NAME@"

    // --- Observable state ---------------------------------------------------
    property string state: Widget.STATE_UNKNOWN
    property var details: []
    // Non-empty feedback for the last poll. A status message is informational, so
    // statusIsError is what separates "note" from "failure" -- a healthy probe
    // that reports nothing must never paint the widget red.
    property string statusFeedback: ""
    property bool statusIsError: false
    property bool actionInFlight: false
    property string actionFeedback: ""
    property int runToken: 0

    // --- Configuration (read here and nowhere else) -------------------------
    readonly property int pollIntervalMs: Math.max(2000, Plasmoid.configuration.pollIntervalSeconds * 1000)
    // Resolved by the same pure function the config page uses for its hint, so the
    // two cannot disagree about an empty setting.
    readonly property string iconName: Widget.resolveIconName(
        Plasmoid.configuration.panelIcon,
        Widget.ICON_DEFAULT
    )
    readonly property bool detailsEnabled: Plasmoid.configuration.showDetails

    // --- Derived state ------------------------------------------------------
    // The status command. Only the JS builder knows how the probe is spelled, so
    // this file never writes one.
    readonly property string statusCommand: Widget.buildStatusCommand()

    // True when the widget currently carries a failure the user has to see: a
    // failed read or a failed action. The action's failure outranks the probe's,
    // because it is what the user just did.
    readonly property bool errorActive: root.statusIsError || root.actionFeedback !== ""
    // The single severity mapping in the whole package: widget.js decides the
    // severity, SeverityDot.qml maps it onto a colour, and neither representation
    // maps a state onto a colour itself.
    readonly property string severity: Widget.severityFor(root.state, root.errorActive)

    readonly property string feedbackText: root.actionFeedback !== ""
        ? root.actionFeedback
        : root.statusFeedback

    // --- Plasmoid metadata ---------------------------------------------------
    Plasmoid.title: root.widgetName
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    // On the desktop show the full widget; in a panel fall back to the compact
    // representation, which expands into a popup on click.
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : null

    toolTipMainText: root.widgetName
    toolTipSubText: root.feedbackText !== ""
        ? root.feedbackText
        : i18nc("@info", "State: %1", root.state)

    // --- Actions -------------------------------------------------------------
    function nextRunToken() {
        root.runToken += 1;
        return root.runToken;
    }

    // Re-read immediately, without waiting for the next poll tick. The token makes
    // the source distinct, so two refreshes in a row both run.
    function refreshStatus() {
        forcedStatusRead.connectedSources = [
            Widget.withRunToken(root.statusCommand, root.nextRunToken())
        ];
    }

    /*
     * The user-facing sentence for a failed probe. widget.js returns data only --
     * an extracted detail line and the exit code -- and the sentence is composed
     * here, where i18n() lives, so no untranslatable English is baked into the
     * core.
     */
    function failureMessage(detail, exitCode) {
        return detail !== ""
            ? i18nc("@info", "The probe failed (exit code %1): %2", exitCode, detail)
            : i18nc("@info", "The probe failed (exit code %1).", exitCode);
    }

    // One shared interpretation for the poller and the one-shot re-read, so a
    // reply cannot mean two different things.
    function applyStatus(stdout, stderr, exitCode) {
        // The engine delivers exactly one event, at process exit, carrying the
        // exit code. An event without one is a stream this widget does not expect;
        // ignoring it keeps a future streaming engine from flashing a false error.
        if (exitCode === undefined) {
            return;
        }
        const result = Widget.interpretStatus(exitCode, stdout, stderr);
        root.state = result.state;
        root.details = result.details;
        root.statusIsError = result.isError;
        root.statusFeedback = result.isError
            ? root.failureMessage(result.feedback, Number(exitCode))
            : "";
    }

    // The one action. The builder refuses anything that is not the declared
    // action, so the empty-command guard is defence in depth: an empty command
    // must never reach the engine, and a refused action never burns a token.
    function runAction() {
        if (root.actionInFlight) {
            return;
        }
        const command = Widget.buildActionCommand(Widget.ACTION_RESTART, root.nextRunToken());
        if (command === "") {
            return;
        }
        root.actionInFlight = true;
        root.actionFeedback = "";
        actionSource.connectedSources = [command];
    }

    // --- Data sources --------------------------------------------------------

    // The poller. Always on: a failed poll shows a negative severity and a
    // message, and the next tick still runs.
    P5Support.DataSource {
        id: statusSource
        engine: "executable"
        interval: root.pollIntervalMs
        connectedSources: [root.statusCommand]

        onNewData: (sourceName, data) => {
            root.applyStatus(data["stdout"], data["stderr"], data["exit code"]);
        }
    }

    // One-shot: re-read after an action, without waiting for the next poll tick.
    // The run token is what makes a second re-run a distinct source.
    P5Support.DataSource {
        id: forcedStatusRead
        engine: "executable"
        interval: 0
        connectedSources: []

        onNewData: (sourceName, data) => {
            root.applyStatus(data["stdout"], data["stderr"], data["exit code"]);
        }
    }

    // One-shot: the action itself. Exit 0 clears the feedback and re-reads the
    // state, so the popup shows what the action left behind; anything else is
    // surfaced rather than swallowed.
    P5Support.DataSource {
        id: actionSource
        engine: "executable"
        interval: 0
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data["exit code"] === undefined) {
                return;
            }
            root.actionInFlight = false;

            if (Number(data["exit code"]) === 0) {
                root.actionFeedback = "";
                root.refreshStatus();
                return;
            }

            const detail = Widget.failureDetail(data["stderr"], data["stdout"]);
            root.actionFeedback = detail !== ""
                ? i18nc("@info", "The action failed (exit code %1): %2", Number(data["exit code"]), detail)
                : i18nc("@info", "The action failed (exit code %1).", Number(data["exit code"]));
        }
    }

    // --- Contextual actions --------------------------------------------------
    // The same two intents as the popup, so the panel right-click is a complete
    // control surface without opening the popup. Each one still goes through the
    // builders: this file spells no command.
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.refreshStatus()
        },
        PlasmaCore.Action {
            text: i18n("Restart")
            enabled: !root.actionInFlight
            onTriggered: root.runAction()
        }
    ]

    // --- Representations -----------------------------------------------------
    compactRepresentation: CompactRepresentation {
        iconName: root.iconName
        severity: root.severity
    }

    fullRepresentation: FullRepresentation {
        state: root.state
        severity: root.severity
        details: root.details
        detailsEnabled: root.detailsEnabled
        feedbackText: root.feedbackText
        feedbackIsError: root.errorActive
        actionInFlight: root.actionInFlight

        onRefreshRequested: root.refreshStatus()
        onActionRequested: root.runAction()
    }
}
