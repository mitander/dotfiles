local M = {}

M.echo = function(str)
    vim.cmd "redraw"
    vim.api.nvim_echo({ { str, "Bold" } }, true, {})
end

M.lazy_bootstrap = function(install_path)
    M.echo "  Installing lazy.nvim & plugins ..."
    local repo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", repo, install_path }
end

M.lazy_load = function(plugin)
    vim.api.nvim_create_autocmd({ "BufRead", "BufWinEnter", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("BeLazyOnFileOpen" .. plugin, {}),
        callback = function()
            local file = vim.fn.expand "%"
            local condition = file ~= "NvimTree_1" and file ~= "[lazy]" and file ~= ""

            if condition then
                vim.api.nvim_del_augroup_by_name("BeLazyOnFileOpen" .. plugin)

                -- dont defer for treesitter as it will show slow highlighting
                -- This deferring only happens only when we do "nvim filename"
                if plugin ~= "nvim-treesitter" then
                    vim.schedule(function()
                        require("lazy").load { plugins = plugin }

                        if plugin == "nvim-lspconfig" then
                            vim.cmd "silent! do FileType"
                        end
                    end, 0)
                else
                    require("lazy").load { plugins = plugin }
                end
            end
        end,
    })
end

M.bind = function(mode, outer_opts)
    outer_opts = outer_opts or { noremap = true, silent = true }
    return function(key, cmd, opts)
        cmd = "<cmd>" .. cmd .. "<enter>"
        opts = vim.tbl_extend("force", outer_opts, opts or {})
        vim.api.nvim_set_keymap(mode, key, cmd, opts)
    end
end

M.bind_buf = function(mode, outer_opts)
    outer_opts = outer_opts or { noremap = true, silent = true }
    return function(buf, key, cmd, opts)
        cmd = "<cmd>" .. cmd .. "<enter>"
        opts = vim.tbl_extend("force", opts, opts or {})
        vim.api.nvim_buf_set_keymap(buf, mode, key, cmd, opts)
    end
end

M.highlight = function(v)
    vim.cmd("hi! " .. v.group .. " guibg=" .. v.bg .. " guifg=" .. v.fg .. " gui='NONE'")
end

return M
