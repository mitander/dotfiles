return {
    "ibhagwan/fzf-lua",
    opts = {
        hls = {
            backdrop = "Normal",
            border = "WinSeparator",
            preview_title = "Directory",
            preview_border = "WinSeparator",
        },
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
                extensions = {
                    ["gif"] = { "chafa" },
                    ["png"] = { "chafa" },
                    ["jpg"] = { "chafa" },
                    ["jpeg"] = { "chafa" },
                    ["svg"] = { "chafa" },
                },
            },
        },
        files = {
            fd_opts = "--no-ignore --color=never --type f --hidden --follow  --exclude .git",
            cwd = vim.fn.getcwd(),
            winopts = {
                preview = {
                    hidden = "hidden",
                },
                height = 0.25,
                width = 1,
                col = 0,
                row = 100,
            },
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
                preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
            },
            commits = {
                winopts = { preview = { vertical = "down:60%" } },
                preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
            },
            bcommits = {
                winopts = { preview = { vertical = "down:60%" } },
                preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
            },
            branches = {
                winopts = {
                    preview = { vertical = "down:75%", horizontal = "right:75%" },
                },
            },
            files = {
                cmd = 'git ls-files -o -c --exclude-standard | grep -vE "^$(git ls-files -d | paste -sd "|" -)$"',
                winopts = {
                    preview = {
                        hidden = "hidden",
                    },
                    height = 0.25,
                    width = 1,
                    col = 0,
                    row = 100,
                },
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
    },

    config = function(_, opts)
        local fzf_lua = require("fzf-lua")
        if vim.ui then
            fzf_lua.register_ui_select({
                winopts = {
                    win_height = 0.30,
                    win_width = 0.70,
                    win_row = 0.40,
                },
            })
        end

        local in_git = vim.fn.systemlist("git rev-parse --is-inside-work-tree")[1] == "true"
        vim.keymap.set("n", "<c-p>", in_git and fzf_lua.git_files or fzf_lua.files)
        vim.keymap.set("n", "<c-f>", fzf_lua.grep_project)
        vim.keymap.set("n", "<c-b>", fzf_lua.buffers)
        vim.keymap.set("n", "<leader>h", fzf_lua.help_tags)
        vim.keymap.set("n", "<leader>gs", fzf_lua.git_status)
        vim.keymap.set("n", "<leader>gl", fzf_lua.git_commits)
        vim.keymap.set("n", "<leader>gb", fzf_lua.git_branches)
        vim.keymap.set("n", "<leader>gc", fzf_lua.git_bcommits)
        vim.keymap.set("n", "<leader>p", fzf_lua.tmux_buffers)

        fzf_lua.setup(opts)
    end,
}
