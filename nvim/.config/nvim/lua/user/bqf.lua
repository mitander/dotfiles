local status_ok, bqf = pcall(require, "nvim-bqf")
if not status_ok then
  return
end

vim.cmd([[
    hi link BqfPreviewRange Search
]])

bqf.setup({
    {
    auto_enable = {
        description = [[enable nvim-bqf in quickfix window automatically]],
        default = true
    },
    magic_window = {
        description = [[give the window magic, when the window is splited horizontally, keep
            the distance between the current line and the top/bottom border of neovim unchanged.
            It's a bit like a floating window, but the window is indeed a normal window, without
            any floating attributes.]],
        default = true
    },
    auto_resize_height = {
        description = [[resize quickfix window height automatically.
            Shrink higher height to size of list in quickfix window, otherwise extend height
            to size of list or to default height (10)]],
        default = true
    },
    preview = {
        auto_preview = {
            description = [[enable preview in quickfix window automatically]],
            default = true
        },
        border_chars = {
            description = [[border and scroll bar chars, they respectively represent:
                vline, vline, hline, hline, ulcorner, urcorner, blcorner, brcorner, sbar]],
            default = {'│', '│', '─', '─', '╭', '╮', '╰', '╯', '█'}
        },
        delay_syntax = {
            description = [[delay time, to do syntax for previewed buffer, unit is millisecond]],
            default = 50
        },
        win_height = {
            description = [[the height of preview window for horizontal layout]],
            default = 15
        },
        win_vheight = {
            description = [[the height of preview window for vertical layout]],
            default = 15
        },
        wrap = {
            description = [[wrap the line, `:h wrap` for detail]],
            default = false
        },
        should_preview_cb = {
            description = [[a callback function to decide whether to preview while switching buffer,
                with a bufnr parameter]],
            default = nil
        }
    },
    func_map = {
        description = [[the table for {function = key}]],
        default = [[see ###Function table for detail]],
    },
}
})
