local languages = {
    "go",
    "zig",
    "rust",
    "lua",
    "vim",
    "vimdoc",
    "python",
    "c",
    "cpp",
    "javascript",
    "typescript",
    "json",
    "toml",
    "yaml",
    "bash",
    "fish",
    "markdown",
    "markdown_inline",
    "comment",
}

local textobjects = {
    select = {
        enable = true,
        lookahead = true,
        keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
        },
    },
    move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
        },
        goto_next_end = {
            ["]F"] = "@function.outer",
            ["]C"] = "@class.outer",
        },
        goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
        },
        goto_previous_end = {
            ["[F"] = "@function.outer",
            ["[C"] = "@class.outer",
        },
    },
}

local function is_large_file(buf)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
    return ok and stats and stats.size > 100 * 1024
end

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    cmd = { "TSUpdate", "TSInstall" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    keys = {
        { "<leader>ti", "<cmd>checkhealth nvim-treesitter<cr>", desc = "Treesitter info" },
    },
    config = function()
        local treesitter = require("nvim-treesitter")
        treesitter.setup({})
        treesitter.install(languages)

        local group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            callback = function(args)
                if is_large_file(args.buf) then
                    return
                end

                local started = pcall(vim.treesitter.start, args.buf)
                if started and vim.bo[args.buf].filetype ~= "python" then
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })

        local ok, textobjects_plugin = pcall(require, "nvim-treesitter-textobjects")
        if ok then
            textobjects_plugin.setup(textobjects)
        end
    end,
}
