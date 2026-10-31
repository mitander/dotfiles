-- Run with: scripts/check fzf
-- Requires installed plugins and the linked Flume checkout. No picker is opened.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugins = vim.fn.stdpath("data") .. "/lazy"
vim.opt.runtimepath:prepend(root .. "/nvim/.config/nvim")
vim.opt.runtimepath:prepend(root .. "/themes/flume")
for _, plugin in ipairs({ "nvim-web-devicons", "fzf-lua", "oil.nvim" }) do
    assert(vim.fn.isdirectory(plugins .. "/" .. plugin) == 1, "install " .. plugin .. " separately")
    vim.opt.runtimepath:append(plugins .. "/" .. plugin)
end

local spec = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/devicons.lua")
local provider = require("nvim-web-devicons")
assert(not provider.has_loaded(), "icon options must apply before the first setup")
spec.config(nil, spec.opts)
local originals = vim.deepcopy(provider.get_icons())
local picker_spec = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/fzf.lua")
picker_spec.config(nil, picker_spec.opts)
local devicons = require("fzf-lua.devicons")
local config = require("fzf-lua.config")
local make_entry = require("fzf-lua.make_entry")
local flume = require("flume")
local oil_columns = require("oil.columns")
local oil_constants = require("oil.constants")
local samples = {
    { file = "example.md", extension = "md", family = "icon_neutral", ansi = 253 },
    { file = "example.yaml", extension = "yaml", family = "icon_red", ansi = 160 },
    { file = "example.toml", extension = "toml", family = "icon_red", ansi = 124 },
    { file = "example.rs", extension = "rs", family = "icon_orange", ansi = 216 },
    { file = "example.py", extension = "py", family = "icon_yellow", ansi = 214 },
    { file = "example.pyi", extension = "pyi", family = "icon_yellow", ansi = 214 },
    { file = "example.pyw", extension = "pyw", family = "icon_yellow", ansi = 39 },
    { file = "example.js", extension = "js", family = "icon_yellow", ansi = 185 },
    { file = "example.json", extension = "json", family = "icon_yellow", ansi = 185 },
    { file = "example.fish", extension = "fish", family = "icon_green", ansi = 240 },
    { file = "example.go", extension = "go", family = "icon_cyan", ansi = 38 },
    { file = "example.lua", extension = "lua", family = "icon_blue", ansi = 74 },
    { file = "example.luac", extension = "luac", family = "icon_blue", ansi = 74 },
    { file = "example.tsx", extension = "tsx", family = "icon_blue", ansi = 26 },
    { file = "example.ex", extension = "ex", family = "icon_purple", ansi = 140 },
    { file = "example.png", extension = "png", family = "icon_purple", ansi = 140 },
    { file = "example.gleam", extension = "gleam", family = "icon_pink", ansi = 219 },
}

local function luminance(color)
    local result = 0
    for index, weight in ipairs({ 0.2126, 0.7152, 0.0722 }) do
        local channel = tonumber(color:sub(index * 2, index * 2 + 1), 16) / 255
        local linear = channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4
        result = result + weight * linear
    end
    return result
end

local function contrast(first, second)
    local a, b = luminance(first), luminance(second)
    return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
end

assert(devicons.load({ plugin = "devicons" }))
for _, truecolor in ipairs({ true, false, true }) do
    vim.o.termguicolors = truecolor
    -- Include same-background and repeated-schema transitions, not just dark/light.
    for _, schema in ipairs({ "dusk", "mira", "mira", "opal", "mesa", "opal", "dusk" }) do
        flume.setup({ schema = schema, watch_sync = false, follow_sync = false, dev = false })
        assert(devicons.state("devicons") == nil, "ColorScheme must invalidate fzf icon data")
        assert(devicons.load({ plugin = "devicons" }))
        local colors = flume.colors
        local themed = provider.get_icons()
        local allowed = {}
        for _, role in ipairs({
            "icon_neutral",
            "icon_red",
            "icon_orange",
            "icon_yellow",
            "icon_green",
            "icon_cyan",
            "icon_blue",
            "icon_purple",
            "icon_pink",
        }) do
            allowed[colors[role]] = true
        end
        for key, original in pairs(originals) do
            local icon = themed[key]
            assert(
                icon.icon == original.icon and icon.name == original.name,
                "icon identity changed"
            )
            assert(icon.cterm_color == original.cterm_color, "upstream terminal fallback changed")
            assert(allowed[icon.color], "icon did not receive a palette color: " .. tostring(key))
            if icon.name then
                local highlight =
                    vim.api.nvim_get_hl(0, { name = "DevIcon" .. icon.name, link = false })
                assert(
                    highlight.fg == tonumber(icon.color:sub(2), 16),
                    "icon data/highlight mismatch: " .. key
                )
            end
            assert(contrast(icon.color, colors.bg) >= 3, "icon is faint on the canvas")
            assert(
                contrast(icon.color, colors.element_active) >= 3,
                "icon is faint on selected rows"
            )
        end
        local opts = config.normalize_opts({}, "files")
        assert(opts.file_icons and opts.color_icons, "file picker must retain colored icons")
        for _, sample in ipairs(samples) do
            local expected = colors[sample.family]
            local provider_icon, provider_color =
                provider.get_icon_color(sample.file, sample.extension)
            assert(provider_icon == originals[sample.extension].icon)
            assert(provider_color == expected, "provider highlight does not match its themed data")
            local oil_entry = {
                [oil_constants.FIELD_TYPE] = "file",
                [oil_constants.FIELD_NAME] = sample.file,
            }
            local chunk = oil_columns.render_col({}, { "icon", add_padding = false }, oil_entry, 0)
            assert(chunk[1] == provider_icon, "Oil changed the file-type glyph")
            local oil_highlight = vim.api.nvim_get_hl(0, { name = chunk[2], link = false })
            assert(
                oil_highlight.fg == tonumber(expected:sub(2), 16),
                "Oil icon has a different family"
            )
            local icon, color = devicons.get_devicon(sample.file)
            assert(icon == provider_icon, "fzf changed the file-type glyph")
            assert(color == (truecolor and expected or tostring(sample.ansi)), sample.file)
            local prefix
            if truecolor then
                prefix = string.format(
                    "\27[38;2;%d;%d;%dm",
                    tonumber(expected:sub(2, 3), 16),
                    tonumber(expected:sub(4, 5), 16),
                    tonumber(expected:sub(6, 7), 16)
                )
            else
                prefix = string.format("\27[38;5;%dm", sample.ansi)
            end
            local entry = assert(make_entry.file(sample.file, opts))
            assert(entry:find(prefix .. icon, 1, true), "fzf did not emit the themed icon color")
        end
    end
end

-- Reconfiguration must retain the original brand classification rather than
-- classifying already-themed colors again.
spec.config(nil, spec.opts)
assert(provider.get_icons().gleam.color == flume.colors.icon_pink)
vim.g.colors_name = "other-test-theme"
vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "other-test-theme", modeline = false })
assert(
    vim.deep_equal(provider.get_icons(), originals),
    "another theme retained stale Flume icon colors"
)
assert(devicons.load({ plugin = "devicons" }))
local _, restored = devicons.get_devicon("example.gleam")
assert(restored == "#FFAFF3", "another theme lost the upstream fallback")
-- Syntax/ANSI overrides must not leak into icons. Icon-role overrides still apply.
flume.setup({
    schema = "opal",
    watch_sync = false,
    follow_sync = false,
    dev = false,
    overrides = { syntax_boolean = "#0000ff", bright_yellow = "#ff0000", icon_yellow = "#806b10" },
})
assert(provider.get_icons().py.color == "#806b10", "icon override was ignored")
assert(
    provider.get_icons().rs.color == flume.colors.icon_orange,
    "syntax override changed Rust icons"
)

-- Explicit identities must win even when upstream colors move to another hue.
-- This independent adapter instance also exercises default and unknown-format fallbacks.
flume.setup({ schema = "opal", watch_sync = false, follow_sync = false, dev = false })
local fixture_icons = {
    [1] = { icon = "?", name = "Default", color = "#ff0000" },
    py = { icon = "p", name = "Py", color = "#0000ff" },
    python_alias = { icon = "p", name = "Py", color = "#ff0000" },
    unknown = { icon = "u", name = "FutureFormat", color = "#00ff00" },
}
local fixture_provider = {
    get_icons = function()
        return fixture_icons
    end,
    set_icon = function(icons)
        fixture_icons = icons
    end,
    set_default_icon = function(_, color)
        assert(color == flume.colors.icon_neutral)
    end,
}
local adapter = dofile(root .. "/nvim/.config/nvim/lua/mitander/icon_colors.lua")
adapter.setup(fixture_provider)
assert(fixture_icons.py.color == flume.colors.icon_yellow, "upstream hue overrode Python policy")
assert(fixture_icons.python_alias.color == fixture_icons.py.color, "aliases disagree")
assert(fixture_icons.unknown.color == flume.colors.icon_green, "new formats lost the hue fallback")
print(
    "PASS: explicit file families, contrast, Oil columns, fzf RGB/256-color entries and schema-switch caches"
)
vim.cmd("qa!")
