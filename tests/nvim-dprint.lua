-- Run with: nvim --clean --headless -l tests/nvim-dprint.lua
-- Requires installed Conform, dprint and the configured native formatters.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config_dir = root .. "/nvim/.config/nvim"
local function new_buffer(filename, filetype, lines)
    local buffer = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, filename)
    vim.bo[buffer].filetype = filetype
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
end

-- Paths must stay literal across config expansion, exec templates and shell arguments.
local temporary = vim.fn.tempname() .. [[ space & ' " < >]]
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
    vim.env.DPRINT_CONFIG_DIR = root .. "/dprint/.config/dprint"
    vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/conform.nvim")

    local opts = dofile(config_dir .. "/lua/mitander/plugins/conform.lua").opts
    opts.format_on_save = nil

    -- Observe expected failures through callbacks, not queued editor notifications.
    opts.notify_on_error = false
    require("conform").setup(opts)

    vim.fn.mkdir(temporary, "p")
    vim.fn.writefile({
        "[package]",
        'name = "format_fixture"',
        'version = "0.1.0"',
        'edition = "2018"',
        "[lib]",
        'path = "example.rs"',
    }, temporary .. "/Cargo.toml")

    for _, sample in ipairs(samples) do
        local extension, filetype, source = sample[1], sample[2], sample[3]
        local filename = temporary .. "/example." .. extension
        local lines = vim.split(source, "\n", { plain = true })
        vim.fn.writefile(lines, filename)
        new_buffer(filename, filetype, lines)

        local err = format_buffer()
        assert(not err, extension .. ": " .. vim.inspect(err))

        local formatted = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        assert(formatted ~= source, extension .. " should be formatted")
        assert(
            vim.deep_equal(vim.fn.readfile(filename), lines),
            "formatting must not rewrite the source file"
        )
        if extension == "py" then
            assert(
                formatted:find("import os\nimport sys", 1, true),
                "organize imports without removing unused imports"
            )
        end
        if extension == "bash" or extension == "zsh" then
            assert(
                formatted:find("\n  echo hi\n", 1, true),
                "shell indentation must use two spaces"
            )
        end
        print("PASS: Conform formats " .. extension .. " without writing the source file")
    end

    -- A project config replaces the global preset, without changing editor setup.
    local project = temporary .. "/project"
    vim.fn.mkdir(project)
    local project_config = vim.json.decode(
        table.concat(vim.fn.readfile(vim.env.DPRINT_CONFIG_DIR .. "/dprint.json"), "\n")
    )
    project_config.indentWidth = 4
    vim.fn.writefile({ vim.json.encode(project_config) }, project .. "/dprint.json")

    new_buffer(project .. "/example.json", "json", { "{", '"x":1', "}" })
    assert(not format_buffer())
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(
        lines[2] == '    "x": 1',
        "project indentation must override the global preset: " .. vim.inspect(lines)
    )
    print("PASS: project config overrides the global preset")

    -- A repository-wide formatter must not intercept native current-buffer formatting.
    vim.fn.mkdir(project .. "/.dev-tools/bin", "p")
    local pinned = project .. "/.dev-tools/bin/dprint"
    vim.fn.writefile({ "#!/bin/sh", "exit 99" }, pinned)
    vim.fn.setfperm(pinned, "rwxr-xr-x")
    for _, sample in ipairs({ samples[2], samples[3] }) do
        local extension, filetype, source = sample[1], sample[2], sample[3]
        local filename = project .. "/example." .. extension
        local original = vim.split(source, "\n", { plain = true })
        vim.fn.writefile(original, filename)
        new_buffer(filename, filetype, original)
        assert(not format_buffer(), "native formatter must bypass project dprint")
        assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") ~= source)
        assert(vim.deep_equal(vim.fn.readfile(filename), original), "only the buffer may change")
    end
    print("PASS: Rust and Python buffers bypass project dprint without writing source files")

    -- Editor stdin formatting and the Cargo gate must honor the same project policy.
    vim.fn.writefile({
        "[package]",
        'name = "native_format_fixture"',
        'version = "0.1.0"',
        'edition = "2024"',
        "[lib]",
        'path = "equivalence.rs"',
    }, project .. "/Cargo.toml")
    vim.fn.writefile({ 'edition = "2024"', "max_width = 60" }, project .. "/rustfmt.toml")
    local rust_path = project .. "/equivalence.rs"
    local rust_source = { "pub async fn example(){let values=[1,2,3,4,5,6,7,8,9,10];}" }
    vim.fn.writefile(rust_source, rust_path)
    new_buffer(rust_path, "rust", rust_source)
    assert(not format_buffer())
    local rust_buffer = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(vim.deep_equal(vim.fn.readfile(rust_path), rust_source))
    local cargo = vim.system({ "cargo", "fmt", "--all" }, {
        cwd = project,
        env = { RUSTUP_AUTO_INSTALL = "0" },
        text = true,
    }):wait(10000)
    assert(cargo.code == 0, cargo.stderr)
    assert(vim.deep_equal(vim.fn.readfile(rust_path), rust_buffer))
    print("PASS: editor Rust formatting matches cargo fmt with project configuration")

    -- A failing native formatter must not replace the buffer.
    local bin = temporary .. "/bin"
    vim.fn.mkdir(bin)
    vim.fn.writefile({ "#!/bin/sh", "printf replacement; exit 1" }, bin .. "/clang-format")
    vim.fn.setfperm(bin .. "/clang-format", "rwxr-xr-x")

    local original_lines = { "int main(){return 0;}" }
    new_buffer(temporary .. "/failure.c", "c", original_lines)
    vim.env.PATH = bin .. ":" .. vim.env.PATH
    assert(format_buffer(), "native formatter failure must reach Conform")
    assert(
        vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), original_lines),
        "native formatter failure must preserve the buffer"
    )
    print("PASS: native formatter failure preserves the buffer")
end, debug.traceback)

vim.fn.delete(temporary, "rf")

assert(ok, failure)
vim.cmd("qa!")
