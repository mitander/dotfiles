local M = {}
local originals
local families

-- Assign identities, not RGB thresholds or individual aliases. Every extension
-- sharing a DevIcon group must use the same family in Oil and fzf.
local file_families = {
    neutral = { "Default", "Lock", "Log", "Md", "Markdown", "Txt", "Makefile", "Ini" },
    red = { "Java", "Rb", "Rake", "Toml", "Yaml", "Yml", "Pdf" },
    orange = { "Rs", "Rlib", "Zig", "Html", "Htm", "Svelte", "Swift" },
    yellow = {
        "Py",
        "Pyi",
        "Pyc",
        "Pyd",
        "Pyo",
        "Pyw",
        "Pyx",
        "Pxd",
        "Pxi",
        "Js",
        "Mjs",
        "Cjs",
        "SpecJs",
        "TestJs",
        "Json",
        "Json5",
        "Jsonc",
        "Jsonl",
    },
    green = {
        "Vue",
        "Fish",
        "Sh",
        "Bash",
        "BashProfile",
        "Bashrc",
        "Zsh",
        "Zshprofile",
        "Zshenv",
        "Zshrc",
    },
    cyan = { "Go", "GoMod", "GoSum", "GoWork", "Jsx", "JavaScriptReactSpec", "JavaScriptReactTest" },
    blue = {
        "Lua",
        "Luau",
        "Ts",
        "Tsx",
        "Mts",
        "Cts",
        "SpecTs",
        "TestTs",
        "TypeScriptReactSpec",
        "TypeScriptReactTest",
        "Nix",
        "Css",
        "Sql",
    },
    purple = {
        "Ex",
        "Exs",
        "Eex",
        "Heex",
        "Leex",
        "Erl",
        "Hrl",
        "Hs",
        "Lhs",
        "Jpeg",
        "Jpg",
        "Png",
        "Webp",
    },
    pink = { "Gleam", "Sass", "Scss" },
}

local function family(color)
    if type(color) ~= "string" or not color:match("^#%x%x%x%x%x%x$") then
        return nil
    end
    local red = tonumber(color:sub(2, 3), 16)
    local green = tonumber(color:sub(4, 5), 16)
    local blue = tonumber(color:sub(6, 7), 16)
    local high, low = math.max(red, green, blue), math.min(red, green, blue)
    local delta = high - low
    if high == 0 or delta / high < 0.2 then
        return "neutral"
    end
    local hue
    if high == red then
        hue = ((green - blue) / delta) % 6
    elseif high == green then
        hue = (blue - red) / delta + 2
    else
        hue = (red - green) / delta + 4
    end
    hue = hue * 60
    if hue < 15 or hue >= 345 then
        return "red"
    elseif hue < 45 then
        return "orange"
    elseif hue < 75 then
        return "yellow"
    elseif hue < 165 then
        return "green"
    elseif hue < 200 then
        return "cyan"
    elseif hue < 255 then
        return "blue"
    elseif hue < 290 then
        return "purple"
    else
        return "pink"
    end
end

local function classify(icons)
    local keys, names, result = {}, {}, { [1] = "neutral" }
    for category, identities in pairs(file_families) do
        for _, name in ipairs(identities) do
            names[name] = category
        end
    end
    if icons[1] and icons[1].name then
        names[icons[1].name] = "neutral"
    end
    for key in pairs(icons) do
        if type(key) == "string" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local icon = icons[key]
        local category = names[icon.name] or family(icon.color)
        if icon.name and category then
            -- Aliases share a DevIcon highlight group. Choose one stable family
            -- for that identity so the RGB table and the highlight cannot disagree.
            names[icon.name] = names[icon.name] or category
            category = names[icon.name]
        end
        result[key] = category
    end
    return result
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
    -- Resolve explicit assignments and upstream fallbacks once. Reclassifying
    -- themed colors on each switch would gradually move icons between families.
    originals = originals or vim.deepcopy(provider.get_icons())
    families = families or classify(originals)
    local function update()
        local colors = palette()
        local icons = vim.deepcopy(originals)
        if colors then
            for key, icon in pairs(icons) do
                local category = families[key]
                if category then
                    icon.color = colors[category]
                end
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
