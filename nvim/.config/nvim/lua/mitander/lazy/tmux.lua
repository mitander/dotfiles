return {
    "aserowy/tmux.nvim",
    config = function()
        require("tmux").setup {
            copy_sync = {
                enable = true,
                ignore_buffers = { empty = false },
                register_offset = 0,
                redirect_to_clipboard = true,
                sync_clipboard = true,
                sync_deletes = true,
                sync_unnamed = true,
            },
            navigation = {
                cycle_navigation = false,
                enable_default_keybindings = true,
            },
            resize = {
                enable_default_keybindings = true,
            },
        }
    end,
}
