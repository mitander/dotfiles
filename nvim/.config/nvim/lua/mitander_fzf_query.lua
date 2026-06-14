local M = {}

function M.rg_glob(query, opts)
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

return M
