local function in_git_worktree()
    local result = vim.fn.system({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--is-inside-work-tree" })
    return vim.v.shell_error == 0 and vim.trim(result) == "true"
end

local function project_files()
    local opts = { no_resume = true }
    local fzf_lua = require("fzf-lua")
    if in_git_worktree() then
        fzf_lua.git_files(opts)
    else
        fzf_lua.files(opts)
    end
end

local function all_files()
    require("fzf-lua").files({
        no_resume = true,
        fd_opts = "--no-ignore --color=never --type f --hidden --follow --exclude .git",
        file_ignore_patterns = { ".git/" },
    })
end

local function smart_rg_glob(query, opts)
    local libuv = require("fzf-lua.libuv")
    local glob_flag = opts.glob_flag or "--glob"

    local function words(s)
        local items = {}
        for item in tostring(s or ""):gmatch("%S+") do
            items[#items + 1] = item
        end
        return items
    end

    local function trim(s)
        return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    end

    local function normalize_glob(glob)
        glob = trim(glob)
        if glob == "" then
            return nil
        end
        if glob:match("^%.[%w_%-]+$") then
            glob = "*" .. glob
        elseif glob:sub(-1) == "/" then
            glob = glob .. "**"
        end
        return glob
    end

    local function looks_like_glob(token)
        if token == "" or token == "*" or token == ".*" then
            return false
        end
        return token:find("/", 1, true) ~= nil
            or token:match("^%.[%w_%-]+$") ~= nil
            or (token:find("[%*%?%[]") ~= nil and token:find("%.") ~= nil)
    end

    local filters = {}
    local function add_filter(glob, exclude)
        glob = normalize_glob(glob)
        if not glob then
            return
        end
        if exclude and glob:sub(1, 1) ~= "!" then
            glob = "!" .. glob
        end
        filters[#filters + 1] = glob
    end

    local search, glob_part = query:match("^(.-)%s%-%-%s*(.*)$")
    if glob_part then
        search = trim(search)
        for _, token in ipairs(words(glob_part)) do
            local exclude = token:sub(1, 1) == "!"
            add_filter(exclude and token:sub(2) or token, exclude)
        end
    else
        local terms = {}
        for _, token in ipairs(words(query)) do
            local include = token:match("^in:(.+)$") or token:match("^include:(.+)$")
            local exclude = token:match("^out:(.+)$") or token:match("^exclude:(.+)$")
            if include then
                add_filter(include, false)
            elseif exclude then
                if exclude:sub(1, 1) == "!" then
                    exclude = exclude:sub(2)
                end
                add_filter(exclude, true)
            elseif token:sub(1, 1) == "!" and looks_like_glob(token:sub(2)) then
                add_filter(token:sub(2), true)
            elseif looks_like_glob(token) then
                add_filter(token, false)
            else
                terms[#terms + 1] = token
            end
        end
        search = #filters > 0 and table.concat(terms, " ") or query
    end

    if #filters == 0 then
        return query, nil
    end

    local args = {}
    for _, glob in ipairs(filters) do
        args[#args + 1] = string.format("%s %s", glob_flag, libuv.shellescape(glob))
    end
    return search, table.concat(args, " ")
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
        keymap = {
            fzf = {
                true,
                ["ctrl-c"] = "clear-query",
            },
        },
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
            glob_flag = "--glob",
            glob_separator = ".",
            rg_glob_fn = smart_rg_glob,
            rg_opts = "--hidden --column --line-number --no-heading"
                .. " --color=always --smart-case -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'",
        },
        live_grep = {
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
