local function git_ref_exists(ref)
    vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", ref })
    return vim.v.shell_error == 0
end

local function default_branch()
    local origin_head = vim.fn.system({ "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })
    if vim.v.shell_error == 0 then
        return vim.trim(origin_head)
    end

    for _, ref in ipairs({ "origin/main", "origin/master", "main", "master" }) do
        if git_ref_exists(ref) then
            return ref
        end
    end
end

local function git_status()
    local ok, lib = pcall(require, "diffview.lib")
    if ok and lib.get_current_view() then
        vim.cmd.DiffviewClose()
        return
    end

    vim.cmd.DiffviewOpen()
end

local function review_branch()
    local base = default_branch()
    if not base then
        vim.notify("No main/master ref found; opening working tree diff", vim.log.levels.WARN, { title = "Diffview" })
        vim.cmd.DiffviewOpen()
        return
    end

    vim.cmd("DiffviewOpen " .. base .. "...HEAD")
end

return {
    "sindrets/diffview.nvim",
    init = function()
        local group = vim.api.nvim_create_augroup("mitander_diffview", { clear = true })

        vim.api.nvim_create_autocmd("QuitPre", {
            group = group,
            callback = function()
                local lib = package.loaded["diffview.lib"]
                if lib and lib.get_current_view and lib.get_current_view() then
                    vim.cmd.DiffviewClose()
                end
            end,
        })
    end,
    cmd = {
        "DiffviewOpen",
        "DiffviewClose",
        "DiffviewFileHistory",
        "DiffviewFocusFiles",
        "DiffviewRefresh",
        "DiffviewToggleFiles",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>gs", git_status, desc = "Git status diff" },
        { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Review working tree" },
        { "<leader>gD", "<cmd>DiffviewOpen --staged<cr>", desc = "Review staged changes" },
        { "<leader>gr", review_branch, desc = "Review branch against default" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
        { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
        { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close review" },
    },
    opts = function()
        local actions = require("diffview.actions")
        local close = "<cmd>DiffviewClose<cr>"

        return {
            enhanced_diff_hl = true,
            default_args = {
                DiffviewOpen = { "--imply-local" },
            },
            view = {
                default = { layout = "diff2_horizontal" },
                file_history = { layout = "diff2_horizontal" },
                merge_tool = { layout = "diff3_horizontal" },
            },
            file_panel = {
                listing_style = "tree",
                tree_options = {
                    flatten_dirs = true,
                    folder_statuses = "only_folded",
                },
                win_config = {
                    position = "left",
                    width = 36,
                },
            },
            keymaps = {
                view = {
                    { "n", "q", close, { desc = "Close git status" } },
                    { "n", "<esc>", close, { desc = "Close git status" } },
                    { "n", "<leader>gs", close, { desc = "Close git status" } },
                    { "n", "[g", "[c", { desc = "Previous diff hunk" } },
                    { "n", "]g", "]c", { desc = "Next diff hunk" } },
                    { "n", "-", actions.toggle_stage_entry, { desc = "Stage / unstage current file" } },
                    { "n", "s", actions.toggle_stage_entry, { desc = "Stage / unstage current file" } },
                    { "n", "S", actions.stage_all, { desc = "Stage all files" } },
                    { "n", "U", actions.unstage_all, { desc = "Unstage all files" } },
                    { "n", "X", actions.restore_entry, { desc = "Discard current file changes" } },
                },
                file_panel = {
                    { "n", "q", close, { desc = "Close git status" } },
                    { "n", "<esc>", close, { desc = "Close git status" } },
                    { "n", "<leader>gs", close, { desc = "Close git status" } },
                },
                file_history_panel = {
                    { "n", "q", close, { desc = "Close file history" } },
                    { "n", "<esc>", close, { desc = "Close file history" } },
                },
            },
        }
    end,
}
