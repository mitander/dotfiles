local function picker()
    return require("fzf-lua")
end

local function project_files()
    local cwd = vim.fn.getcwd()
    local opts = { no_resume = true, previewer = false, cwd = cwd }
    if vim.fn.executable("git") ~= 1 then
        picker().files(opts)
        return
    end

    -- Let Git resolve worktrees and environment overrides without blocking the editor.
    vim.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { text = true }, function(result)
        vim.schedule(function()
            if result.code == 0 then
                opts.cwd = vim.trim(result.stdout)
            end
            picker().files(opts)
        end)
    end)
end

local fd_exists = vim.fn.executable("fd") == 1

local function all_files()
    picker().files({
        no_resume = true,
        previewer = false,
        cmd = fd_exists and "fd --no-ignore --color=never --type f --hidden --follow --exclude .git"
            or "rg --files --no-ignore --hidden -g '!.git'",
        file_ignore_patterns = { ".git/" },
    })
end

-- Picker layouts
local file_cmd = fd_exists and "fd --color=never --type f --hidden --follow --exclude .git" or nil

local file_picker_winopts = {
    height = 0.72,
    width = 0.82,
    row = 0.50,
    col = 0.50,
    title = " Files ",
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

-- Grep and live grep share query syntax, discovery rules and preview layout.
local grep_opts = {
    formatter = "path.filename_first",
    winopts = search_winopts,
    rg_glob = true,
    glob_flag = "--glob",
    -- Use fzf-lua's native `query -- glob` syntax.
    rg_opts = "--hidden --column --line-number --no-heading"
        .. " --color=always --smart-case -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'",
}

-- Plugin configuration
return {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    init = function()
        local select = vim.ui.select
        -- Restore the original selector before loading fzf-lua, which installs its own.
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.ui.select = function(items, opts, on_choice)
            vim.ui.select = select
            require("lazy").load({ plugins = { "fzf-lua" } })
            vim.ui.select(items, opts, on_choice)
        end
    end,
    keys = {
        { "<c-p>", project_files, desc = "Find project files" },
        { "<leader>P", all_files, desc = "Find all files" },
        {
            "<c-f>",
            function()
                picker().live_grep({ resume = true })
            end,
            desc = "Live grep session",
        },
        {
            "<c-b>",
            function()
                picker().buffers()
            end,
            desc = "Buffers",
        },
        {
            "<leader>h",
            function()
                picker().help_tags()
            end,
            desc = "Help tags",
        },

        {
            "<leader>gs",
            function()
                picker().git_status()
            end,
            desc = "Git status (modified files)",
        },
        {
            "<leader>gl",
            function()
                picker().git_commits()
            end,
            desc = "Git log",
        },
        {
            "<leader>gb",
            function()
                picker().git_branches()
            end,
            desc = "Git branches",
        },
        {
            "<leader>gc",
            function()
                picker().git_bcommits()
            end,
            desc = "Buffer commits",
        },
        {
            "<leader>p",
            function()
                picker().tmux_buffers()
            end,
            desc = "Tmux buffers",
        },
    },
    opts = {
        fzf_colors = { true },
        fzf_opts = { ["--no-bold"] = true },
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
            title_flags = false,
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
            previewer = false,
            cmd = file_cmd,
            -- Keep discovery in-process to avoid an empty picker when the Nix
            -- Neovim worker fails to load config ("config is nil").
            multiprocess = false,
            winopts = vim.deepcopy(file_picker_winopts),
        },
        grep = vim.deepcopy(grep_opts),
        live_grep = vim.deepcopy(grep_opts),
        git = {
            status = {
                prompt = "Review> ",
                cmd = "git -c color.status=false --no-optional-locks status --porcelain=v1 -uall",
                winopts = {
                    preview = { vertical = "down:70%", horizontal = "right:70%" },
                },
            },
            diff = {
                preview = "git diff --color {ref1} {ref} -- {file}",
            },
            hunks = {
                cmd = "git --no-pager diff --color=always {ref1} {ref} -- {file}",
            },
            commits = {
                winopts = { preview = { vertical = "down:60%" } },
            },
            bcommits = {
                winopts = { preview = { vertical = "down:60%" } },
            },
            branches = {
                winopts = {
                    preview = { vertical = "down:75%", horizontal = "right:75%" },
                },
            },
            files = {
                prompt = "Files: ",
                formatter = "path.filename_first",
                previewer = false,
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
