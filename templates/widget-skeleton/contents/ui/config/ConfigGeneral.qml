import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import "../widget.js" as Widget

/*
 * General configuration page.
 *
 * Plasma binds every "cfg_<entryName>" alias to the corresponding entry in
 * contents/config/main.xml. The alias target must stay a plain writable property:
 * aliasing an expression is a silent no-op on save.
 *
 * The JS core sits one directory up, in contents/ui/. QML's implicit
 * same-directory import covers only this config/ directory, so the parent is
 * imported explicitly -- which is also what lets this page resolve values with the
 * very functions main.qml uses.
 */
Kirigami.FormLayout {
    id: configPage

    property alias cfg_pollIntervalSeconds: pollInterval.value
    property alias cfg_showDetails: showDetails.checked

    /*
     * The panel icon is a plain property, NOT an alias.
     *
     * GOTCHA, recorded here because docker-status-widget lost a setting to it:
     * Plasma hands every stored value to this page as an initial property, and that
     * write reaches a combo box's text before the combo has finished initialising.
     * The combo's own startup then adopts index 0 and rewrites its text -- so a
     * setting carried by a combo cannot be a cfg_* alias, or merely opening the page
     * would write the first model entry over the stored value.
     *
     * A plain property survives the write, and the combo is seeded from it below in
     * the combo's own Component.onCompleted.
     */
    property string cfg_panelIcon: Widget.ICON_DEFAULT

    // The hint is derived by the same normaliser main.qml uses, so the page cannot
    // disagree with the widget about whether the setting is effectively empty.
    readonly property bool panelIconUnset: Widget.normalizeOutput(configPage.cfg_panelIcon) === ""

    QQC2.SpinBox {
        id: pollInterval
        Kirigami.FormData.label: i18n("Poll interval (seconds):")
        from: 2
        to: 300
        stepSize: 1

        QQC2.ToolTip.text: i18n("How often the widget runs the probe. Each poll runs one command and reads its first line.")
        QQC2.ToolTip.visible: hovered
    }

    /*
     * Editable on purpose: the icon is any name from the active theme, so a value
     * the list does not carry must be typable rather than refused.
     */
    QQC2.ComboBox {
        id: panelIcon
        Kirigami.FormData.label: i18n("Panel icon:")
        editable: true
        model: [
            "folder-symbolic",
            "utilities-terminal-symbolic",
            "network-wired-symbolic",
            "view-statistics-symbolic",
            "dialog-information-symbolic"
        ]

        // False until the stored value has been pushed into the control. The stored
        // value arrives BEFORE the combo initialises; the combo's own startup then
        // sets index 0 and its text -- and only afterwards does this
        // Component.onCompleted run. The push-back below therefore stays muted until
        // the seed is in, or merely opening the page would overwrite the stored icon.
        property bool seeded: false

        // Config -> control, once the combo has finished initialising. The stored
        // value is read into a local before anything is written: setting currentIndex
        // makes the combo rewrite its text from the model, and an index of -1 blanks
        // it, so a free-form name has to be restored afterwards or it would be lost
        // before it is ever shown.
        Component.onCompleted: {
            const stored = configPage.cfg_panelIcon;
            panelIcon.currentIndex = panelIcon.find(stored);
            panelIcon.editText = stored;
            panelIcon.seeded = true;
        }

        // Control -> config: a pick from the list and a free-form edit both reach the
        // setting Plasma reads when the page is saved. The index then follows an exact
        // match, so the popup highlight points at the value on screen.
        onActivated: (index) => { configPage.cfg_panelIcon = panelIcon.textAt(index); }
        onEditTextChanged: {
            if (!panelIcon.seeded) {
                return;
            }
            configPage.cfg_panelIcon = panelIcon.editText;

            const match = panelIcon.find(panelIcon.editText);
            if (match >= 0 && match !== panelIcon.currentIndex) {
                panelIcon.currentIndex = match;
            }
        }

        QQC2.ToolTip.text: i18n("Any icon name from the active theme. Type a name the list does not carry if you need one.")
        QQC2.ToolTip.visible: hovered
    }

    QQC2.CheckBox {
        id: showDetails
        Kirigami.FormData.label: i18n("Show the probe's detail lines:")
        text: i18n("Show the probe's detail lines")

        QQC2.ToolTip.text: i18n("Turns the popup's detail list off without hiding the state.")
        QQC2.ToolTip.visible: hovered
    }

    QQC2.Label {
        visible: configPage.panelIconUnset
        text: i18n("No icon set; the widget will use its default.")
        wrapMode: Text.WordWrap
        opacity: 0.7
        font: Kirigami.Theme.smallFont
    }
}
