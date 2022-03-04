lua << EOF

package.loaded["theme"] = nil
package.loaded["theme.base"] = nil
package.loaded["theme.treesitter"] = nil
package.loaded["theme.lsp"] = nil
package.loaded["theme.others"] = nil

local colors = {
  none = "NONE",
  fg = "#abb2bf",
  bg = "#282828",
  black = "#282828",
  black_1 = "#3c3836",
  green = "#98971a",
  green_1 = "#b8bb26",
  white = "#fbf1c7",
  white_1 = "#ebdbb2",
  white_2 = "#d5c4a1",
  blue = "#458588",
  blue_1 = "#83a598",
  blue_2 = "#076678",
  orange = "#d65d0e",
  orange_1 = "#fe8019",
  orange_2 = "#af3a03",
  yellow = "#d79921",
  yellow_1 = "#fabd2f",
  yellow_2 = "#b57614",
  red = "#cc241d",
  red_1 = "#fb4934",
  red_2 = "#ffbba6",
  red_3 = "#9d0006",
  grey = "#928374",
  grey_1 = "#a89984",
  grey_2 = "#928374",
  grey_3 = "#282c34",
  grey_4 = "#2c323c",
  grey_5 = "#3e4452",
  grey_6 = "#3b4048",
  grey_7 = "#5c5c5c",
  grey_8 = "#252931",
  gold = "#7d9921",
}

require("theme").load_colors(colors, name)

EOF
