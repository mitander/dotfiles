local status_ok, bqf = pcall(require, "bqf")
if not status_ok then
  return
end

vim.cmd([[
    hi link BqfPreviewRange Search
]])

bqf.setup({
    auto_enable = true,
    preview = {
        win_height = 12,
        win_vheight = 12,
        delay_syntax = 80,
        border_chars = {'┃', '┃', '━', '━', '┏', '┓', '┗', '┛', '█'},
        should_preview_cb = function(bufnr)
            local ret = true
            local filename = vim.api.nvim_buf_get_name(bufnr)
            local fsize = vim.fn.getfsize(filename)
            -- file size greater than 100k can't be previewed automatically
            if fsize > 100 * 1024 then
                ret = false
            end
            return ret
        end
    },
    -- make `drop` and `tab drop` to become preferred
    func_map = {
        drop = '<;>',
        openc = 'O',
        tabdrop = '<C-t>',
        tabc = '',
        ptogglemode = 'z,',
    },
})
