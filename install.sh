#!/usr/bin/env bash

if [ ${UID} -eq 0 ]; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="${HOME}/.local/share/icons"
fi

readonly SRC_DIR=$(cd $(dirname $0) && pwd)

readonly COLOR_VARIANTS=("standard" "green" "grey" "orange" "pink" "purple" "red" "yellow")
readonly BRIGHT_VARIANTS=("" "dark")

readonly DEFAULT_NAME="Fluent"

usage() {
  printf "%s\n" "Usage: $0 [OPTIONS...] [COLOR VARIANTS...]"
  printf "\n%s\n" "OPTIONS:"
  printf "  %-25s%s\n"   "-a"       "Install all color folder versions"
  printf "  %-25s%s\n"   "-d DIR"   "Specify theme destination directory (Default: ${DEST_DIR})"
  printf "  %-25s%s\n"   "-n NAME"  "Specify theme name (Default: ${DEFAULT_NAME})"
  printf "  %-25s%s\n"   "-h"       "Show this help"
  printf "\n%s\n" "COLOR VARIANTS:"
  printf "  %-25s%s\n"   "standard" "Standard color folder version"
  printf "  %-25s%s\n"   "green"    "Green color folder version"
  printf "  %-25s%s\n"   "grey"     "Grey color folder version"
  printf "  %-25s%s\n"   "orange"   "Orange color folder version"
  printf "  %-25s%s\n"   "pink"     "Pink color folder version"
  printf "  %-25s%s\n"   "purple"   "Purple color folder version"
  printf "  %-25s%s\n"   "red"      "Red color folder version"
  printf "  %-25s%s\n"   "yellow"   "Yellow color folder version"
  printf "\n  %s\n" "By default, only the standard one is selected."
}

install_theme() {
  # Appends a dash if the variables are not empty
  if [[ "$1" != "standard" ]]; then
    local -r colorprefix="-$1"
  fi

  local -r brightprefix="${2:+-$2}"

  local -r THEME_NAME="${NAME}${colorprefix}${brightprefix}"
  local -r THEME_DIR="${DEST_DIR}/${THEME_NAME}"

  if [ -d "${THEME_DIR}" ]; then
    rm -r "${THEME_DIR}"
  fi

  echo "Installing '${THEME_NAME}'..."

  install -d "${THEME_DIR}"

  install -m644 "${SRC_DIR}/src/index.theme"                                     "${THEME_DIR}"

  # Update the name in index.theme
  sed -i "s/%NAME%/${THEME_NAME//-/ }/g"                                         "${THEME_DIR}/index.theme"

  if [ -z "${brightprefix}" ]; then
    cp -r "${SRC_DIR}"/src/{16,22,24,32,64,256,scalable,symbolic}                "${THEME_DIR}"
    cp -r "${SRC_DIR}"/links/{16,22,24,32,64,256,scalable,symbolic}              "${THEME_DIR}"
    if [ -n "${colorprefix}" ]; then
      install -m644 "${SRC_DIR}"/src/colors/color${colorprefix}/places/*.svg     "${THEME_DIR}/scalable/places"
      install -m644 "${SRC_DIR}"/src/colors/color${colorprefix}/apps/*.svg       "${THEME_DIR}/scalable/apps"
    fi
  else
    local -r STD_THEME_DIR="${THEME_DIR%-dark}"

    install -d "${THEME_DIR}"/{16,22,24,32,symbolic}

    cp -r "${SRC_DIR}"/src/16/{actions,devices,places}                           "${THEME_DIR}/16"
    cp -r "${SRC_DIR}"/src/22/{actions,devices,places}                           "${THEME_DIR}/22"
    cp -r "${SRC_DIR}"/src/24/{actions,devices,places}                           "${THEME_DIR}/24"
    cp -r "${SRC_DIR}"/src/32/actions                                            "${THEME_DIR}/32"
    cp -r "${SRC_DIR}"/src/symbolic/*                                            "${THEME_DIR}/symbolic"

    # Change icon color for dark theme
    sed -i "s/#363636/#dedede/g" "${THEME_DIR}"/{16,22,24,32}/actions/*.svg
    sed -i "s/#363636/#dedede/g" "${THEME_DIR}"/{16,22,24}/{places,devices}/*.svg
    sed -i "s/#363636/#dedede/g" "${THEME_DIR}"/symbolic/{actions,apps,categories,devices,emblems,emotes,mimetypes,places,status}/*.svg

    cp -r "${SRC_DIR}"/links/16/{actions,devices,places}                         "${THEME_DIR}/16"
    cp -r "${SRC_DIR}"/links/22/{actions,devices,places}                         "${THEME_DIR}/22"
    cp -r "${SRC_DIR}"/links/24/{actions,devices,places}                         "${THEME_DIR}/24"
    cp -r "${SRC_DIR}"/links/32/actions                                          "${THEME_DIR}/32"
    cp -r "${SRC_DIR}"/links/symbolic/*                                          "${THEME_DIR}/symbolic"

    # Link the common icons
    ln -sr "${STD_THEME_DIR}/scalable"                                           "${THEME_DIR}/scalable"
    ln -sr "${STD_THEME_DIR}/16/mimetypes"                                       "${THEME_DIR}/16/mimetypes"
    ln -sr "${STD_THEME_DIR}/16/panel"                                           "${THEME_DIR}/16/panel"
    ln -sr "${STD_THEME_DIR}/16/status"                                          "${THEME_DIR}/16/status"
    ln -sr "${STD_THEME_DIR}/22/emblems"                                         "${THEME_DIR}/22/emblems"
    ln -sr "${STD_THEME_DIR}/22/mimetypes"                                       "${THEME_DIR}/22/mimetypes"
    ln -sr "${STD_THEME_DIR}/22/panel"                                           "${THEME_DIR}/22/panel"
    ln -sr "${STD_THEME_DIR}/24/animations"                                      "${THEME_DIR}/24/animations"
    ln -sr "${STD_THEME_DIR}/24/panel"                                           "${THEME_DIR}/24/panel"
    ln -sr "${STD_THEME_DIR}/32/categories"                                      "${THEME_DIR}/32/categories"
    ln -sr "${STD_THEME_DIR}/32/status"                                          "${THEME_DIR}/32/status"
    ln -sr "${STD_THEME_DIR}/64"                                                 "${THEME_DIR}/64"
    ln -sr "${STD_THEME_DIR}/256"                                                "${THEME_DIR}/256"
  fi

  ln -sr "${THEME_DIR}/16"                                                       "${THEME_DIR}/16@2x"
  ln -sr "${THEME_DIR}/22"                                                       "${THEME_DIR}/22@2x"
  ln -sr "${THEME_DIR}/24"                                                       "${THEME_DIR}/24@2x"
  ln -sr "${THEME_DIR}/32"                                                       "${THEME_DIR}/32@2x"
  ln -sr "${THEME_DIR}/64"                                                       "${THEME_DIR}/64@2x"
  ln -sr "${THEME_DIR}/256"                                                      "${THEME_DIR}/256@2x"
  ln -sr "${THEME_DIR}/scalable"                                                 "${THEME_DIR}/scalable@2x"
  
  ln -sr "${THEME_DIR}/16"                                                       "${THEME_DIR}/16@3x"
  ln -sr "${THEME_DIR}/22"                                                       "${THEME_DIR}/22@3x"
  ln -sr "${THEME_DIR}/24"                                                       "${THEME_DIR}/24@3x"
  ln -sr "${THEME_DIR}/32"                                                       "${THEME_DIR}/32@3x"
  ln -sr "${THEME_DIR}/64"                                                       "${THEME_DIR}/64@3x"
  ln -sr "${THEME_DIR}/256"                                                      "${THEME_DIR}/256@3x"
  ln -sr "${THEME_DIR}/scalable"                                                 "${THEME_DIR}/scalable@3x"

  gtk-update-icon-cache "${THEME_DIR}"
}

while [ $# -gt 0 ]; do
  case "${1}" in
    -a|--all)
      colors=("${COLOR_VARIANTS[@]}")
      ;;
    -d|--dest)
      DEST_DIR="${2}"
      shift
      ;;
    -n|--name)
      NAME="${2}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      # If the argument is a color variant, append it to the colors to be installed
      if [[ " ${COLOR_VARIANTS[*]} " = *" ${1} "* ]] && [[ "${colors[*]}" != *${1}* ]]; then
        colors+=("${1}")
      else
        echo "ERROR: Unrecognized installation option '${1}'."
        echo "Try '${0} --help' for more information."
        exit 1
      fi
  esac

  shift
done

# Default name is 'Fluent'
: "${NAME:="${DEFAULT_NAME}"}"

# By default, only the standard color variant is selected
for color in "${colors[@]:-standard}"; do
  for bright in "${BRIGHT_VARIANTS[@]}"; do
    install_theme "${color}" "${bright}"
  done
done
