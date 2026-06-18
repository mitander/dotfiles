local uv = vim.uv
local zls_bin = vim.fn.expand("~/.local/bin/zls")

local function project_zig_root(root)
    local project_root = vim.fs.root(root, function(name, path)
        if name == "zig" then
            local local_zig = path .. "/zig/zig"
            local local_zig_lib = path .. "/zig/lib"
            return uv.fs_stat(local_zig) and uv.fs_stat(local_zig_lib)
        end
        return false
    end)
    if project_root then
        return project_root, project_root .. "/zig/zig", project_root .. "/zig/lib"
    end
end

local function add_project_zig(config, root_dir)
    local root = root_dir or config.root_dir or vim.fn.getcwd()
    local _, local_zig, local_zig_lib = project_zig_root(root)

    config.settings = config.settings or {}
    config.settings.zls = config.settings.zls or {}

    if local_zig then
        config.settings.zls.zig_exe_path = local_zig
    end

    if local_zig_lib then
        config.settings.zls.zig_lib_path = local_zig_lib
    end
end

local function zls_root_dir(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { ".git", "build.zig" })
    if not root then
        local name = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr) or bufnr
        root = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
    end

    if project_zig_root(root) or vim.fn.executable("zig") == 1 then
        on_dir(root)
    end
end

return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        {
            "j-hui/fidget.nvim",
            opts = {},
        },
    },
    opts = {
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        flags = {
            debounce_text_changes = 150,
        },
        servers = {
            gopls = {},
            jsonls = {},
            clangd = {},
            rust_analyzer = {},
            zls = {
                cmd = { zls_bin },
                root_dir = zls_root_dir,
                on_new_config = add_project_zig,
                before_init = function(_, config)
                    add_project_zig(config, config.root_dir)
                end,
                settings = {
                    zls = {
                        -- Keep ZLS useful, but avoid expensive/version-sensitive project checks by default.
                        enable_build_on_save = false,
                        enable_ast_check_diagnostics = false,
                        skip_std_references = true,
                        enable_autofix = false,
                        enable_import_completion = true,
                        enable_semantic_tokens = true,
                        enable_snippets = true,
                        enable_function_snippets = true,
                        enable_argument_placeholders = true,
                        warn_style = false,
                        highlight_global_var_declarations = false,
                    },
                },
            },
            lua_ls = {
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim", "augroup" },
                        },
                        workspace = {
                            checkThirdParty = false,
                            library = {
                                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                                [vim.fn.stdpath("config") .. "/lua"] = true,
                                [vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
                            },
                        },
                    },
                },
            },
        },
    },
    config = function(_, opts)
        local ok, blink = pcall(require, "blink.cmp")
        if ok then
            opts.capabilities =
                vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), blink.get_lsp_capabilities())
        end

        vim.diagnostic.config({
            virtual_text = true,
            update_in_insert = false,
            underline = true,
            severity_sort = true,
            float = { border = "single" },
        })

        local group = vim.api.nvim_create_augroup("LspSetup", { clear = true })

        vim.api.nvim_create_autocmd("LspAttach", {
            pattern = "*",
            group = group,
            callback = function(args)
                local map_opts = { buffer = args.buf, remap = false }
                local function qf_references()
                    vim.lsp.buf.references(nil, { loclist = false })
                end
                local function qf_implementations()
                    vim.lsp.buf.implementation({ loclist = false })
                end
                local function fzf_lsp(method, fallback)
                    return function()
                        local ok, fzf_lua = pcall(require, "fzf-lua")
                        if ok and fzf_lua[method] then
                            fzf_lua[method]({ resume = true, jump1 = false })
                        else
                            fallback()
                        end
                    end
                end

                vim.keymap.set("i", "<c-s>", vim.lsp.buf.signature_help, map_opts)
                vim.keymap.set("n", "ga", vim.lsp.buf.code_action, map_opts)
                vim.keymap.set("n", "gr", fzf_lsp("lsp_references", qf_references), map_opts)
                vim.keymap.set("n", "gR", qf_references, map_opts)
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, map_opts)
                vim.keymap.set("n", "gi", fzf_lsp("lsp_implementations", qf_implementations), map_opts)
                vim.keymap.set("n", "gI", qf_implementations, map_opts)
                vim.keymap.set("n", "go", vim.diagnostic.open_float, map_opts)
                vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, map_opts)
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, map_opts)
                vim.keymap.set("n", "<leader>s", vim.lsp.buf.signature_help, map_opts)
                vim.keymap.set("n", "K", function()
                    vim.lsp.buf.hover({ border = "single" })
                end, map_opts)
                vim.keymap.set("n", "[e", function()
                    vim.diagnostic.jump({ count = -1 })
                end, map_opts)
                vim.keymap.set("n", "]e", function()
                    vim.diagnostic.jump({ count = 1 })
                end, map_opts)
                vim.keymap.set("n", "<leader>i", function()
                    vim.lsp.inlay_hint.enable(
                        not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }),
                        { bufnr = args.buf }
                    )
                end, map_opts)
            end,
        })

        local defaults = {
            capabilities = opts.capabilities,
            flags = opts.flags,
        }

        for server, server_opts in pairs(opts.servers) do
            vim.lsp.config(server, vim.tbl_deep_extend("force", defaults, server_opts))
            vim.lsp.enable(server)
        end
    end,
}
