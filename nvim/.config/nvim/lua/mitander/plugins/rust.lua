return {
    "mrcjkb/rustaceanvim",
    version = "^9",
    -- Rustaceanvim is already a lazy filetype plugin. It alone starts rust-analyzer.
    lazy = false,
    init = function()
        -- Evaluate completion capabilities only when a Rust buffer loads.
        vim.g.rustaceanvim = function()
            return {
                tools = { test_executor = "background" },
                server = {
                    capabilities = require("blink.cmp").get_lsp_capabilities(),
                    -- Use this editor's PATH rather than discovering a shared server.
                    lspmux = { enable = false },
                    on_attach = function(_, bufnr)
                        local function map(lhs, command, desc)
                            vim.keymap.set("n", lhs, function()
                                vim.cmd.RustLsp(command)
                            end, { buffer = bufnr, desc = desc })
                        end

                        map("<leader>cr", "runnables", "Rust run targets")
                        map("<leader>cR", { "runnables", bang = true }, "Rerun Rust target")
                        map("<leader>ct", "testables", "Rust test targets")
                        map("<leader>cT", { "testables", bang = true }, "Rerun Rust tests")
                        map("<leader>cm", "expandMacro", "Expand Rust macro")
                    end,
                },
                -- Debugger integration is opt-in, not part of ordinary Rust startup.
                dap = { autoload_configurations = false },
            }
        end
    end,
}
