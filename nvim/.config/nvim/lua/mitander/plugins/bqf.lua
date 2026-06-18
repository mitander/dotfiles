return {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
        auto_enable = true,
        magic_window = true,
        auto_resize_height = true,
        preview = {
            auto_preview = true,
            border_chars = { "│", "│", "─", "─", "╭", "╮", "╰", "╯", "█" },
            delay_syntax = 50,
            win_height = 15,
            win_vheight = 15,
            wrap = false,
        },
        func_map = {
            openc = "<enter>",
        },
    },
}
