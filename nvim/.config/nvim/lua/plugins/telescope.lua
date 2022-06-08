local ok, telescope = pcall(require, "telescope")
if not ok then
    return
end

local actions = require("telescope.actions")

telescope.setup({
    defaults = {
        layout_strategy = "vertical",
        layout_config = { width = 0.8, height = 0.8 },
        path_display = { "truncate" },
        file_ignore_patterns = { "jpg", "jpeg", "ttf", "otf", "png*", "vendor", ".vscode", ".gitlab", "*cache*" },
        mappings = {
            i = {
                ["<C-n>"] = actions.cycle_history_next,
                ["<C-p>"] = actions.cycle_history_prev,

                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,

                ["<esc>"] = actions.close,

                ["<Down>"] = actions.move_selection_next,
                ["<Up>"] = actions.move_selection_previous,

                ["<CR>"] = actions.select_default,
                ["<C-s>"] = actions.select_horizontal,
                ["<C-v>"] = actions.select_vertical,
                ["<C-t>"] = actions.select_tab,

                ["<C-u>"] = actions.preview_scrolling_up,
                ["<C-d>"] = actions.preview_scrolling_down,

                ["<PageUp>"] = actions.results_scrolling_up,
                ["<PageDown>"] = actions.results_scrolling_down,

                ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                ["<C-l>"] = actions.complete_tag,
            },

            n = {
                ["<esc>"] = actions.close,
                ["<CR>"] = actions.select_default,
                ["<C-s>"] = actions.select_horizontal,
                ["<C-v>"] = actions.select_vertical,
                ["<C-t>"] = actions.select_tab,

                ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

                ["j"] = actions.move_selection_next,
                ["k"] = actions.move_selection_previous,
                ["H"] = actions.move_to_top,
                ["M"] = actions.move_to_middle,
                ["L"] = actions.move_to_bottom,

                ["<Down>"] = actions.move_selection_next,
                ["<Up>"] = actions.move_selection_previous,
                ["gg"] = actions.move_to_top,
                ["G"] = actions.move_to_bottom,

                ["<C-u>"] = actions.preview_scrolling_up,
                ["<C-d>"] = actions.preview_scrolling_down,

                ["<PageUp>"] = actions.results_scrolling_up,
                ["<PageDown>"] = actions.results_scrolling_down,
            },
        },
    },
    pickers = {
        live_grep = {
            find_command = "rg,--files",
            "--hidden",
            "-g",
            "!.git/**",
            additional_args = function()
                return { "--hidden" }
            end,
        },
        git_files = {
            previewer = false,
            additional_args = function()
                return { "--smart-case" }
            end,
        },
        buffers = {
            previewer = false,
        },
    },
})

require("telescope").load_extension("projects")

local util = require("plugins.util")
local colors = require("plugins.colors")

util.highlight({
    { group = "TelescopeBorder", bg = colors.none, fg = colors.green },
    { group = "TelescopePromptBorder", bg = colors.none, fg = colors.gray2 },
    { group = "TelescopeResultsBorder", bg = colors.none, fg = colors.gray2 },
    { group = "TelescopePreviewBorder", bg = colors.none, fg = colors.gray2 },
    { group = "TelescopeSelection", bg = colors.none, fg = colors.magneta },
})

require("plugins.mappings").telescope()
