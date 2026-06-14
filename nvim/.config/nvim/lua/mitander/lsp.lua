local uv = vim.uv or vim.loop

local function project_zig_paths(root)
    local local_zig = root .. "/zig/zig"
    local local_zig_lib = root .. "/zig/lib"
    return local_zig, local_zig_lib
end

local function add_project_zig(new_config, root_dir)
    local root = root_dir or vim.fn.getcwd()
    local local_zig, local_zig_lib = project_zig_paths(root)

    new_config.settings = vim.deepcopy(new_config.settings or {})
    new_config.settings.zls = new_config.settings.zls or {}

    if uv.fs_stat(local_zig) then
        new_config.settings.zls.zig_exe_path = local_zig
    end

    if uv.fs_stat(local_zig_lib) then
        new_config.settings.zls.zig_lib_path = local_zig_lib
    end
end

local function zls_root_dir(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "build.zig", ".git" })
    if not root then
        local name = vim.api.nvim_buf_get_name(bufnr)
        root = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
    end

    local local_zig = project_zig_paths(root)
    if uv.fs_stat(local_zig) or vim.fn.executable("zig") == 1 then
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
                cmd = { "zls" },
                root_dir = zls_root_dir,
                on_new_config = add_project_zig,
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

        local group = vim.api.nvim_create_augroup("LspSetup", {})

        vim.api.nvim_create_autocmd("LspAttach", {
            pattern = "*",
            group = group,
            callback = function(args)
                local map_opts = { buffer = args.buf, remap = false }
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
                vim.keymap.set("n", "gr", fzf_lsp("lsp_references", vim.lsp.buf.references), map_opts)
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, map_opts)
                vim.keymap.set("n", "gi", fzf_lsp("lsp_implementations", vim.lsp.buf.implementation), map_opts)
                vim.keymap.set("n", "go", vim.diagnostic.open_float, map_opts)
                vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, map_opts)
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, map_opts)
                vim.keymap.set("n", "<leader>s", vim.lsp.buf.signature_help, map_opts)
                vim.keymap.set("n", "K", function()
                    vim.lsp.buf.hover({ border = "single" })
                end, map_opts)
                vim.keymap.set("n", "[d", function()
                    vim.diagnostic.jump({ count = -1 })
                end, map_opts)
                vim.keymap.set("n", "]d", function()
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
