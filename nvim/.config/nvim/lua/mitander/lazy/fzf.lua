return {
    "ibhagwan/fzf-lua",
    lazy = false,
    config = function()
        local fzf_lua = require("fzf-lua")

        vim.cmd [[hi FzfLuaBorder guifg=#363646]]
        vim.cmd [[hi FzfLuaTitle guifg=#dcd7ba]]

        fzf_lua.setup {
            {
                "default-title"
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
                    winopts = {
                        preview = {
                            hidden = "hidden",
                        },
                        height = 0.25,
                        width = 1,
                        col = 0,
                        row = 100,
                    }
                }
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

        -- TODO:
        vim.keymap.set("n", "<c-p>",
            "<cmd> exec (len(system('git rev-parse'))) ? ':FzfLua files' : ':FzfLua git_files'<cr>")
        vim.keymap.set("n", "<c-f>", require("fzf-lua").grep_project)
        vim.keymap.set("n", "<c-b>", require("fzf-lua").buffers)
        vim.keymap.set("n", "<leader>h", require("fzf-lua").help_tags)
        vim.keymap.set("n", "<leader>gs", require("fzf-lua").git_status)
        vim.keymap.set("n", "<leader>gl", require("fzf-lua").git_commits)
        vim.keymap.set("n", "<leader>gb", require("fzf-lua").git_branches)
        vim.keymap.set("n", "<leader>gc", require("fzf-lua").git_bcommits)
        vim.keymap.set("n", "<leader>p", require("fzf-lua").tmux_buffers)

        vim.cmd [[
         autocmd! FileType fzf set noshowmode
      \| autocmd BufLeave <buffer> set showmode
        ]]
    end,
}
