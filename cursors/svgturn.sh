#!/usr/bin/env bash
set -e

INPUT_DIR="./src/svg"
OUTPUT_DIR="./output-png"

mkdir -p "$OUTPUT_DIR"

for svgfile in "$INPUT_DIR"/*.svg; do
  filename=$(basename "$svgfile" .svg)
  echo "Converting $svgfile to $OUTPUT_DIR/$filename.png"
  
  
  inkscape  \
    --export-area-page \
    --export-background-opacity=0 \
    --export-type=png \
    -o "$OUTPUT_DIR/$filename.png" \
    "$svgfile"
done

echo "All SVGs converted to PNG with transparency and color match!"
