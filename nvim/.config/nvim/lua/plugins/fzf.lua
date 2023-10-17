local ok, fzf_lua = pcall(require, "fzf-lua")
if not ok then
    return
end

fzf_lua.setup {
    winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.55,
        preview = {
            layout = "flex",
            flip_columns = 130,
            scrollbar = "float",
        },
    },
    previewers = {
        bat = { theme = "base16" },
        builtin = {
            ueberzug_scaler = "cover",
            extensions      = {
                ["gif"]  = { "chafa" },
                ["png"]  = { "chafa" },
                ["jpg"]  = { "chafa" },
                ["jpeg"] = { "chafa" },
                ["svg"]  = { "chafa" },
            }
        },
    },
    files = {
        fd_opts = "--no-ignore --color=never --type f --hidden --follow  --exclude .git",
        action = { ["ctrl-l"] = fzf_lua.actions.arg_add },
        cwd = vim.fn.getcwd()
    },
    grep = {
        rg_glob = true,
        rg_opts = "--hidden --column --line-number --no-heading"
            .. " --color=always --smart-case -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'",
    },
    git = {
        status = {
            cmd = "git status -su",
            winopts = {
                preview = { vertical = "down:70%", horizontal = "right:70%" },
            },
            actions = {
                ["ctrl-x"] = { fzf_lua.actions.git_reset, fzf_lua.actions.resume },
            },
            preview_pager = vim.fn.executable "delta" == 1 and "delta --width=$COLUMNS",
        },
        commits = {
            winopts = { preview = { vertical = "down:60%" } },
            preview_pager = vim.fn.executable "delta" == 1 and "delta --width=$COLUMNS",
        },
        bcommits = {
            winopts = { preview = { vertical = "down:60%" } },
            preview_pager = vim.fn.executable "delta" == 1 and "delta --width=$COLUMNS",
        },
        branches = {
            winopts = {
                preview = { vertical = "down:75%", horizontal = "right:75%" },
            },
        },
        files = {
            cmd = "git ls-files -o -c --exclude-standard | grep -vE \"^$(git ls-files -d | paste -sd \"|\" -)$\"",
        },
    },
    diagnostics = { icon_padding = " " },
    file_ignore_patterns = {
        "ttf",
        "otf",
        "vendor",
        ".vscode",
        ".gitlab/",
        "*cache*",
        ".git/",
    },
}

if vim.ui then
    fzf_lua.register_ui_select {
        winopts = {
            win_height = 0.30,
            win_width = 0.70,
            win_row = 0.40,
        },
    }
end

local utils = require("utils")
local nmap = utils.nmap
local nmap_cmd = utils.nmap_cmd

vim.cmd [[command! Files exec (len(system('git rev-parse'))) ? ':FzfLua files' : ':FzfLua git_files']]
nmap_cmd { "<c-p>", "Files" }
nmap { "<c-f>", require("fzf-lua").grep_project }
nmap { "<c-b>", require("fzf-lua").buffers }
nmap { "<leader>h", require("fzf-lua").help_tags }
nmap { "<leader>gs", require("fzf-lua").git_status }
nmap { "<leader>gl", require("fzf-lua").git_commits }
nmap { "<leader>gb", require("fzf-lua").git_branches }
nmap { "<leader>gc", require("fzf-lua").git_bcommits }
nmap { "<leader>p", require("fzf-lua").tmux_buffers }
