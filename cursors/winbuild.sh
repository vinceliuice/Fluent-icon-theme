#!/usr/bin/env bash
set -e

has_command() {
  command -v "$1" >/dev/null 2>&1
}

generate_pngs() {
  local src_dir="$1"
  cd "$SRC/$src_dir" || exit 1

  mkdir -p ../x1 ../x1_25 ../x1_5 ../x2

  find . -name "*.svg" -type f -exec sh -c 'inkscape -o "../x1/${0%.svg}.png" -w 32 -h 32 "$0"' {} \;
  find . -name "*.svg" -type f -exec sh -c 'inkscape -o "../x1_25/${0%.svg}.png" -w 40 -h 40 "$0"' {} \;
  find . -name "*.svg" -type f -exec sh -c 'inkscape -o "../x1_5/${0%.svg}.png" -w 48 -h 48 "$0"' {} \;
  find . -name "*.svg" -type f -exec sh -c 'inkscape -o "../x2/${0%.svg}.png" -w 64 -h 64 "$0"' {} \;

  cd "$SRC" || exit 1
}

build_windows_cursors() {
  local build_dir="$1"
  local src_base="$SRC"

  mkdir -p "$build_dir"
  echo -ne "Generating Windows cursors (.cur) in $build_dir ...\r"

  for PNG in "$src_base/x1"/*.png; do
    BASENAME=$(basename "$PNG" .png)

    PNG_32="$src_base/x1/${BASENAME}.png"
    PNG_40="$src_base/x1_25/${BASENAME}.png"
    PNG_48="$src_base/x1_5/${BASENAME}.png"
    PNG_64="$src_base/x2/${BASENAME}.png"

    INPUTS=()
    [[ -f "$PNG_32" ]] && INPUTS+=("$PNG_32")
    [[ -f "$PNG_40" ]] && INPUTS+=("$PNG_40")
    [[ -f "$PNG_48" ]] && INPUTS+=("$PNG_48")
    [[ -f "$PNG_64" ]] && INPUTS+=("$PNG_64")

    magick convert "${INPUTS[@]}" -define icon:auto-resize=32,40,48,64 "$build_dir/$BASENAME.cur"
  done

  echo -e "Generating Windows cursors... DONE"
}

check_and_install_tools() {
  if ! has_command inkscape; then
    echo "Inkscape not found. Installing Inkscape"
    sudo add-apt-repository universe -y 
    sudo add-apt-repository ppa:inkscape.dev/stable -y 
    sudo apt-get update -y
    sudo apt install inkscape -y
    echo "Inkscape installed!"
  fi

  if ! has_command magick; then
    echo "ImageMagick not found. Installing ImageMagick..."
    sudo apt-get update -y
    sudo apt install imagemagick -y
    echo "ImageMagick installed."
  fi
}

main() {
  check_and_install_tools

  SRC=$PWD/src

  rm -rf "$SRC/x1" "$SRC/x1_25" "$SRC/x1_5" "$SRC/x2"

  THEMES=( "svg" "svg-white" )

  for THEME_SVG in "${THEMES[@]}"; do
    generate_pngs "$THEME_SVG"

    BUILD="$SRC/../dist-win"
    if [[ "$THEME_SVG" == "svg-white" ]]; then
      BUILD="$SRC/../dist-win-white"
    fi

    build_windows_cursors "$BUILD"
  done

  rm -rf "$SRC/x1" "$SRC/x1_25" "$SRC/x1_5" "$SRC/x2"

  echo "Windows cursor build complete on Linux! Output in dist-win and dist-win-white."
}

main "$@"

