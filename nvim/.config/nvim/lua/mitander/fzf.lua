local function git_root()
    local result = vim.fn.system({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
    if vim.v.shell_error == 0 then
        return vim.trim(result)
    end
end

local function project_files()
    require("fzf-lua").files({
        no_resume = true,
        cwd = git_root() or vim.fn.getcwd(),
    })
end

local function all_files()
    require("fzf-lua").files({
        no_resume = true,
        fd_opts = "--no-ignore --color=never --type f --hidden --follow --exclude .git",
        file_ignore_patterns = { ".git/" },
    })
end

local smart_rg_glob = require("mitander_fzf_query").rg_glob
local fd = vim.fn.exepath("fd") ~= "" and vim.fn.exepath("fd") or "fd"

local file_picker_winopts = {
    height = 0.72,
    width = 0.82,
    row = 0.50,
    col = 0.50,
    title = " Files · F4 preview ",
    preview = {
        hidden = "hidden",
        layout = "flex",
        flip_columns = 140,
        horizontal = "right:55%",
        vertical = "down:45%",
        scrollbar = "float",
    },
}

local search_winopts = {
    height = 0.88,
    width = 0.92,
    row = 0.50,
    col = 0.50,
    title = [[ Search ]],
    preview = {
        layout = "flex",
        flip_columns = 140,
        horizontal = "right:58%",
        vertical = "down:50%",
        scrollbar = "float",
    },
}

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
                require("fzf-lua").live_grep({ resume = true })
            end,
            desc = "Live grep session",
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
            "<leader>gS",
            function()
                require("fzf-lua").git_status()
            end,
            desc = "Git status picker",
        },
        {
            "<leader>gL",
            function()
                require("fzf-lua").git_commits()
            end,
            desc = "Git commits picker",
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
        keymap = {
            fzf = {
                true,
                ["ctrl-c"] = "clear-query",
                ["ctrl-w"] = "abort",
            },
        },
        hls = {
            backdrop = "Normal",
            border = "FloatBorder",
            preview_title = "Directory",
            preview_border = "FloatBorder",
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
            prompt = "Files: ",
            formatter = "path.filename_first",
            cmd = fd .. " --color=never --type f --hidden --follow --exclude .git",
            multiprocess = false,
            winopts = vim.deepcopy(file_picker_winopts),
        },
        grep = {
            formatter = "path.filename_first",
            winopts = vim.deepcopy(search_winopts),
            rg_glob = true,
            glob_flag = "--glob",
            glob_separator = ".",
            rg_glob_fn = smart_rg_glob,
            rg_opts = "--hidden --column --line-number --no-heading"
                .. " --color=always --smart-case -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'",
        },
        live_grep = {
            formatter = "path.filename_first",
            winopts = vim.deepcopy(search_winopts),
            rg_glob = true,
            glob_flag = "--glob",
            glob_separator = ".",
            rg_glob_fn = smart_rg_glob,
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
                prompt = "Files: ",
                formatter = "path.filename_first",
                cmd = "git ls-files --exclude-standard",
                multiprocess = false,
                winopts = vim.deepcopy(file_picker_winopts),
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
