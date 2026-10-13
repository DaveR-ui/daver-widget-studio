import QtQuick

import org.kde.kirigami as Kirigami

import "widget.js" as Widget

/*
 * The single severity -> colour mapping, shared by every representation.
 *
 * The severity vocabulary is imported from widget.js rather than re-spelled, so
 * the meaning of a state lives in exactly one file and the colour lives in exactly
 * one place. Adding a fifth severity means adding it here and nowhere else.
 *
 * Muted is deliberately NOT neutral: an unknown state must not read as "fine".
 */
Rectangle {
    id: dot

    property string severity: Widget.SEVERITY_MUTED
    property int diameter: Math.round(Kirigami.Units.gridUnit / 3)

    readonly property color severityColor: {
        switch (dot.severity) {
        case Widget.SEVERITY_POSITIVE:
            return Kirigami.Theme.positiveTextColor;
        case Widget.SEVERITY_NEGATIVE:
            return Kirigami.Theme.negativeTextColor;
        case Widget.SEVERITY_NEUTRAL:
            // Grey rather than the bright text colour: an inactive state must not
            // read as an active one.
            return Qt.alpha(Kirigami.Theme.textColor, 0.6);
        default:
            return Kirigami.Theme.disabledTextColor;
        }
    }

    implicitWidth: dot.diameter
    implicitHeight: dot.diameter
    radius: dot.diameter / 2
    color: dot.severityColor
}
