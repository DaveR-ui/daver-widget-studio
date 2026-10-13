import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import "widget.js" as Widget

/*
 * Panel representation: the configured icon and the severity dot.
 *
 * main.qml resolves the icon name and the severity and hands both down, so this
 * file reads no configuration and maps no state onto a colour itself. The icon
 * dimming below is the only visual decision left here, and it is driven by the
 * severity the core produced -- a dot beside it is what makes the widget readable
 * at a glance.
 */
Item {
    id: compactRoot

    property string iconName: Widget.ICON_DEFAULT
    property string severity: Widget.SEVERITY_MUTED

    implicitWidth: compactLayout.implicitWidth
    implicitHeight: compactLayout.implicitHeight

    RowLayout {
        id: compactLayout
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: compactRoot.iconName
            opacity: compactRoot.severity === Widget.SEVERITY_POSITIVE ? 1.0 : 0.5
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }

        SeverityDot {
            Layout.alignment: Qt.AlignVCenter
            severity: compactRoot.severity
        }
    }
}
