local M = {}
local originals
local family_by_name = {}

-- DevIcon identities can cover many filenames/extensions. Resolve them once,
-- independently of upstream hues and previously applied palette colors.
for family, names in pairs(require("mitander.icon_families")) do
    for _, name in ipairs(names) do
        assert(not family_by_name[name], "duplicate icon identity: " .. name)
        family_by_name[name] = family
    end
end

local function palette()
    local flume = package.loaded.flume
    if type(flume) ~= "table" or not flume.is_active() then
        return nil
    end
    local colors = flume.colors
    return {
        neutral = colors.icon_neutral,
        red = colors.icon_red,
        copper = colors.icon_copper,
        orange = colors.icon_orange,
        yellow = colors.icon_yellow,
        green = colors.icon_green,
        cyan = colors.icon_cyan,
        blue = colors.icon_blue,
        purple = colors.icon_purple,
        pink = colors.icon_pink,
    }
end

function M.setup(provider)
    originals = originals or vim.deepcopy(provider.get_icons())
    local function update()
        local colors = palette()
        local icons = vim.deepcopy(originals)
        if colors then
            for _, icon in pairs(icons) do
                -- A new upstream format is quiet until its identity is reviewed.
                -- RGB guessing split aliases such as ts/d.ts and py/py.typed.
                icon.color = colors[family_by_name[icon.name] or "neutral"]
            end
        end
        -- Update provider data as well as highlights: fzf-lua serializes the
        -- RGB table directly. Keep upstream cterm colors as the fallback.
        provider.set_icon(icons)
        local default = icons[1]
        if default then
            provider.set_default_icon(default.icon, default.color, default.cterm_color)
        end
        local fzf = package.loaded["fzf-lua.devicons"]
        if type(fzf) == "table" then
            -- Background-only invalidation misses Dusk/Mira and Opal/Mesa
            -- switches. Rebuild the exported cache on the next picker load.
            fzf.set_state("devicons", nil)
        end
    end
    local group = vim.api.nvim_create_augroup("mitander_icon_colors", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = update })
    update()
end

return M
