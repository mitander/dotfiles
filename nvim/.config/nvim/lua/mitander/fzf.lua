local function in_git_worktree()
    local result = vim.fn.system({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--is-inside-work-tree" })
    return vim.v.shell_error == 0 and vim.trim(result) == "true"
end

local function project_files()
    local fzf_lua = require("fzf-lua")
    if in_git_worktree() then
        fzf_lua.git_files()
    else
        fzf_lua.files()
    end
end

local function all_files()
    require("fzf-lua").files({
        fd_opts = "--no-ignore --color=never --type f --hidden --follow --exclude .git",
        file_ignore_patterns = { ".git/" },
    })
end

return {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    init = function()
        local select = vim.ui.select
        vim.ui.select = function(items, opts, on_choice)
            require("lazy").load({ plugins = { "fzf-lua" } })
            if vim.ui.select == select then
                select(items, opts, on_choice)
            else
                vim.ui.select(items, opts, on_choice)
            end
        end
    end,
    keys = {
        { "<c-p>", project_files, desc = "Find project files" },
        { "<leader>P", all_files, desc = "Find all files" },
        {
            "<c-f>",
            function()
                require("fzf-lua").live_grep()
            end,
            desc = "Live grep",
        },
        {
            "<c-b>",
            function()
                require("fzf-lua").buffers()
            end,
            desc = "Buffers",
        },
        {
            "<leader>h",
            function()
                require("fzf-lua").help_tags()
            end,
            desc = "Help tags",
        },
        {
            "<leader>gs",
            function()
                require("fzf-lua").git_status()
            end,
            desc = "Git status",
        },
        {
            "<leader>gl",
            function()
                require("fzf-lua").git_commits()
            end,
            desc = "Git commits",
        },
        {
            "<leader>gb",
            function()
                require("fzf-lua").git_branches()
            end,
            desc = "Git branches",
        },
        {
            "<leader>gc",
            function()
                require("fzf-lua").git_bcommits()
            end,
            desc = "Buffer commits",
        },
        {
            "<leader>p",
            function()
                require("fzf-lua").tmux_buffers()
            end,
            desc = "Tmux buffers",
        },
    },
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
            fd_opts = "--color=never --type f --hidden --follow --exclude .git",
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
        live_grep = {
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
        fzf_lua.setup(opts)

        if vim.ui then
            fzf_lua.register_ui_select({
                winopts = {
                    win_height = 0.30,
                    win_width = 0.70,
                    win_row = 0.40,
                },
            })
        end
    end,
}
