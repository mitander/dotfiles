local ok, null_ls = pcall(require, "null-ls")
if not ok then
    print "error: could not load null-ls"
    return
end

local formatting = null_ls.builtins.formatting

null_ls.setup {
    debug = true,
    offset_encoding = "utf-8",
    sources = {
        formatting.clang_format,
        formatting.gofmt,
        formatting.zigfmt,
        formatting.rustfmt,
        formatting.jq,
        formatting.lua_format,
    },
    on_attach = function(client, bufnr)
        if client.supports_method "textDocument/formatting" then
            vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format { bufnr = bufnr, timeout_ms = 2000 }
                end,
            })
        end
    end,
}
