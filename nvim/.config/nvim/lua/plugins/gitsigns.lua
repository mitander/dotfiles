local ok, gitsigns = pcall(require, "gitsigns")
if not ok then
    print("error: could not load gitsigns")
    return
end

gitsigns.setup({
    signs = {
        add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
        change = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
        delete = { hl = "GitSignsDelete", text = "▎", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        topdelete = {
            hl = "GitSignsDelete",
            text = "▎",
            numhl = "GitSignsDeleteNr",
            linehl = "GitSignsDeleteLn",
        },
        changedelete = {
            hl = "GitSignsChange",
            text = "▎",
            numhl = "GitSignsChangeNr",
            linehl = "GitSignsChangeLn",
        },
    },
    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,
    watch_gitdir = {
        interval = 1000,
        follow_files = true,
    },
    attach_to_untracked = true,
    current_line_blame = false,
    current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "right_align",
        delay = 0,
        ignore_whitespace = false,
    },
    current_line_blame_formatter_opts = {
        relative_time = false,
    },
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil,
    max_file_length = 40000,
    preview_config = {
        border = "single",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
    },
    yadm = {
        enable = false,
    },
})

local nmap = require("utils").nmap
nmap { "gp", require("gitsigns").preview_hunk_inline }
nmap { "g.", require("gitsigns").toggle_signs }
nmap { "[g", require("gitsigns").prev_hunk }
nmap { "]g", require("gitsigns").next_hunk }
nmap { "g,", require("gitsigns").toggle_current_line_blame }
nmap { "gl", require("gitsigns").blame_line }
nmap { "<leader><bs>", require("gitsigns").reset_hunk }
