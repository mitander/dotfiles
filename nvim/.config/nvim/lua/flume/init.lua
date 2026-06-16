-- Flume: A wavy theme inspired by One Dark and Duskfox

local M = {}

M.colors = {
    -- warm paper / ink scaffold
    border = "#a49376",
    border_variant = "#b9aa8f",
    border_focused = "#315f86",

    bg = "#e6dfcf",
    terminal_bg = "#e6dfcf",

    surface = "#ddd3c0",
    surface_alt = "#d1c1a9",
    element = "#ddd3c0",
    element_hover = "#d1c1a9",
    element_active = "#bfa987",

    fg = "#141312",
    text = "#141312",
    muted = "#6b5f4f",
    placeholder = "#887a66",

    accent = "#315f86",
    highlight = "#eea645",

    active_line = "#ddd3c0",
    line_number = "#887a66",
    active_line_number = "#141312",
    indent_guide = "#c8bca6",

    -- terminal / ANSI.
    black = "#141312",
    bright_black = "#4f473d",
    dim_black = "#a49376",

    red = "#a63d3f",
    bright_red = "#b84b4c",
    dim_red = "#efd9d5",

    green = "#4f6a32",
    bright_green = "#5f7a3e",
    dim_green = "#dfe7d3",

    yellow = "#83580c",
    bright_yellow = "#9a6710",
    dim_yellow = "#efdfc6",

    blue = "#315f86",
    bright_blue = "#34658c",
    dim_blue = "#c8d9df",

    magenta = "#8f3d7a",
    bright_magenta = "#a03872",
    dim_magenta = "#e6cfda",

    cyan = "#266a76",
    bright_cyan = "#2f7782",
    dim_cyan = "#c9ddda",

    white = "#4f473d",
    bright_white = "#141312",
    dim_white = "#6b5f4f",

    -- syntax
    syntax_attribute = "#34658c",
    syntax_boolean = "#99405f",
    syntax_comment = "#695f51",
    syntax_doc_comment = "#5a625c",
    syntax_constant = "#83580c",
    syntax_function = "#315f86",
    syntax_type = "#266a76",
    syntax_keyword = "#8f3d7a",
    syntax_primary = "#141312",
    syntax_property = "#a63d3f",
    syntax_punctuation = "#4f473d",
    syntax_punctuation_bracket = "#4f473d",
    syntax_punctuation_special = "#9b4a2a",
    syntax_string = "#4f6a32",
    syntax_special = "#a03872",

    predictive = "#7b7f76",

    diff_add_bg = "#dfe7d3",
    diff_change_bg = "#dbe4e6",
    diff_delete_bg = "#efd9d5",

    hint = "#266a76",
    hint_bg = "#dbe4e6",
    warn_bg = "#efdfc6",
}

local function load_ghostty_colors()
    local paths = {
        vim.fn.expand("~/.config/ghostty/themes/flume"),
        vim.fn.expand("~/dotfiles/ghostty/.config/ghostty/themes/flume"),
    }
    local f
    for _, path in ipairs(paths) do
        f = io.open(path, "r")
        if f then break end
    end
    if not f then return end

    local ghostty = {}
    for line in f:lines() do
        local clean_line = line:match("^%s*(.-)%s*$")
        if clean_line and clean_line ~= "" then
            local is_comment, key, val = clean_line:match("^(#?)%s*([%w%-_]+)%s*=%s*(#[%da-fA-F]+)$")
            if not key then
                local is_pal_comment, pal_val = clean_line:match("^(#?)%s*palette%s*=%s*(.+)$")
                if pal_val then
                    local idx, color = pal_val:match("^(%d+)%s*=%s*(#[%da-fA-F]+)$")
                    if idx and color then
                        ghostty["color_" .. idx] = color
                    end
                end
            else
                ghostty[key] = val
            end
        end
    end
    f:close()

    local c = M.colors
    if ghostty.background then
        c.bg = ghostty.background
        c.terminal_bg = ghostty.background
        c.element = ghostty.background
    end
    if ghostty.foreground then
        c.fg = ghostty.foreground
        c.text = ghostty.foreground
        c.syntax_primary = ghostty.foreground
    end
    if ghostty["selection-background"] then
        c.surface_alt = ghostty["selection-background"]
        c.active_line = ghostty["selection-background"]
        c.indent_guide = ghostty["selection-background"]
    end

    local map = {
        color_0 = "black",
        color_1 = "red",
        color_2 = "green",
        color_3 = "yellow",
        color_4 = "blue",
        color_5 = "magenta",
        color_6 = "cyan",
        color_7 = "white",
        color_8 = "bright_black",
        color_9 = "bright_red",
        color_10 = "bright_green",
        color_11 = "bright_yellow",
        color_12 = "bright_blue",
        color_13 = "bright_magenta",
        color_14 = "bright_cyan",
        color_15 = "bright_white",
    }
    for k, v in pairs(map) do
        if ghostty[k] then
            c[v] = ghostty[k]
        end
    end

    for k, v in pairs(ghostty) do
        if c[k] ~= nil then
            c[k] = v
        end
    end
end

local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

function M.setup()
    load_ghostty_colors()
    local c = M.colors
    vim.o.background = "light"
    vim.g.colors_name = "flume"

    hi("Normal", { fg = c.syntax_primary, bg = c.bg })
    hi("NormalNC", { fg = c.syntax_primary, bg = c.bg })
    hi("NormalFloat", { fg = c.fg, bg = c.surface })
    hi("FloatBorder", { fg = c.border, bg = c.bg })
    hi("FloatTitle", { fg = c.text, bg = c.surface, bold = true })
    hi("WinSeparator", { fg = c.border_variant, bg = c.bg })
    hi("SignColumn", { bg = c.bg })
    hi("FoldColumn", { fg = c.placeholder, bg = c.bg })
    hi("Folded", { fg = c.muted, bg = c.surface })
    hi("EndOfBuffer", { fg = c.bg, bg = c.bg })
    hi("NonText", { fg = c.line_number })
    hi("Whitespace", { fg = c.line_number })
    hi("IblIndent", { fg = c.indent_guide })
    hi("IblWhitespace", { fg = c.indent_guide })
    hi("ColorColumn", { bg = c.surface })
    hi("CursorLine", { bg = c.active_line })
    hi("CursorLineNr", { fg = c.active_line_number, bg = c.active_line, bold = true })
    hi("LineNr", { fg = c.line_number, bg = c.bg })
    hi("Visual", { bg = c.element_active })
    hi("Search", { fg = c.text, bg = c.dim_blue })
    hi("IncSearch", { fg = c.black, bg = c.highlight })
    hi("CurSearch", { fg = c.black, bg = c.highlight })
    hi("MatchParen", { fg = c.text, bg = c.element_active, bold = true })
    hi("Directory", { fg = c.accent })
    hi("Title", { fg = c.syntax_property })

    hi("StatusLine", { fg = c.text, bg = c.surface_alt })
    hi("StatusLineNC", { fg = c.muted, bg = c.surface })
    hi("TabLine", { fg = c.muted, bg = c.surface })
    hi("TabLineSel", { fg = c.text, bg = c.bg, bold = true })
    hi("TabLineFill", { bg = c.surface })

    hi("Pmenu", { fg = c.fg, bg = c.surface })
    hi("PmenuSel", { fg = c.text, bg = c.element_active })
    hi("PmenuSbar", { bg = c.surface })
    hi("PmenuThumb", { bg = c.bright_black })
    hi("WildMenu", { fg = c.text, bg = c.element_active })

    hi("Question", { fg = c.green })
    hi("MoreMsg", { fg = c.green })
    hi("WarningMsg", { fg = c.yellow })
    hi("ErrorMsg", { fg = c.red })
    hi("ModeMsg", { fg = c.text })

    hi("DiffAdd", { bg = c.diff_add_bg })
    hi("DiffChange", { bg = c.diff_change_bg })
    hi("DiffDelete", { fg = c.red, bg = c.diff_delete_bg })
    hi("DiffText", { bg = c.dim_blue })
    hi("Added", { fg = c.green })
    hi("Changed", { fg = c.yellow })
    hi("Removed", { fg = c.red })

    hi("DiagnosticError", { fg = c.red })
    hi("DiagnosticWarn", { fg = c.yellow })
    hi("DiagnosticInfo", { fg = c.accent })
    hi("DiagnosticHint", { fg = c.hint })
    hi("DiagnosticOk", { fg = c.green })
    hi("DiagnosticVirtualTextError", { fg = c.red, bg = c.diff_delete_bg })
    hi("DiagnosticVirtualTextWarn", { fg = c.yellow, bg = c.warn_bg })
    hi("DiagnosticVirtualTextInfo", { fg = c.accent, bg = c.hint_bg })
    hi("DiagnosticVirtualTextHint", { fg = c.hint, bg = c.hint_bg })
    hi("DiagnosticUnderlineError", { sp = c.red, undercurl = true })
    hi("DiagnosticUnderlineWarn", { sp = c.yellow, undercurl = true })
    hi("DiagnosticUnderlineInfo", { sp = c.accent, undercurl = true })
    hi("DiagnosticUnderlineHint", { sp = c.hint, undercurl = true })

    hi("Comment", { fg = c.syntax_comment })
    hi("Constant", { fg = c.syntax_constant })
    hi("String", { fg = c.syntax_string })
    hi("Character", { fg = c.syntax_string })
    hi("Number", { fg = c.syntax_boolean })
    hi("Boolean", { fg = c.syntax_boolean })
    hi("Float", { fg = c.syntax_boolean })
    hi("Identifier", { fg = c.syntax_primary })
    hi("Function", { fg = c.syntax_function })
    hi("Statement", { fg = c.syntax_keyword })
    hi("Conditional", { fg = c.syntax_keyword })
    hi("Repeat", { fg = c.syntax_keyword })
    hi("Label", { fg = c.accent })
    hi("Operator", { fg = c.syntax_type })
    hi("Keyword", { fg = c.syntax_keyword })
    hi("Exception", { fg = c.syntax_keyword })
    hi("PreProc", { fg = c.syntax_keyword })
    hi("Include", { fg = c.syntax_keyword })
    hi("Define", { fg = c.syntax_keyword })
    hi("Macro", { fg = c.syntax_keyword })
    hi("PreCondit", { fg = c.syntax_keyword })
    hi("Type", { fg = c.syntax_type })
    hi("StorageClass", { fg = c.syntax_keyword })
    hi("Structure", { fg = c.syntax_type })
    hi("Typedef", { fg = c.syntax_type })
    hi("Special", { fg = c.syntax_special })
    hi("SpecialChar", { fg = c.syntax_special })
    hi("Tag", { fg = c.accent })
    hi("Delimiter", { fg = c.syntax_punctuation })
    hi("SpecialComment", { fg = c.syntax_doc_comment })
    hi("Debug", { fg = c.red })
    hi("Underlined", { fg = c.accent, underline = true })
    hi("Ignore", { fg = c.placeholder })
    hi("Error", { fg = c.red })
    hi("Todo", { fg = c.black, bg = c.highlight, bold = true })

    hi("@attribute", { fg = c.syntax_attribute })
    hi("@boolean", { fg = c.syntax_boolean })
    hi("@character", { fg = c.syntax_string })
    hi("@comment", { fg = c.syntax_comment })
    hi("@comment.documentation", { fg = c.syntax_doc_comment })
    hi("@constant", { fg = c.syntax_constant })
    hi("@constant.builtin", { fg = c.syntax_boolean })
    hi("@constructor", { fg = c.syntax_function })
    hi("@function", { fg = c.syntax_function })
    hi("@function.builtin", { fg = c.syntax_function })
    hi("@function.call", { fg = c.syntax_function })
    hi("@function.macro", { fg = c.syntax_function })
    hi("@keyword", { fg = c.syntax_keyword })
    hi("@keyword.conditional", { fg = c.syntax_keyword })
    hi("@keyword.function", { fg = c.syntax_keyword })
    hi("@keyword.operator", { fg = c.syntax_keyword })
    hi("@keyword.repeat", { fg = c.syntax_keyword })
    hi("@keyword.return", { fg = c.syntax_keyword })
    hi("@label", { fg = c.accent })
    hi("@module", { fg = c.syntax_primary })
    hi("@namespace", { fg = c.syntax_primary })
    hi("@number", { fg = c.syntax_boolean })
    hi("@number.float", { fg = c.syntax_boolean })
    hi("@operator", { fg = c.syntax_type })
    hi("@property", { fg = c.syntax_property })
    hi("@punctuation.bracket", { fg = c.syntax_punctuation_bracket })
    hi("@punctuation.delimiter", { fg = c.syntax_punctuation_bracket })
    hi("@punctuation.special", { fg = c.syntax_punctuation_special })
    hi("@string", { fg = c.syntax_string })
    hi("@string.documentation", { fg = c.syntax_string })
    hi("@string.escape", { fg = c.syntax_doc_comment })
    hi("@string.regexp", { fg = c.syntax_boolean })
    hi("@string.special", { fg = c.syntax_boolean })
    hi("@tag", { fg = c.accent })
    hi("@tag.attribute", { fg = c.syntax_attribute })
    hi("@tag.delimiter", { fg = c.syntax_property })
    hi("@text.literal", { fg = c.syntax_string })
    hi("@type", { fg = c.syntax_type })
    hi("@type.builtin", { fg = c.syntax_type })
    hi("@variable", { fg = c.syntax_primary })
    hi("@variable.builtin", { fg = c.syntax_boolean })
    hi("@variable.member", { fg = c.syntax_property })
    hi("@markup.heading", { fg = c.syntax_property, bold = true })
    hi("@markup.italic", { italic = true })
    hi("@markup.link", { fg = c.syntax_function, italic = true })
    hi("@markup.link.url", { fg = c.syntax_type, underline = true })
    hi("@markup.list", { fg = c.syntax_property })
    hi("@markup.raw", { fg = c.syntax_string })

    hi("GitSignsAdd", { fg = c.green, bg = c.bg })
    hi("GitSignsChange", { fg = c.yellow, bg = c.bg })
    hi("GitSignsDelete", { fg = c.red, bg = c.bg })
    hi("OilDir", { fg = c.accent })
    hi("OilFile", { fg = c.fg })
    hi("OilHidden", { fg = c.placeholder })
    hi("OilLink", { fg = c.cyan })
    hi("OilStatusLine", { fg = c.fg, bg = c.surface_alt, bold = true })

    local terminal_colors = {
        c.black,
        c.red,
        c.green,
        c.yellow,
        c.blue,
        c.magenta,
        c.cyan,
        c.white,
        c.bright_black,
        c.bright_red,
        c.bright_green,
        c.bright_yellow,
        c.bright_blue,
        c.bright_magenta,
        c.bright_cyan,
        c.bright_white,
    }

    for i, color in ipairs(terminal_colors) do
        vim.g["terminal_color_" .. (i - 1)] = color
    end
end

return M
