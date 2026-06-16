#!/bin/bash
KEY=$1
FILE=~/dotfiles/ghostty/.config/ghostty/themes/flume
if [ ! -f "$FILE" ]; then
    FILE=~/.config/ghostty/themes/flume
fi

# Default values if file doesn't exist
if [ ! -f "$FILE" ]; then
    case "$KEY" in
        background) echo "#e6dfcf" ;;
        foreground) echo "#141312" ;;
        palette_0) echo "#141312" ;;
        selection-background) echo "#d1c1a9" ;;
        palette_8) echo "#4f473d" ;;
        palette_1) echo "#a63d3f" ;;
        palette_2) echo "#4f6a32" ;;
        palette_3) echo "#83580c" ;;
        palette_4) echo "#315f86" ;;
        palette_5) echo "#8f3d7a" ;;
        palette_6) echo "#266a76" ;;
        palette_9) echo "#b84b4c" ;;
        *) echo "#141312" ;;
    esac
    exit 0
fi

if [[ "$KEY" == palette_* ]]; then
    IDX=${KEY#palette_}
    # Parse palette = IDX=color
    awk -F'=' -v idx="$IDX" '$1 ~ "palette" { gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 == idx) {print $3} }' "$FILE" | tr -d ' \r'
else
    # Parse standard keys or commented-out override keys (e.g. # border = #a49376)
    awk -F'=' -v key="$KEY" '
        $1 ~ key {
            k = $1; gsub(/^#[ \t]*/, "", k); gsub(/[ \t]+$/, "", k);
            if (k == key) {
                val = $2; gsub(/^[ \t]+|[ \t]+$/, "", val);
                print val
            }
        }
    ' "$FILE" | tr -d ' \r'
fi
