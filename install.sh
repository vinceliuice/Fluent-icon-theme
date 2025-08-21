#!/usr/bin/env bash
# Refactored version: Cross-color deduplication + same-color light/dark reuse
# Interface compatible with README

set -euo pipefail

#==========================
# Default installation path (global if root)
#==========================
if [ "${UID}" -eq 0 ]; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="${HOME}/.local/share/icons"
fi

# Source directory = script location
readonly SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

# Color & brightness variants
readonly COLOR_VARIANTS=("standard" "green" "grey" "orange" "pink" "purple" "red" "yellow" "teal")
readonly BRIGHT_VARIANTS=("" "light" "dark")

readonly DEFAULT_NAME="Fluent"

#==========================
# Help text
#==========================
usage() {
  cat << EOF
Usage: $0 [OPTION] | [COLOR VARIANTS]...

OPTIONS:
  -a, --all                Install all color folder versions
  -d, --dest               Specify theme destination directory (Default: $HOME/.local/share/icons)
  -n, --name               Specify theme name (Default: Fluent)
  -h, --help               Show this help

COLOR VARIANTS:
  standard                 Standard color folder version
  green                    Green color folder version
  grey                     Grey color folder version
  orange                   Orange color folder version
  pink                     Pink color folder version
  purple                   Purple color folder version
  red                      Red color folder version
  yellow                   Yellow color folder version
  teal                     Teal color folder version

  By default, only the standard one is selected.
EOF
}

#==========================
# Utilities
#==========================
die() { echo "ERROR: $*" >&2; exit 1; }

install_file() { # mode src dest
  install -m"$1" "$2" "$3"
}

ensure_dir() {
  install -d "$1"
}

safe_rm_dir() {
  local d="$1"
  if [ -d "$d" ] || [ -L "$d" ]; then
    rm -rf --one-file-system "$d"
  fi
}

# Create a relative symlink (replace if exists)
rel_link() {
  local target="$1"
  local linkpath="$2"
  safe_rm_dir "$linkpath"
  ln -sr "$target" "$linkpath"
}

# Merge directory contents (overwrite on conflict)
merge_copy() {
  local dir_src="$1"
  local dir_dst="$2"
  [ -d "$dir_src" ] || return 0
  ensure_dir "$dir_dst"
  cp -rT "$dir_src" "$dir_dst" 2>/dev/null || cp -r "$dir_src/." "$dir_dst/"
}

# Sed replace in-place (ignore if no match)
safe_sed_replace() {
  local from="$1" to="$2" pattern="$3"
  shopt -s nullglob
  local files=( $pattern )
  shopt -u nullglob
  [ "${#files[@]}" -eq 0 ] && return 0
  sed -i "s/${from//\//\\/}/${to//\//\\/}/g" "${files[@]}"
}

#==========================
# Shared bases (hidden dirs, not exposed as themes)
#==========================
SHARED_BASE=""
SHARED_LIGHT_BASE=""
SHARED_DARK_BASE=""

init_shared_names() {
  SHARED_BASE="${DEST_DIR}/.${NAME}-base"
  SHARED_LIGHT_BASE="${DEST_DIR}/.${NAME}-light-base"
  SHARED_DARK_BASE="${DEST_DIR}/.${NAME}-dark-base"
}

# Build base for standard brightness (full content without index.theme)
build_shared_base() {
  safe_rm_dir "${SHARED_BASE}"
  echo "Preparing shared base: ${SHARED_BASE}"
  ensure_dir "${SHARED_BASE}"
  for d in 16 22 24 32 256 scalable symbolic; do
    merge_copy "${SRC_DIR}/src/${d}" "${SHARED_BASE}/${d}"
  done
  for d in 16 22 24 32 256 scalable symbolic; do
    merge_copy "${SRC_DIR}/links/${d}" "${SHARED_BASE}/${d}"
  done
}

# Build base for light variant (only 16/22/24 panel, #dedede -> #363636)
build_shared_light_base() {
  safe_rm_dir "${SHARED_LIGHT_BASE}"
  echo "Preparing shared light base: ${SHARED_LIGHT_BASE}"
  ensure_dir "${SHARED_LIGHT_BASE}"
  for sz in 16 22 24; do
    if [ -d "${SRC_DIR}/src/${sz}/panel" ]; then
      merge_copy "${SRC_DIR}/src/${sz}/panel" "${SHARED_LIGHT_BASE}/${sz}/panel"
      safe_sed_replace "#dedede" "#363636" "${SHARED_LIGHT_BASE}/${sz}/panel/*.svg"
    fi
    if [ -d "${SRC_DIR}/links/${sz}/panel" ]; then
      merge_copy "${SRC_DIR}/links/${sz}/panel" "${SHARED_LIGHT_BASE}/${sz}/panel"
    fi
  done
}

# Build base for dark variant (subset dirs with #363636 -> #dedede)
build_shared_dark_base() {
  safe_rm_dir "${SHARED_DARK_BASE}"
  echo "Preparing shared dark base: ${SHARED_DARK_BASE}"
  ensure_dir "${SHARED_DARK_BASE}"

  merge_copy "${SRC_DIR}/src/16/actions"     "${SHARED_DARK_BASE}/16/actions"
  merge_copy "${SRC_DIR}/src/16/devices"     "${SHARED_DARK_BASE}/16/devices"
  merge_copy "${SRC_DIR}/src/16/places"      "${SHARED_DARK_BASE}/16/places"
  merge_copy "${SRC_DIR}/src/22/actions"     "${SHARED_DARK_BASE}/22/actions"
  merge_copy "${SRC_DIR}/src/22/categories"  "${SHARED_DARK_BASE}/22/categories"
  merge_copy "${SRC_DIR}/src/22/devices"     "${SHARED_DARK_BASE}/22/devices"
  merge_copy "${SRC_DIR}/src/22/places"      "${SHARED_DARK_BASE}/22/places"
  merge_copy "${SRC_DIR}/src/24/actions"     "${SHARED_DARK_BASE}/24/actions"
  merge_copy "${SRC_DIR}/src/24/devices"     "${SHARED_DARK_BASE}/24/devices"
  merge_copy "${SRC_DIR}/src/24/places"      "${SHARED_DARK_BASE}/24/places"
  merge_copy "${SRC_DIR}/src/32/actions"     "${SHARED_DARK_BASE}/32/actions"
  merge_copy "${SRC_DIR}/src/32/devices"     "${SHARED_DARK_BASE}/32/devices"
  merge_copy "${SRC_DIR}/src/32/status"      "${SHARED_DARK_BASE}/32/status"

  if [ -d "${SRC_DIR}/src/symbolic" ]; then
    ensure_dir "${SHARED_DARK_BASE}/symbolic"
    cp -r "${SRC_DIR}/src/symbolic/." "${SHARED_DARK_BASE}/symbolic/"
  fi

  safe_sed_replace "#363636" "#dedede" "${SHARED_DARK_BASE}/22/categories/*.svg"
  for sz in 16 22 24 32; do
    safe_sed_replace "#363636" "#dedede" "${SHARED_DARK_BASE}/${sz}/actions/*.svg"
  done
  safe_sed_replace "#363636" "#dedede" "${SHARED_DARK_BASE}/32/devices/*.svg"
  safe_sed_replace "#363636" "#dedede" "${SHARED_DARK_BASE}/32/status/*.svg"
  for sz in 16 22 24; do
    safe_sed_replace "#363636" "#dedede" "${SHARED_DARK_BASE}/${sz}/places/*.svg"
    safe_sed_replace "#363636" "#dedede" "${SHARED_DARK_BASE}/${sz}/devices/*.svg"
  done
  for sub in actions apps categories devices emblems emotes mimetypes places status; do
    safe_sed_replace "#363636" "#dedede" "${SHARED_DARK_BASE}/symbolic/${sub}/*.svg"
  done

  merge_copy "${SRC_DIR}/links/16/actions"     "${SHARED_DARK_BASE}/16/actions"
  merge_copy "${SRC_DIR}/links/16/devices"     "${SHARED_DARK_BASE}/16/devices"
  merge_copy "${SRC_DIR}/links/16/places"      "${SHARED_DARK_BASE}/16/places"
  merge_copy "${SRC_DIR}/links/22/actions"     "${SHARED_DARK_BASE}/22/actions"
  merge_copy "${SRC_DIR}/links/22/categories"  "${SHARED_DARK_BASE}/22/categories"
  merge_copy "${SRC_DIR}/links/22/devices"     "${SHARED_DARK_BASE}/22/devices"
  merge_copy "${SRC_DIR}/links/22/places"      "${SHARED_DARK_BASE}/22/places"
  merge_copy "${SRC_DIR}/links/24/actions"     "${SHARED_DARK_BASE}/24/actions"
  merge_copy "${SRC_DIR}/links/24/devices"     "${SHARED_DARK_BASE}/24/devices"
  merge_copy "${SRC_DIR}/links/24/places"      "${SHARED_DARK_BASE}/24/places"
  merge_copy "${SRC_DIR}/links/32/actions"     "${SHARED_DARK_BASE}/32/actions"
  merge_copy "${SRC_DIR}/links/32/devices"     "${SHARED_DARK_BASE}/32/devices"
  merge_copy "${SRC_DIR}/links/32/status"      "${SHARED_DARK_BASE}/32/status"
  if [ -d "${SRC_DIR}/links/symbolic" ]; then
    merge_copy "${SRC_DIR}/links/symbolic"     "${SHARED_DARK_BASE}/symbolic"
  fi
}

#==========================
# Install a single theme (color + brightness)
#==========================
install_theme() {
  local color="$1"
  local bright="$2"

  local colorprefix=""
  [ "$color" != "standard" ] && colorprefix="-$color"
  local brightprefix=""
  [ -n "$bright" ] && brightprefix="-$bright"

  local THEME_NAME="${NAME}${colorprefix}${brightprefix}"
  local THEME_DIR="${DEST_DIR}/${THEME_NAME}"

  local TMP_DIR="${THEME_DIR}.tmp.$$"
  safe_rm_dir "${THEME_DIR}.tmp*"
  ensure_dir "${TMP_DIR}"

  case "$color" in
    standard)
      theme_color='#198ee6' ;;
    purple)
      theme_color='#dc63ee' ;;
    pink)
      theme_color='#ff5c93' ;;
    red)
      theme_color='#ff6666' ;;
    orange)
      theme_color='#ff9c33' ;;
    yellow)
      theme_color='#ffcb52' ;;
    green)
      theme_color='#67cb6b' ;;
    teal)
      theme_color='#32c8ba' ;;
    grey)
      theme_color='#808080' ;;
  esac

  echo "Installing '${THEME_NAME}'..."

  install_file 644 "${SRC_DIR}/src/index.theme" "${TMP_DIR}/index.theme"
  sed -i "s/%NAME%/${THEME_NAME//-/ }/g" "${TMP_DIR}/index.theme"

  if [ -z "${bright}" ]; then
    for d in 16 22 24 32 256 symbolic; do
      rel_link "${SHARED_BASE}/${d}" "${TMP_DIR}/${d}"
    done
    if [ "$color" = "standard" ]; then
      rel_link "${SHARED_BASE}/scalable" "${TMP_DIR}/scalable"
    else
      ensure_dir "${TMP_DIR}/scalable"
      for sub in applets devices mimetypes; do
        [ -d "${SHARED_BASE}/scalable/${sub}" ] && rel_link "${SHARED_BASE}/scalable/${sub}" "${TMP_DIR}/scalable/${sub}"
      done
      for sub in apps places; do
        ensure_dir "${TMP_DIR}/scalable/${sub}"
        merge_copy "${SRC_DIR}/src/scalable/${sub}" "${TMP_DIR}/scalable/${sub}"
        safe_sed_replace "#198ee6" "${theme_color}" "${TMP_DIR}/scalable/${sub}/*.svg"
        merge_copy "${SRC_DIR}/links/scalable/${sub}" "${TMP_DIR}/scalable/${sub}"
      done
    fi
  elif [ "${bright}" = "light" ]; then
    local STD_THEME_DIR="${DEST_DIR}/${NAME}${colorprefix}"
    for sz in 16 22 24; do
      ensure_dir "${TMP_DIR}/${sz}"
      rel_link "${SHARED_LIGHT_BASE}/${sz}/panel" "${TMP_DIR}/${sz}/panel"
    done
    rel_link "${STD_THEME_DIR}/scalable"     "${TMP_DIR}/scalable"
    rel_link "${STD_THEME_DIR}/32"           "${TMP_DIR}/32"
    rel_link "${STD_THEME_DIR}/256"          "${TMP_DIR}/256"
    rel_link "${STD_THEME_DIR}/16/actions"   "${TMP_DIR}/16/actions"
    rel_link "${STD_THEME_DIR}/16/devices"   "${TMP_DIR}/16/devices"
    rel_link "${STD_THEME_DIR}/16/mimetypes" "${TMP_DIR}/16/mimetypes"
    rel_link "${STD_THEME_DIR}/16/places"    "${TMP_DIR}/16/places"
    rel_link "${STD_THEME_DIR}/16/status"    "${TMP_DIR}/16/status"
    rel_link "${STD_THEME_DIR}/22/actions"   "${TMP_DIR}/22/actions"
    rel_link "${STD_THEME_DIR}/22/categories" "${TMP_DIR}/22/categories"
    rel_link "${STD_THEME_DIR}/22/devices"   "${TMP_DIR}/22/devices"
    rel_link "${STD_THEME_DIR}/22/emblems"   "${TMP_DIR}/22/emblems"
    rel_link "${STD_THEME_DIR}/22/mimetypes" "${TMP_DIR}/22/mimetypes"
    rel_link "${STD_THEME_DIR}/22/places"    "${TMP_DIR}/22/places"
    rel_link "${STD_THEME_DIR}/24/actions"   "${TMP_DIR}/24/actions"
    rel_link "${STD_THEME_DIR}/24/animations" "${TMP_DIR}/24/animations"
    rel_link "${STD_THEME_DIR}/24/devices"   "${TMP_DIR}/24/devices"
    rel_link "${STD_THEME_DIR}/24/places"    "${TMP_DIR}/24/places"
    rel_link "${STD_THEME_DIR}/symbolic"     "${TMP_DIR}/symbolic"

  elif [ "${bright}" = "dark" ]; then
    local STD_THEME_DIR="${DEST_DIR}/${NAME}${colorprefix}"
    for path in \
      "16/actions" "16/devices" "16/places" \
      "22/actions" "22/categories" "22/devices" "22/places" \
      "24/actions" "24/devices" "24/places" \
      "32/actions" "32/devices" "32/status" \
      "symbolic"
    do
      local src="${SHARED_DARK_BASE}/${path}"
      [ -e "$src" ] && ensure_dir "${TMP_DIR}/${path}" && rel_link "$src" "${TMP_DIR}/${path}"
    done
    rel_link "${STD_THEME_DIR}/scalable"       "${TMP_DIR}/scalable"
    rel_link "${STD_THEME_DIR}/16/mimetypes"   "${TMP_DIR}/16/mimetypes"
    rel_link "${STD_THEME_DIR}/16/status"      "${TMP_DIR}/16/status"
    rel_link "${STD_THEME_DIR}/16/panel"       "${TMP_DIR}/16/panel"
    rel_link "${STD_THEME_DIR}/22/emblems"     "${TMP_DIR}/22/emblems"
    rel_link "${STD_THEME_DIR}/22/mimetypes"   "${TMP_DIR}/22/mimetypes"
    rel_link "${STD_THEME_DIR}/22/panel"       "${TMP_DIR}/22/panel"
    rel_link "${STD_THEME_DIR}/24/animations"  "${TMP_DIR}/24/animations"
    rel_link "${STD_THEME_DIR}/24/panel"       "${TMP_DIR}/24/panel"
    rel_link "${STD_THEME_DIR}/32/categories"  "${TMP_DIR}/32/categories"
    rel_link "${STD_THEME_DIR}/256"            "${TMP_DIR}/256"
  fi

  for mult in 2 3; do
    rel_link "${TMP_DIR}/16"      "${TMP_DIR}/16@${mult}x"
    rel_link "${TMP_DIR}/22"      "${TMP_DIR}/22@${mult}x"
    rel_link "${TMP_DIR}/24"      "${TMP_DIR}/24@${mult}x"
    rel_link "${TMP_DIR}/32"      "${TMP_DIR}/32@${mult}x"
    rel_link "${TMP_DIR}/256"     "${TMP_DIR}/256@${mult}x"
    rel_link "${TMP_DIR}/scalable" "${TMP_DIR}/scalable@${mult}x"
  done

  safe_rm_dir "${THEME_DIR}"
  mv "${TMP_DIR}" "${THEME_DIR}"

  gtk-update-icon-cache "${THEME_DIR}" >/dev/null 2>&1 || true
}

#==========================
# Argument parsing
#==========================
NAME=""
colors=()

while [ $# -gt 0 ]; do
  case "$1" in
    -a|--all) colors=("${COLOR_VARIANTS[@]}") ;;
    -d|--dest) [ $# -ge 2 ] || die "Missing argument for $1"; DEST_DIR="$2"; shift ;;
    -n|--name) [ $# -ge 2 ] || die "Missing argument for $1"; NAME="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ " ${COLOR_VARIANTS[*]} " == *" $1 "* ]]; then
        [[ " ${colors[*]-} " != *" $1 "* ]] && colors+=("$1")
      else
        die "Unrecognized installation option '$1'. Try '$0 --help'."
      fi
      ;;
  esac
  shift
done

: "${NAME:="${DEFAULT_NAME}"}"

if [ ${#colors[@]} -eq 0 ]; then
  colors=(standard)
fi

#==========================
# Prepare shared bases
#==========================
ensure_dir "${DEST_DIR}"
init_shared_names
build_shared_base
build_shared_light_base
build_shared_dark_base

#==========================
# Installation loop
#==========================
for color in "${colors[@]}"; do
  for bright in "${BRIGHT_VARIANTS[@]}"; do
    install_theme "${color}" "${bright}"
  done
done

echo "Done."
