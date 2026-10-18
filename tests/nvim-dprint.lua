-- Run with: nvim --clean --headless -l tests/nvim-dprint.lua
-- Requires installed Conform, dprint and the configured native formatters.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config_dir = root .. "/nvim/.config/nvim"
vim.env.DPRINT_CONFIG_DIR = root .. "/dprint/.config/dprint"
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/conform.nvim")
local opts = dofile(config_dir .. "/lua/mitander/plugins/conform.lua").opts
opts.format_on_save = nil
require("conform").setup(opts)

-- Paths must stay literal across config expansion, exec templates and shell arguments.
local temporary = vim.fn.tempname() .. [[ space & ' " < >]]
vim.fn.mkdir(temporary, "p")
vim.fn.writefile({
    "[package]",
    'name = "format_fixture"',
    'version = "0.1.0"',
    'edition = "2018"',
    "[lib]",
    'path = "example.rs"',
}, temporary .. "/Cargo.toml")
local samples = {
    { "lua", "lua", "local x={a=1}" },
    { "py", "python", "import sys\nimport os\nx=1" },
    { "rs", "rust", "async fn gen(){let x=1;}" },
    { "go", "go", 'package main\nfunc main(){println("hello")}' },
    { "c", "c", "int main(){return 0;}" },
    { "cpp", "cpp", "int main(){return 0;}" },
    { "sh", "sh", "if true;then echo hi;fi" },
    { "bash", "bash", "#!/usr/bin/env bash\nif [[ -n $HOME ]];then\necho hi\nfi" },
    { "zsh", "zsh", "#!/usr/bin/env zsh\nif true;then\necho hi\nfi" },
    { "fish", "fish", "if true;echo hi;end" },
    { "nix", "nix", "{a=1;}" },
    { "zig", "zig", "pub fn main() void {const x=1;_=x;}" },
    { "js", "javascript", "const x={a:1};" },
    { "ts", "typescript", "const x:number=1;" },
    { "jsx", "javascriptreact", 'const x=<div a="b">hello</div>;' },
    { "tsx", "typescriptreact", 'const x=<div a="b">hello</div>;' },
    { "json", "json", '{"x":1}' },
    { "jsonc", "jsonc", '{"x":1,}' },
    { "md", "markdown", "#    Title" },
    { "toml", "toml", "x=1" },
    { "yaml", "yaml", "x:    1" },
    { "html", "html", '<div  class = "hello" >hello</div>' },
    { "css", "css", "a{color:red}" },
    { "scss", "scss", "$c:red;a{color:$c}" },
}

local function format_buffer()
    local completed, failure = false, nil
    require("conform").format({ async = false, timeout_ms = 5000 }, function(err)
        completed, failure = true, err
    end)
    assert(completed, "formatter callback did not run")
    return failure
end

local ok, failure = xpcall(function()
    for _, sample in ipairs(samples) do
        vim.cmd.enew({ bang = true })
        local filename = temporary .. "/example." .. sample[1]
        local lines = vim.split(sample[3], "\n", { plain = true })
        vim.fn.writefile(lines, filename)
        vim.api.nvim_buf_set_name(0, filename)
        vim.bo.filetype = sample[2]
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        local err = format_buffer()
        assert(not err, sample[1] .. ": " .. vim.inspect(err))
        local formatted = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        assert(formatted ~= sample[3], sample[1] .. " should be formatted")
        assert(vim.deep_equal(vim.fn.readfile(filename), lines), "formatting must not rewrite the source file")
        if sample[1] == "py" then
            assert(formatted:find("import os\nimport sys", 1, true), "organize imports without removing unused imports")
        end
        if sample[1] == "bash" or sample[1] == "zsh" then
            assert(formatted:find("\n  echo hi\n", 1, true), "shell indentation must use two spaces")
        end
        print("PASS: Conform formats " .. sample[1] .. " without writing the source file")
    end

    -- A project config replaces the global preset, without changing editor setup.
    local project = temporary .. "/project"
    vim.fn.mkdir(project)
    local project_config =
        vim.json.decode(table.concat(vim.fn.readfile(vim.env.DPRINT_CONFIG_DIR .. "/dprint.json"), "\n"))
    project_config.indentWidth = 4
    vim.fn.writefile({ vim.json.encode(project_config) }, project .. "/dprint.json")
    vim.cmd.enew({ bang = true })
    vim.api.nvim_buf_set_name(0, project .. "/example.json")
    vim.bo.filetype = "json"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "{", '"x":1', "}" })
    assert(not format_buffer())
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(lines[2] == '    "x": 1', "project indentation must override the global preset: " .. vim.inspect(lines))
    print("PASS: project config overrides the global preset")

    -- A failing native formatter must not replace the buffer.
    local bin = temporary .. "/bin"
    vim.fn.mkdir(bin)
    vim.fn.writefile({ "#!/bin/sh", "printf replacement; exit 1" }, bin .. "/clang-format")
    vim.fn.setfperm(bin .. "/clang-format", "rwxr-xr-x")
    vim.cmd.enew({ bang = true })
    vim.api.nvim_buf_set_name(0, temporary .. "/failure.c")
    vim.bo.filetype = "c"
    local original = { "int main(){return 0;}" }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, original)
    vim.env.PATH = bin .. ":" .. vim.env.PATH
    assert(format_buffer(), "native formatter failure must reach Conform")
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), original))
    print("PASS: native formatter failure preserves the buffer")
end, debug.traceback)
vim.fn.delete(temporary, "rf")
assert(ok, failure)
vim.cmd("qa!")
