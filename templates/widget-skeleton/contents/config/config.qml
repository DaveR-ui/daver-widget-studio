import org.kde.plasma.configuration

/*
 * The applet's config page.
 *
 * GOTCHA, recorded here because it costs an afternoon the first time: the
 * `source:` path below is resolved relative to `contents/ui/`, NOT relative to
 * `contents/`. ConfigGeneral.qml therefore lives in contents/ui/config/, and
 * writing `source: "config/ConfigGeneral.qml"` is what points at it. Recording
 * the same trap as docker-status-widget's README does.
 *
 * Keep the page in contents/ui/config/ for a second reason: the applet's pure JS
 * core sits in contents/ui/, so the config page can import it and reuse the very
 * resolvers main.qml uses.
 */
ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "config/ConfigGeneral.qml"
    }
}
