local function git_root()
    if vim.fn.executable("git") ~= 1 then
        return nil
    end
    local result = vim.fn.system({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
    if vim.v.shell_error == 0 then
        return vim.trim(result)
    end
    return nil
end

local function project_files()
    require("fzf-lua").files({
        no_resume = true,
        previewer = false,
        cwd = git_root() or vim.fn.getcwd(),
    })
end

local fd_exists = vim.fn.executable("fd") == 1

local function all_files()
    require("fzf-lua").files({
        no_resume = true,
        previewer = false,
        fd_opts = fd_exists and "--no-ignore --color=never --type f --hidden --follow --exclude .git" or nil,
        file_ignore_patterns = { ".git/" },
    })
end

local function smart_rg_glob(query, opts)
    local function stringify(value)
        if type(value) == "table" then
            local items = {}
            for i, item in ipairs(value) do
                items[i] = tostring(item)
            end
            return table.concat(items, " ")
        end
        return tostring(value or "")
    end

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

    local function has_glob_magic(s)
        return s:find("[%*%?%[]") ~= nil
    end

    local function has_path_separator(s)
        return s:find("/", 1, true) ~= nil
    end

    local function looks_like_extension(s)
        return s:match("^%.[%w_%-]+$") ~= nil
    end

    local function looks_like_file_path(s)
        return s:match("[^/]+%.[^/]+$") ~= nil
    end

    local function looks_like_path_filter(token)
        if token == "" or token == "*" or token == ".*" then
            return false
        end
        return has_path_separator(token) or looks_like_extension(token) or has_glob_magic(token)
    end

    local function normalize_glob(glob, mode)
        glob = trim(glob)
        if glob == "" then
            return nil
        end

        if mode == "bare_exclude" then
            if not has_glob_magic(glob) and not has_path_separator(glob) and not looks_like_extension(glob) then
                return "*" .. glob .. "*"
            end
        end

        if looks_like_extension(glob) then
            return "*" .. glob
        end

        if glob:sub(-1) == "/" then
            return glob .. "**"
        end

        if has_path_separator(glob) and not has_glob_magic(glob) and not looks_like_file_path(glob) then
            return glob .. "/**"
        end

        return glob
    end

    local function rg_regex_escape(s)
        return (s:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%{}|\\])", "\\%1"))
    end

    local function smart_term_regex(term)
        if term:match("^re:") then
            return term:sub(4)
        end

        local parts = {}
        for part in term:gmatch("[^_%-%s%.:/]+") do
            parts[#parts + 1] = rg_regex_escape(part)
        end

        if #parts > 1 then
            return table.concat(parts, "[-_./:[:space:]]*")
        end

        return rg_regex_escape(term)
    end

    local function build_search(terms)
        local regex_terms = {}
        for _, term in ipairs(terms) do
            if term ~= "" then
                regex_terms[#regex_terms + 1] = smart_term_regex(term)
            end
        end
        return table.concat(regex_terms, ".*")
    end

    query = stringify(query)
    opts = opts or {}

    -- fzf-lua calls rg_glob_fn again from the preview highlighter. If the query
    -- is already the regex we generated, don't try to parse it as user syntax.
    if query:find("[-_./:[:space:]]*", 1, true) then
        return query, nil
    end

    local libuv = require("fzf-lua.libuv")
    local glob_flag = opts.glob_flag or "--glob"
    local filters = {}
    local terms = {}
    local used_smart_syntax = false

    local function add_filter(glob, exclude, mode)
        glob = normalize_glob(glob, mode)
        if not glob then
            return
        end
        if exclude and glob:sub(1, 1) ~= "!" then
            glob = "!" .. glob
        end
        filters[#filters + 1] = glob
        used_smart_syntax = true
    end

    local function add_term(token)
        if token:sub(1, 2) == [[\!]] then
            terms[#terms + 1] = "!" .. token:sub(3)
        elseif token:sub(1, 2) == "!!" then
            terms[#terms + 1] = "!" .. token:sub(3)
        elseif token:sub(1, 1) == '"' and token:sub(-1) == '"' then
            terms[#terms + 1] = token:sub(2, -2)
        else
            terms[#terms + 1] = token
        end
    end

    local search, glob_part = query:match("^(.-)%s%-%-%s*(.*)$")
    if glob_part then
        for _, token in ipairs(words(search)) do
            add_term(token)
        end
        for _, token in ipairs(words(glob_part)) do
            local exclude = token:sub(1, 1) == "!"
            add_filter(exclude and token:sub(2) or token, exclude)
        end
    else
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
            elseif token:sub(1, 2) == [[\!]] or token:sub(1, 2) == "!!" then
                add_term(token)
            elseif token:sub(1, 1) == "!" then
                add_filter(token:sub(2), true, looks_like_path_filter(token:sub(2)) and nil or "bare_exclude")
            elseif looks_like_path_filter(token) then
                add_filter(token, false)
            else
                add_term(token)
            end
        end
    end

    if not used_smart_syntax then
        return query, nil
    end

    local args = {}
    for _, glob in ipairs(filters) do
        args[#args + 1] = string.format("%s %s", glob_flag, libuv.shellescape(glob))
    end

    -- We build a small regex for fuzzy-ish word/separator matching, so prevent
    -- fzf-lua from escaping it back into a literal string.
    opts.no_esc = true
    return build_search(terms), table.concat(args, " ")
end
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

return {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    init = function()
        local select = vim.ui.select
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
            "<leader>gl",
            function()
                require("fzf-lua").git_commits()
            end,
            desc = "Git log",
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
            "<leader>gh",
            function()
                require("fzf-lua").git_bcommits()
            end,
            desc = "Current file history",
        },
        {
            "<leader>gH",
            function()
                require("fzf-lua").git_commits()
            end,
            desc = "Repo history",
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
                prompt = "Review> ",
                cmd = "git -c color.status=false --no-optional-locks status --porcelain=v1 -uall",
                winopts = {
                    preview = { vertical = "down:70%", horizontal = "right:70%" },
                },
                preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
            },
            diff = {
                preview = "git diff --color {ref1} {ref} -- {file}",
                preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
            },
            hunks = {
                cmd = "git --no-pager diff --color=always {ref1} {ref} -- {file}",
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
