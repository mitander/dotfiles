local M = {}

function M.config()
  local status_ok, nvimtree = pcall(require, "nvim-tree")
  if not status_ok then
    return
  end

  local config_status_ok, nvim_tree_config = pcall(require, "nvim-tree.config")
  if not config_status_ok then
    return
  end

  local tree_cb = nvim_tree_config.nvim_tree_callback

  local g = vim.g

  g.nvim_tree_indent_markers = 1

  g.nvim_tree_icons = {
    default = "",
    symlink = "",
    git = {
      deleted = "",
      ignored = "◌",
      renamed = "➜",
      staged = "✓",
      unmerged = "",
      unstaged = "✗",
      untracked = "★",
    },
    folder = {
      default = "",
      empty = "",
      empty_open = "",
      open = "",
      symlink = "",
      symlink_open = "",
    },
  }

  nvimtree.setup {
    filters = {
      dotfiles = false,
      custom = {
        ".git",
        "node_modules",
        ".cache",
        "__pycache__",
      },
    },
    disable_netrw = true,
    hijack_netrw = true,
    ignore_ft_on_setup = {
      "dashboard",
      "startify",
      "alpha",
    },
    auto_close = true,
    open_on_tab = false,
    quit_on_open = true,
    hijack_cursor = true,
    hide_root_folder = true,
    update_cwd = true,
    update_focused_file = {
      enable = true,
      update_cwd = true,
      ignore_list = {},
    },
    diagnostics = {
      enable = false,
      icons = {
        hint = "",
        info = "",
        warning = "",
        error = "",
      },
    },
    view = {
      width = 25,
      height = 30,
      side = "left",
      allow_resize = true,
      hide_root_folder = false,
      number = false,
      relativenumber = false,
      signcolumn = "yes",
      mappings = {
        custom_only = false,
        list = {
          { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
          { key = { "h", "<BS>" }, cb = tree_cb "close_node" },
          { key = "h", cb = tree_cb "close_node" },
          { key = "<C-v>", cb = tree_cb "vsplit" },
          { key = "<C-s>", cb = tree_cb "split" },
        },
      },
    },
    git = {
      enable = true,
      ignore = false,
      timeout = 500,
    },
    show_icons = {
      git = 1,
      folders = 1,
      files = 1,
      folder_arrows = 0,
      tree_width = 30,
    },
  }
end

return M
