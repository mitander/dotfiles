-- Run with: nvim --clean --headless -l tests/nvim-luals.lua
-- Requires an installed LuaLS. All generated config, metadata and logs stay temporary.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config_dir = root .. "/nvim/.config/nvim"
local temporary = vim.fn.tempname()
local server = vim.env.LUA_LANGUAGE_SERVER or vim.fn.exepath("lua-language-server")
if server == "" then
    server = vim.fn.stdpath("data") .. "/mason/bin/lua-language-server"
end
assert(
    vim.fn.executable(server) == 1,
    "install LuaLS separately or set LUA_LANGUAGE_SERVER to its executable"
)

local function check()
    vim.fn.mkdir(temporary, "p")

    -- Check with the editor's libraries and the workspace's runtime settings.
    local settings =
        dofile(config_dir .. "/lua/mitander/plugins/lsp.lua").opts.servers.lua_ls.settings.Lua
    local workspace_settings =
        vim.json.decode(table.concat(vim.fn.readfile(config_dir .. "/.luarc.json"), "\n"))
    settings = vim.tbl_deep_extend("force", settings, workspace_settings)
    local config_path = temporary .. "/settings.json"
    vim.fn.writefile({ vim.json.encode(settings) }, config_path)

    local function diagnose(workspace, name)
        local log = temporary .. "/" .. name
        local result = vim.system({
            server,
            "--check=" .. workspace,
            "--configpath=" .. config_path,
            "--check_format=json",
            "--checklevel=Warning",
            "--logpath=" .. log,
            "--metapath=" .. temporary .. "/meta",
        }, { text = true }):wait(60000)

        local report = log .. "/check.json"
        assert(
            vim.fn.filereadable(report) == 1,
            "LuaLS produced no report: " .. vim.inspect(result)
        )
        local diagnostics = vim.json.decode(table.concat(vim.fn.readfile(report), "\n"))
        return result, diagnostics
    end

    local result, diagnostics = diagnose(config_dir, "workspace")
    assert(result.code == 0, "Neovim Lua diagnostics: " .. vim.inspect(diagnostics))
    assert(vim.tbl_isempty(diagnostics), "Neovim workspace must have no Warning/Error diagnostics")

    -- A clean report must not come from disabled diagnostics.
    local canary = temporary .. "/canary"
    vim.fn.mkdir(canary)
    vim.fn.writefile({
        "print(vim.api.nvim_get_current_buf())",
        "dotfiles_missing_global()",
        "vim.uv.dotfiles_missing_field()",
    }, canary .. "/invalid.lua")

    local canary_result, canary_diagnostics = diagnose(canary, "canary-report")
    assert(canary_result.code == 1, "LuaLS must reject the deliberately invalid canary")

    local codes = {}
    for _, items in pairs(canary_diagnostics) do
        for _, diagnostic in ipairs(items) do
            codes[diagnostic.code] = true
        end
    end

    assert(codes["undefined-global"], "undefined globals must still be diagnosed")
    assert(
        codes["undefined-field"],
        "undefined host-library fields must still be diagnosed: " .. vim.inspect(canary_diagnostics)
    )
end

local ok, failure = xpcall(check, debug.traceback)
vim.fn.delete(temporary, "rf")

assert(ok, failure)
print("PASS: LuaLS checks Neovim source and rejects unknown globals/host-library fields")
vim.cmd("qa!")
