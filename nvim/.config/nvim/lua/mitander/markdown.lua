local M = {}
local limits = require("mitander.buffer_limits")
local namespace = vim.api.nvim_create_namespace("mitander_markdown")
local callouts = {
    NOTE = { "󰋽", "DiagnosticInfo" },
    TIP = { "󰌶", "DiagnosticOk" },
    IMPORTANT = { "󰅾", "Special" },
    WARNING = { "󰀪", "DiagnosticWarn" },
    CAUTION = { "󰳦", "DiagnosticWarn" },
    ERROR = { "󰅚", "DiagnosticWarn" },
}

local function highlights()
    local flume = package.loaded.flume
    local colors = type(flume) == "table" and flume.is_active() and flume.colors or nil
    local headings = colors
            and {
                colors.syntax_function,
                colors.syntax_keyword,
                colors.syntax_type,
                colors.syntax_function,
                colors.blue,
                colors.muted,
            }
        or {}
    for level = 1, 6 do
        vim.api.nvim_set_hl(0, "@markup.heading." .. level .. ".markdown", {
            fg = headings[level],
            bold = true,
            link = not colors and "Title" or nil,
        })
    end
    for name, config in pairs(callouts) do
        local foreground = colors
            and ({
                NOTE = colors.syntax_keyword,
                TIP = colors.green,
                IMPORTANT = colors.syntax_property,
                WARNING = colors.yellow,
                CAUTION = colors.yellow,
                ERROR = colors.yellow,
            })[name]
        vim.api.nvim_set_hl(0, "Markdown" .. name, {
            fg = foreground,
            bold = true,
            link = not colors and config[2] or nil,
        })
    end
    vim.api.nvim_set_hl(0, "@markup.link.url.markdown_inline", { link = "Comment" })
end

local function decorate_quote(buf, quote)
    local row, col = quote:range()
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    local name = line:sub(col + 1):match("^>%s*%[!([%a]+)%]")
    name = name and name:upper()
    if not callouts[name] then
        return
    end
    local highlight = "Markdown" .. name
    local marker = assert(line:find("%[![%a]+%]", col + 1)) - 1
    local label = callouts[name][1] .. " " .. name:sub(1, 1) .. name:sub(2):lower()
    -- Replace only the marker's screen cells. Keep the following text at exactly
    -- the same column, including on the cursor line and in Insert mode.
    label = label .. string.rep(" ", math.max(0, #name + 3 - vim.fn.strdisplaywidth(label)))
    vim.api.nvim_buf_set_extmark(buf, namespace, row, marker, {
        end_col = #line,
        hl_group = highlight,
        virt_text = { { label, highlight } },
        virt_text_pos = "overlay",
        hl_mode = "replace",
        priority = 150,
    })

    local level = 1
    local parent = quote:parent()
    while parent do
        if parent:type() == "block_quote" then
            level = level + 1
        end
        parent = parent:parent()
    end
    local function markers(node)
        local kind = node:type()
        if kind == "block_quote_marker" or kind == "block_continuation" then
            local text = vim.treesitter.get_node_text(node, buf)
            local index = 0
            for position in text:gmatch("()>") do
                index = index + 1
                if
                    (kind == "block_quote_marker" and node:parent() == quote)
                    or (kind == "block_continuation" and index == level)
                then
                    local marker_row, marker_col = node:range()
                    vim.api.nvim_buf_set_extmark(
                        buf,
                        namespace,
                        marker_row,
                        marker_col + position - 1,
                        {
                            virt_text = { { "│", highlight } },
                            virt_text_pos = "overlay",
                            hl_mode = "replace",
                            priority = 150,
                        }
                    )
                    break
                end
            end
        end
        for child in node:iter_children() do
            -- A nested quote has its own title, but its continuation prefixes
            -- can still contain the outer quote's marker.
            markers(child)
        end
    end
    markers(quote)
end

function M.refresh(buf)
    if not vim.api.nvim_buf_is_loaded(buf) then
        return
    end
    vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
    if
        vim.bo[buf].filetype ~= "markdown"
        or vim.b[buf].markdown_styling == false
        or limits.is_large(buf)
    then
        return
    end
    local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
    if not ok or not parser then
        return -- Plain syntax highlighting remains usable without a prepared parser.
    end
    local query = vim.treesitter.query.parse("markdown", "(block_quote) @quote")
    -- Parse only the Markdown tree. Callouts do not need injected language trees.
    for _, tree in ipairs(parser:parse(false) or {}) do
        for _, quote in query:iter_captures(tree:root(), buf) do
            decorate_quote(buf, quote)
        end
    end
end

function M.setup()
    highlights()
    local group = vim.api.nvim_create_augroup("mitander_markdown", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        group = group,
        callback = function(args)
            if vim.bo[args.buf].filetype == "markdown" then
                -- Native Treesitter queries also conceal code fences and URLs.
                -- Disable that in every window showing Markdown, not just at startup.
                for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
                    vim.wo[win].conceallevel = 0
                end
                M.refresh(args.buf)
            end
        end,
    })
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
        group = group,
        callback = function(args)
            if vim.bo[args.buf].filetype == "markdown" then
                M.refresh(args.buf)
            end
        end,
    })
    vim.api.nvim_create_user_command("MarkdownToggle", function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].filetype == "markdown" then
            vim.b[buf].markdown_styling = vim.b[buf].markdown_styling == false
            M.refresh(buf)
        end
    end, { desc = "Toggle Markdown callout styling (keep syntax highlighting)" })
    vim.keymap.set(
        "n",
        "<leader>vm",
        "<cmd>MarkdownToggle<cr>",
        { desc = "Toggle Markdown callout styling" }
    )
end

return M
