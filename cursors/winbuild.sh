#!/usr/bin/env bash
set -e

has_command() {
  command -v "$1" >/dev/null 2>&1
}

check_and_install_tools() {
  if ! has_command inkscape; then
    echo "Inkscape not found. Installing Inkscape..."
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

build_windows_cursors() {
  local src_png_dir="$1"
  local build_dir="$2"

  mkdir -p "$build_dir"
  echo "Generating Windows cursors (.cur) in $build_dir from PNGs in $src_png_dir ..."

  for PNG in "$src_png_dir"/*.png; do
    BASENAME=$(basename "$PNG" .png)
    magick convert "$PNG" -define icon:auto-resize=32,40,48,64 "$build_dir/$BASENAME.cur"
  done

  echo "Windows cursor build complete in $build_dir"
}

main() {
  check_and_install_tools
  
  
  ./svgturn.sh
  ./svgturn-white.sh
  
  
  SRC=$PWD/src
  
  # Just for the svg path
  PNG_DARK="$PWD/output-png"
  PNG_WHITE="$PWD/output-png-white"

  # Build output folders for Windows .cur files
  BUILD_DARK="$SRC/../dist-win"
  BUILD_WHITE="$SRC/../dist-win-white"

  # Build bundled Windows cursors with multiple sizes embedded in each .cur
  build_windows_cursors "$PNG_DARK" "$BUILD_DARK"
  build_windows_cursors "$PNG_WHITE" "$BUILD_WHITE"

  echo "All done! Windows cursors with bundled DPI sizes are in dist-win and dist-win-white."
}

main "$@"
