#!/bin/bash

# Centralized Ghostty theme file
FILE=~/dotfiles/ghostty/.config/ghostty/themes/flume
if [ ! -f "$FILE" ]; then
    FILE=~/.config/ghostty/themes/flume
fi

# Function to get color from file, with a default value
get_color() {
    local key=$1
    local default=$2
    if [ ! -f "$FILE" ]; then
        echo "$default"
        return
    fi
    
    if [[ "$key" == palette_* ]]; then
        local idx=${key#palette_}
        local val=$(awk -F'=' -v idx="$idx" '$1 ~ "palette" { gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 == idx) {print $3} }' "$FILE" | tr -d ' \r')
        echo "${val:-$default}"
    else
        local val=$(awk -F'=' -v k="$key" '
            $1 ~ k {
                k_part = $1; gsub(/^#[ \t]*/, "", k_part); gsub(/[ \t]+$/, "", k_part);
                if (k_part == k) {
                    v = $2; gsub(/^[ \t]+|[ \t]+$/, "", v);
                    print v
                }
            }
        ' "$FILE" | tr -d ' \r')
        echo "${val:-$default}"
    fi
}

# Extract all colors
thm_bg=$(get_color background "#e6dfcf")
thm_fg=$(get_color foreground "#141312")
thm_black=$(get_color palette_0 "#141312")
thm_gray=$(get_color selection-background "#d1c1a9")
thm_lgray=$(get_color palette_8 "#4f473d")
thm_red=$(get_color palette_1 "#a63d3f")
thm_green=$(get_color palette_2 "#4f6a32")
thm_yellow=$(get_color palette_3 "#83580c")
thm_blue=$(get_color palette_4 "#315f86")
thm_pink=$(get_color palette_5 "#8f3d7a")
thm_cyan=$(get_color palette_6 "#266a76")
thm_orange=$(get_color palette_9 "#b84b4c")

# Target file to write
TARGET_DIR=~/dotfiles/tmux/.config/tmux/tmp
mkdir -p "$TARGET_DIR"
TARGET_FILE="$TARGET_DIR/colors.conf"

# Write TMUX variables and settings
cat <<EOF > "$TARGET_FILE"
# Generated colors
thm_bg="$thm_bg"
thm_fg="$thm_fg"
thm_black="$thm_black"
thm_gray="$thm_gray"
thm_lgray="$thm_lgray"
thm_red="$thm_red"
thm_green="$thm_green"
thm_yellow="$thm_yellow"
thm_blue="$thm_blue"
thm_pink="$thm_pink"
thm_cyan="$thm_cyan"
thm_orange="$thm_orange"

# Apply styles
set -g status-style bg=\$thm_gray,fg=\$thm_fg
set -g status-left " #[bold]#[fg=\$thm_blue, bg=\$thm_gray]#H #[bold]#[fg=\$thm_green, bg=\$thm_gray]#S "
set -g status-right "#[bold]#[fg=\$thm_green, bg=\$thm_gray]CPU#[default]#[bold]:#{cpu_percentage} #[bold]#[fg=\$thm_blue, bg=\$thm_gray]RAM#[default]#[bold]:#{ram_percentage} "
set -g window-status-separator " "
set -g window-status-current-format "#[bold]#[fg=\$thm_fg, bg=\$thm_gray]#I:#[fg=\$thm_blue, bg=\$thm_gray]#{b:pane_current_path}#[fg=\$thm_fg, bg=\$thm_gray]:#[fg=\$thm_green, bg=\$thm_gray]#W"
set -g window-status-format "#[bold]#[fg=\$thm_lgray, bg=\$thm_gray]#I:#{b:pane_current_path}:#W"
set -g pane-border-style fg=\$thm_gray
set -g pane-active-border-style fg=\$thm_gray
EOF

# Source the generated file
tmux source-file "$TARGET_FILE"
