#!/usr/bin/env bash
#
# Install (or remove) the plasmoid for the current user.
#
#   ./install.sh             install or upgrade (the default)
#   ./install.sh uninstall   remove
#
# The package id is substituted at scaffold time -- tools/new-widget.sh replaces
# @WIDGET_ID@ with the real id -- so this script carries no id of its own. Every
# path is resolved from this script's own directory, so it works from any working
# directory, and it touches nothing outside the project tree, the build directory
# and ~/.local/share/plasma/plasmoids/.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# The package id, substituted at scaffold time. It is a reverse-DNS applet id such as
# io.github.daver-ui.my-widget: what Plasma registers, what kpackagetool6 installs,
# and the prefix of the applet's translation domain.
PLASMOID_ID="@WIDGET_ID@"

# The package root: the directory holding metadata.json and contents/.
PACKAGE_DIR="$SCRIPT_DIR"
# Staging inside the project tree: the STAGE, not the package, is what gets
# installed, so a stale file from a previous install cannot survive and the source
# tree is never rewritten in place. Gitignore build/ in the widget's own repo.
STAGE_DIR="$PACKAGE_DIR/build/$PLASMOID_ID"
# The plain-copy target, used only when kpackagetool6 is unavailable.
PLASMOID_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$PLASMOID_ID"

say() { printf '%s\n' "$*"; }

usage() {
    cat <<'EOF'
Usage: install.sh [command]

Commands:
  install     Install or upgrade the plasmoid for the current user (default).
  uninstall   Remove the plasmoid for the current user.

EOF
}

has_kpackagetool() {
    command -v kpackagetool6 >/dev/null 2>&1
}

# Stage the package: everything in the package directory except the build output
# itself and any VCS directory. dotglob, so a hidden file ships with the package.
stage_package() {
    local entry
    local name

    rm -rf -- "$STAGE_DIR"
    mkdir -p -- "$STAGE_DIR"
    shopt -s dotglob nullglob
    for entry in "$PACKAGE_DIR"/*; do
        name="$(basename -- "$entry")"
        case "$name" in
            build|.git) continue ;;
        esac
        cp -a -- "$entry" "$STAGE_DIR/"
    done
}

# Install the STAGED tree, upgrading when the id is already installed. The
# plain-copy fallback keeps a machine without kpackagetool6 working.
install_staged() {
    local staged="$1"

    if has_kpackagetool; then
        if kpackagetool6 --type Plasma/Applet --show "$PLASMOID_ID" >/dev/null 2>&1; then
            kpackagetool6 --type Plasma/Applet --upgrade "$staged"
            say "Upgraded plasmoid: $PLASMOID_ID"
        else
            kpackagetool6 --type Plasma/Applet --install "$staged"
            say "Installed plasmoid: $PLASMOID_ID"
        fi
    else
        rm -rf -- "$PLASMOID_HOME"
        mkdir -p -- "$PLASMOID_HOME"
        cp -a -- "$staged/." "$PLASMOID_HOME/"
        say "kpackagetool6 unavailable; copied the plasmoid to $PLASMOID_HOME"
    fi
}

cmd_install() {
    stage_package
    install_staged "$STAGE_DIR"
    say ""
    say "Next step: right-click the panel or the desktop, \"Add Widgets…\", and search for the widget's name."
    say "If it does not appear, restart plasmashell:  kquitapp6 plasmashell && kstart plasmashell"
}

cmd_uninstall() {
    if has_kpackagetool; then
        kpackagetool6 --type Plasma/Applet --remove "$PLASMOID_ID"
        say "Removed plasmoid: $PLASMOID_ID"
    else
        rm -rf -- "$PLASMOID_HOME"
        say "Removed plasmoid: $PLASMOID_ID (plain copy)"
    fi
    say "Note: remove the widget from the panel or the desktop first if it is still placed."
}

case "${1:-install}" in
    install)        cmd_install ;;
    uninstall)      cmd_uninstall ;;
    -h|--help|help) usage ;;
    *) say "Unknown command: $1" >&2; usage; exit 2 ;;
esac
