#!/usr/bin/env bash
#
# Scaffold a new widget by COPYING templates/widget-skeleton/ and substituting its
# two placeholder tokens.
#
#   tools/new-widget.sh <widget-id> [--name <human name>] [--out <dir>] [--force]
#
# This is scaffolding by copy, not code generation: the whole template tree is
# copied with cp -a, and the only transformation is a literal sed substitution of
# @WIDGET_ID@ and @WIDGET_NAME@ in every regular file of the COPY. There is no
# template engine, no merge path and no "update" command -- a forked widget never
# receives later skeleton improvements, which is deliberate.
#
# The template is only ever READ. A manifest of it is hashed before the copy and
# re-checked afterwards, so a regression that rendered in place fails loudly instead
# of silently poisoning every future scaffold.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STUDIO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$STUDIO_ROOT/templates/widget-skeleton"

# The id is a Plasma applet id: reverse-DNS labels, lowercase, each label starting
# with a letter. Plasma itself is tolerant, but a predictable id is what keeps the
# installed package name, the config group and the i18n domain aligned.
ID_PATTERN='^[a-z][a-z0-9-]+(\.[a-z0-9-]+)+$'

# The human name lands inside a JSON string literal (metadata.json "Name") and a QML
# string literal (the panel title). A double quote, a backslash or any control
# character would terminate the literal it is written into, and a backtick is refused
# too: a name is a label, never part of a command. The remaining metacharacters are
# inert in both contexts and are handled by the sed escaping below.
NAME_FORBIDDEN='["\\`[:cntrl:]]'

usage() {
    cat <<'EOF'
Usage: tools/new-widget.sh <widget-id> [--name <human name>] [--out <dir>] [--force]

  <widget-id>   Reverse-DNS applet id, e.g. io.github.daver-ui.my-widget
  --name        Human-readable name (default: the id's last label, its first letter upper-cased)
  --out         Target directory (default: build/<widget-id> in the studio root)
  --force       Replace a non-empty target directory

Copies templates/widget-skeleton/ and substitutes @WIDGET_ID@ / @WIDGET_NAME@ in
every regular file of the copy. The template itself is never modified.
EOF
}

die() {
    printf 'new-widget: %s\n' "$*" >&2
    exit 1
}

# Trim surrounding whitespace. A name is a label, so a leading or trailing space is
# never intended -- and trimming is what stops a whitespace-only name from looking
# non-empty.
trim() {
    local text="$1"
    text="${text#"${text%%[![:space:]]*}"}"
    text="${text%"${text##*[![:space:]]}"}"
    printf '%s' "$text"
}

# --- Arguments --------------------------------------------------------------

widget_id=""
widget_name=""
out_dir=""
force=0

while [ $# -gt 0 ]; do
    case "$1" in
        --name)
            [ $# -ge 2 ] || die "--name needs a value"
            widget_name="$2"
            shift 2
            ;;
        --out)
            [ $# -ge 2 ] || die "--out needs a value"
            out_dir="$2"
            shift 2
            ;;
        --force)
            force=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            usage >&2
            die "unknown option: $1"
            ;;
        *)
            if [ -n "$widget_id" ]; then
                usage >&2
                die "unexpected argument: $1"
            fi
            widget_id="$1"
            shift
            ;;
    esac
done

# --- Validation (everything is checked BEFORE a single byte is written) -------

if [ -z "$widget_id" ]; then
    usage >&2
    die "a widget id is required"
fi

if ! [[ "$widget_id" =~ $ID_PATTERN ]]; then
    die "invalid widget id '$widget_id': expected lowercase reverse-DNS labels, e.g. io.github.daver-ui.my-widget"
fi

if [ -z "$widget_name" ]; then
    # The last dot-segment, capitalised: io.github.daver-ui.demo -> "Demo". The id
    # pattern allows nothing outside [a-z0-9-] and dots, so the derived name can
    # never hit the name rule below.
    last_label="${widget_id##*.}"
    widget_name="${last_label^}"
else
    widget_name="$(trim "$widget_name")"
fi

if [ -z "$widget_name" ] || [[ "$widget_name" =~ $NAME_FORBIDDEN ]]; then
    die "invalid widget name '$widget_name': it must be non-empty and contain no double quote, backslash, backtick, newline or control character"
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
    die "template directory not found: $TEMPLATE_DIR"
fi

# A relative --out resolves against the CALLER's working directory; the default is
# the studio's own gitignored build/ directory, resolved from this script's path.
if [ -n "$out_dir" ]; then
    case "$out_dir" in
        /*) target="$out_dir" ;;
        *) target="$PWD/$out_dir" ;;
    esac
else
    target="$STUDIO_ROOT/build/$widget_id"
fi

# --- Template manifest (the "never renders in place" proof) ------------------

# A digest of the template's names and bytes, taken before anything is written. The
# tool only ever reads the template; re-hashing at the end turns a violated
# invariant into a failed run instead of a poisoned template.
template_manifest() {
    find "$TEMPLATE_DIR" -type f -print0 \
        | sort -z \
        | xargs -0 -r sha256sum \
        | sha256sum \
        | cut -d' ' -f1
}

manifest_before="$(template_manifest)"

# --- Copy -------------------------------------------------------------------

# A non-empty target is only replaced with an explicit --force.
if [ -e "$target" ] && [ -n "$(ls -A -- "$target")" ]; then
    if [ "$force" -ne 1 ]; then
        die "target directory is not empty: $target (use --force to replace it)"
    fi
    rm -rf -- "$target"
fi

mkdir -p -- "$target"
cp -a -- "$TEMPLATE_DIR/." "$target/"

# --- Substitution ------------------------------------------------------------

# Escape a value so it is a literal sed replacement string. '&' in a replacement
# expands to the whole match and '\' starts an escape, so both -- and the '|' used
# as the delimiter below -- are backslash-escaped. Mirrors tuya's
# plasmoid_escape_sed_replacement.
escape_sed_replacement() {
    printf '%s' "$1" | sed -e 's/[&\\|]/\\&/g'
}

id_replacement="$(escape_sed_replacement "$widget_id")"
name_replacement="$(escape_sed_replacement "$widget_name")"

# Walk every regular file of the COPY -- find -type f, skipping .git and nothing
# else -- and substitute both tokens in place.
while IFS= read -r -d '' file; do
    sed -i -e "s|@WIDGET_ID@|$id_replacement|g" \
           -e "s|@WIDGET_NAME@|$name_replacement|g" \
           "$file"
done < <(find "$target" \( -name .git -prune \) -o -type f -print0)

# --- Post-conditions ---------------------------------------------------------

# Nothing may survive unsubstituted in the copy: a leftover token would reach the
# installed metadata.json as a literal.
if grep -rIl -e '@WIDGET_ID@' -e '@WIDGET_NAME@' "$target" >/dev/null 2>&1; then
    die "a placeholder survived the substitution in $target"
fi

manifest_after="$(template_manifest)"
if [ "$manifest_before" != "$manifest_after" ]; then
    die "the template tree changed during the run: $TEMPLATE_DIR"
fi

# The installer is executable in the template; re-assert it in the copy so a lost
# mode bit cannot make the new widget uninstallable-by-default.
chmod +x -- "$target/install.sh"

# --- Report ------------------------------------------------------------------

printf 'Scaffolded a new widget at %s\n' "$target"
printf '  id:   %s\n' "$widget_id"
printf '  name: %s\n' "$widget_name"
printf '\n'
printf 'Next steps:\n'
printf '  cd "%s" && ./install.sh\n' "$target"
printf '  cd "%s" && node --test tests/*.mjs\n' "$target"
printf '  read docs/protocols/create-a-new-widget.md in the studio\n'
