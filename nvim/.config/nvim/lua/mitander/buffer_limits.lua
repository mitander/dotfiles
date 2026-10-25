local M = {}

local max_bytes = 100 * 1024

local function size_bytes(bufnr)
    return vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))
end

-- Use the current text, including unsaved edits, without copying any lines into Lua.
function M.is_large(bufnr)
    bufnr = bufnr or 0
    if vim.api.nvim_buf_is_loaded(bufnr) then
        return size_bytes(bufnr) > max_bytes
    end

    local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr))
    return stats ~= nil and stats.size > max_bytes
end

function M.completion_buffers()
    local candidates = { vim.api.nvim_get_current_buf() }
    for _, window in ipairs(vim.api.nvim_list_wins()) do
        candidates[#candidates + 1] = vim.api.nvim_win_get_buf(window)
    end

    local buffers, seen = {}, {}
    local total_bytes = 0
    for _, bufnr in ipairs(candidates) do
        if not seen[bufnr] and vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
            seen[bufnr] = true
            local bytes = size_bytes(bufnr)

            -- Bound the combined input too: Blink discards all words when its total is too large.
            if total_bytes + bytes <= max_bytes then
                buffers[#buffers + 1] = bufnr
                total_bytes = total_bytes + bytes
            end
        end
    end
    return buffers
end

function M.setup_treesitter()
    -- Neovim 0.12 starts Lua/Markdown highlighting inside its ftplugins, before our FileType hook.
    -- Gate the shared entrypoint instead of copying or disabling the built-in ftplugins.
    local start = vim.treesitter.start

    ---@diagnostic disable-next-line: duplicate-set-field
    vim.treesitter.start = function(bufnr, lang)
        if not M.is_large(bufnr) then
            return start(bufnr, lang)
        end
    end
end

return M
