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
        { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Review working tree" },
        { "<leader>gD", "<cmd>DiffviewOpen --staged<cr>", desc = "Review staged changes" },
        { "<leader>gr", review_branch, desc = "Review branch against default" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
        { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
        { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close review" },
    },
    opts = {
        enhanced_diff_hl = true,
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
    },
}
