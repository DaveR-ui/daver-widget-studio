import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

import "widget.js" as Widget

/*
 * Popup / desktop representation: the state, the probe's detail lines, the one
 * action and the feedback line.
 *
 * This file reads no configuration and holds no command string: main.qml owns
 * both and hands the computed state, severity, details and feedback down. The
 * buttons only emit an intent; main.qml turns that intent into a command.
 */
ColumnLayout {
    id: fullRoot

    property string state: Widget.STATE_UNKNOWN
    property string severity: Widget.SEVERITY_MUTED
    property var details: []
    property bool detailsEnabled: true
    property string feedbackText: ""
    property bool feedbackIsError: false
    property bool actionInFlight: false

    signal refreshRequested()
    signal actionRequested()

    /*
     * The feedback colour follows the shared severity rather than a hard-coded
     * red, so an informational note is never painted as a failure. The action's
     * failure outranks the probe's, and main.qml already decided which text and
     * which severity are on screen.
     */
    readonly property color feedbackColor: fullRoot.feedbackIsError
        ? Kirigami.Theme.negativeTextColor
        : Kirigami.Theme.textColor

    /*
     * The state sentence. The STATE_* words are compared against the core's
     * constants, so a renamed state cannot silently leave the generic branch.
     */
    function stateLabel() {
        switch (fullRoot.state) {
        case Widget.STATE_ACTIVE:
            return i18n("Active");
        case Widget.STATE_INACTIVE:
            return i18n("Inactive");
        case Widget.STATE_FAILED:
            return i18n("Failed");
        default:
            return i18n("Unknown");
        }
    }

    spacing: Kirigami.Units.smallSpacing
    Layout.preferredWidth: Kirigami.Units.gridUnit * 16

    // --- Header: state and refresh ------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        SeverityDot {
            Layout.alignment: Qt.AlignVCenter
            severity: fullRoot.severity
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: fullRoot.stateLabel()
            font.bold: true
        }

        PlasmaComponents3.ToolButton {
            id: refreshButton
            icon.name: "view-refresh"
            display: PlasmaComponents3.AbstractButton.IconOnly
            enabled: !fullRoot.actionInFlight
            onClicked: fullRoot.refreshRequested()

            PlasmaComponents3.ToolTip {
                text: i18n("Re-run the probe now, without waiting for the next poll")
            }
        }
    }

    // --- Detail list ---------------------------------------------------------
    // One label per line the probe reported, hidden when the setting is off or the
    // probe reported none.
    ColumnLayout {
        visible: fullRoot.detailsEnabled && fullRoot.details.length > 0
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: fullRoot.details

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: modelData
                wrapMode: Text.WordWrap
                opacity: 0.7
                font: Kirigami.Theme.smallFont
            }
        }
    }

    // --- The one action ------------------------------------------------------
    // It only emits an intent; main.qml builds the command. The tooltip spells
    // what the button does, once.
    PlasmaComponents3.Button {
        Layout.fillWidth: true
        text: i18n("Restart")
        enabled: !fullRoot.actionInFlight
        onClicked: fullRoot.actionRequested()

        PlasmaComponents3.ToolTip {
            text: i18n("Run the widget's action command")
        }
    }

    // --- Feedback ------------------------------------------------------------
    PlasmaComponents3.Label {
        visible: fullRoot.feedbackText !== ""
        Layout.fillWidth: true
        text: fullRoot.feedbackText
        color: fullRoot.feedbackColor
        wrapMode: Text.WordWrap
        font: Kirigami.Theme.smallFont
    }
}
