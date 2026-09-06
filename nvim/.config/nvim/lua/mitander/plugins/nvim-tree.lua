local sidebar_width = 34

local function has_current_file()
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.bo[bufnr].buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= ""
end

local function toggle_tree()
    require("nvim-tree.api").tree.toggle({
        find_file = has_current_file(),
        update_root = false,
        focus = true,
    })
end

function _G.mitander_nvim_tree_statusline()
    local ok, core = pcall(require, "nvim-tree.core")
    local dir = ok and core.get_cwd() or nil
    local path = dir and ("  " .. vim.fn.fnamemodify(dir, ":~")) or "  NvimTree"
    return "%#NvimTreeStatusLine#" .. path
end

local function on_attach(bufnr)
    local api = require("nvim-tree.api")

    local function opts(desc)
        return {
            desc = "nvim-tree: " .. desc,
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
        }
    end

    local function move_down()
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local last_line = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_win_set_cursor(0, { math.min(line + 1, last_line), 0 })
    end

    local function enter_directory()
        local node = api.tree.get_node_under_cursor()
        if not node or node.type ~= "directory" or node.name == ".." then
            return
        end

        if not node.open then
            api.node.open.edit(node)
        end
        if node.has_children then
            vim.schedule(move_down)
        end
    end

    api.map.on_attach.default(bufnr)
    vim.opt_local.statusline = "%!v:lua.mitander_nvim_tree_statusline()"

    vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close directory"))
    vim.keymap.set("n", "l", enter_directory, opts("Enter directory"))
    vim.keymap.set("n", "<C-n>", api.tree.close, opts("Close tree"))
    vim.keymap.set("n", "<C-m>", api.tree.close, opts("Close tree"))
    vim.keymap.set("n", "<esc>", api.tree.close, opts("Close tree"))
end

return {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFindFile" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        { "<C-n>", toggle_tree, desc = "Toggle file tree" },
        { "<C-m>", toggle_tree, desc = "Toggle file tree" },
        {
            "<leader>e",
            function()
                require("nvim-tree.api").tree.find_file({ open = true, focus = true })
            end,
            desc = "Reveal current file in tree",
        },
    },
    opts = {
        on_attach = on_attach,
        disable_netrw = false,
        hijack_netrw = false,
        hijack_directories = { enable = false },
        hijack_unnamed_buffer_when_opening = false,
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        view = {
            width = sidebar_width,
            side = "left",
            number = false,
            relativenumber = false,
            signcolumn = "yes",
        },
        renderer = {
            group_empty = false,
            highlight_git = "icon",
            indent_width = 2,
            indent_markers = {
                enable = true,
                inline_arrows = true,
            },
            icons = {
                git_placement = "right_align",
                show = {
                    git = true,
                    modified = false,
                },
                glyphs = {
                    git = {
                        unstaged = "~",
                        staged = "+",
                        unmerged = "!",
                        renamed = "→",
                        untracked = "?",
                        deleted = "-",
                        ignored = "·",
                    },
                },
            },
        },
        git = {
            enable = true,
            show_on_dirs = true,
            show_on_open_dirs = false,
            timeout = 800,
        },
        filters = {
            dotfiles = false,
            git_ignored = true,
        },
        update_focused_file = {
            enable = true,
            update_root = {
                enable = false,
            },
        },
        actions = {
            open_file = {
                quit_on_open = false,
                resize_window = true,
                window_picker = {
                    enable = false,
                },
            },
        },
    },
    config = function(_, opts)
        require("nvim-tree").setup(opts)

        local function setup_tree_highlights()
            local ok, flume = pcall(require, "flume")
            if ok and flume.colors then
                local colors = flume.colors
                vim.api.nvim_set_hl(0, "NvimTreeStatusLine", {
                    fg = colors.text or "#c0caf5",
                    bg = colors.surface_alt or "#1e1e2e",
                    bold = true,
                })
            else
                vim.api.nvim_set_hl(0, "NvimTreeStatusLine", { link = "StatusLine" })
            end
        end

        setup_tree_highlights()

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("mitander_nvim_tree_colors", { clear = true }),
            callback = setup_tree_highlights,
        })

        local function apply_tree_window_options()
            if vim.bo.filetype ~= "NvimTree" then
                return
            end
            vim.opt_local.statusline = "%!v:lua.mitander_nvim_tree_statusline()"
        end

        vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "WinEnter" }, {
            group = vim.api.nvim_create_augroup("mitander_nvim_tree_window_options", { clear = true }),
            callback = apply_tree_window_options,
        })
    end,
}
