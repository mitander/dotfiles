-- Source: nvim --clean --headless -l tests/nvim-markdown.lua
-- Native: append the prepared nvim/site directory containing Markdown parsers.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root .. "/nvim/.config/nvim")
if arg[1] then
    assert(
        vim.fn.filereadable(arg[1] .. "/parser/markdown.so") == 1,
        "prepare the Markdown parser first"
    )
    vim.opt.rtp:prepend(arg[1])
end
local markdown = require("mitander.markdown")
local namespace = vim.api.nvim_get_namespaces().mitander_markdown
local colors = {
    syntax_property = "#cc8796",
    syntax_function = "#73a6b6",
    syntax_type = "#cfb584",
    syntax_keyword = "#b391d6",
    blue = "#6fa8dc",
    muted = "#9498a5",
    green = "#a4b78a",
    yellow = "#dfb86b",
}
package.loaded.flume = {
    is_active = function()
        return true
    end,
    colors = colors,
}
markdown.setup()
local buf = vim.api.nvim_get_current_buf()
local lines = {
    "# Heading",
    "",
    "> [!WARNING] Keep backups",
    "> body [link](docs/TESTING.md)",
    ">",
    "> > [!NOTE] Nested",
    "> > nested body",
    "",
    "```markdown",
    "> [!WARNING] Not a callout",
    "```",
    "",
    "    > [!WARNING] Indented code",
    "",
    "> [!UNKNOWN] Plain quote",
    "",
    "> [!IMPORTANT] Pink",
    "> important body",
    "",
    "> [!TIP] Green",
    "> tip body",
    "",
    "> [!CAUTION] Amber",
    "> caution body",
    "",
    "> [!ERROR] Amber error",
    "> error body",
}
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.bo[buf].filetype = "markdown"
vim.wo.conceallevel = 2
vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = buf })
assert(vim.wo.conceallevel == 0, "native queries must not conceal fences or links")
local function marks()
    return vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })
end
local function foreground(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
end
assert(foreground("@markup.heading.1.markdown") == 0x73a6b6, "H1 must use Flume teal")
assert(foreground("@markup.heading.2.markdown") == 0xb391d6, "H2 must use Flume purple")
assert(foreground("MarkdownNOTE") == 0xb391d6)
assert(foreground("MarkdownWARNING") == 0xdfb86b)
assert(foreground("MarkdownCAUTION") == 0xdfb86b)
assert(foreground("MarkdownERROR") == 0xdfb86b)
assert(foreground("MarkdownIMPORTANT") == 0xcc8796)
colors.syntax_property = "#994466"
colors.syntax_function = "#447788"
vim.api.nvim_exec_autocmds("ColorScheme", {})
assert(foreground("@markup.heading.1.markdown") == 0x447788, "theme switches must refresh teal")
assert(foreground("MarkdownIMPORTANT") == 0x994466)

if not arg[1] then
    local get_parser = vim.treesitter.get_parser
    vim.treesitter.get_parser = function()
        return nil
    end
    markdown.refresh(buf)
    assert(#marks() == 0, "missing parsers must leave plain Markdown usable")
    vim.cmd.MarkdownToggle()
    assert(vim.b[buf].markdown_styling == false)
    vim.cmd.MarkdownToggle()
    assert(vim.b[buf].markdown_styling == true)
    vim.treesitter.get_parser = get_parser
else
    assert(pcall(vim.treesitter.start, buf, "markdown"), "prepare the Markdown parser first")
    markdown.refresh(buf)
    local initial = marks()
    local titles, bars = {}, {}
    local labels = {
        MarkdownNOTE = "󰋽 Note",
        MarkdownTIP = "󰌶 Tip",
        MarkdownIMPORTANT = "󰅾 Important",
        MarkdownWARNING = "󰀪 Warning",
        MarkdownCAUTION = "󰳦 Caution",
        MarkdownERROR = "󰅚 Error",
    }
    for _, mark in ipairs(initial) do
        local row, col, opts = mark[2], mark[3], mark[4]
        assert(not opts.conceal and not opts.conceal_lines and not opts.virt_lines)
        assert(opts.virt_text_pos == "overlay")
        if opts.virt_text[1][1] == "│" then
            bars[row .. ":" .. col] = opts.virt_text[1]
        else
            titles[row] = opts.hl_group
            local raw = lines[row + 1]:match("%[![%a]+%]")
            assert(
                vim.fn.strdisplaywidth(opts.virt_text[1][1]) == #raw,
                "label must preserve columns"
            )
            assert(
                vim.trim(opts.virt_text[1][1]) == labels[opts.hl_group],
                "wrong callout icon/title"
            )
        end
    end
    assert(
        vim.deep_equal(titles, {
            [2] = "MarkdownWARNING",
            [5] = "MarkdownNOTE",
            [16] = "MarkdownIMPORTANT",
            [19] = "MarkdownTIP",
            [22] = "MarkdownCAUTION",
            [25] = "MarkdownERROR",
        }),
        vim.inspect(titles)
    )
    assert(vim.deep_equal(bars["2:0"], { "│", "MarkdownWARNING" }))
    assert(vim.deep_equal(bars["3:0"], { "│", "MarkdownWARNING" }))
    assert(vim.deep_equal(bars["5:2"], { "│", "MarkdownNOTE" }))
    assert(vim.deep_equal(bars["6:2"], { "│", "MarkdownNOTE" }))

    -- Moving and scrolling must neither parse nor regenerate decorations.
    local get_parser = vim.treesitter.get_parser
    vim.treesitter.get_parser = function()
        error("navigation must not parse Markdown")
    end
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    for row = 2, #lines do
        vim.cmd.normal({ "j", bang = true })
        assert(vim.api.nvim_win_get_cursor(0)[1] == row, "j must advance one source row")
    end
    for row = #lines - 1, 1, -1 do
        vim.cmd.normal({ "k", bang = true })
        assert(vim.api.nvim_win_get_cursor(0)[1] == row, "k must retreat one source row")
    end
    for _, event in ipairs({ "CursorMoved", "WinScrolled", "ModeChanged" }) do
        vim.api.nvim_exec_autocmds(event, {})
    end
    assert(vim.deep_equal(initial, marks()), "navigation must leave extmarks untouched")
    vim.treesitter.get_parser = get_parser

    vim.cmd.MarkdownToggle()
    assert(#marks() == 0)
    vim.cmd.MarkdownToggle()
    assert(#marks() == #initial)
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), lines))
    vim.api.nvim_buf_set_lines(buf, 2, 3, false, { "> Ordinary quote now" })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
    for _, mark in ipairs(marks()) do
        assert(mark[4].hl_group ~= "MarkdownWARNING", "edited callout left stale title")
        if mark[4].virt_text then
            assert(mark[4].virt_text[1][2] ~= "MarkdownWARNING", "edited callout left stale bars")
        end
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { string.rep("x", 102401) })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
    assert(#marks() == 0, "growing past the size budget must clear decorations")
    vim.api.nvim_buf_delete(buf, { force = true })
end
print(
    "PASS: stable Markdown source, callout styling and Flume heading colors"
        .. (arg[1] and " (native parsers)" or " (source)")
)
vim.cmd("qa!")
