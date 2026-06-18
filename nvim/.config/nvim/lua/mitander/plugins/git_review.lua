return {
    dir = vim.fn.stdpath("config") .. "/lua/git-review.nvim",
    name = "git-review.nvim",
    lazy = false,
    dependencies = { "ibhagwan/fzf-lua" },
    cmd = { "GitReviewStatus", "GitReviewForm", "GitReviewChanged", "GitReviewStaged", "GitReviewBranch" },
    keys = {
        { "<leader>gS", function() require("git_review").status() end, desc = "Git status review picker" },
        { "<leader>gs", function() require("git_review").form() end, desc = "Git review form" },
        { "<leader>gd", function() require("git_review").changed_files() end, desc = "Changed files diff picker" },
        { "<leader>gD", function() require("git_review").staged_files() end, desc = "Staged files diff picker" },
        { "<leader>gr", function() require("git_review").branch() end, desc = "Review branch against default" },
    },
    config = function()
        vim.api.nvim_create_user_command("GitReviewStatus", function() require("git_review").status() end, {})
        vim.api.nvim_create_user_command("GitReviewForm", function() require("git_review").form() end, {})
        vim.api.nvim_create_user_command("GitReviewChanged", function() require("git_review").changed_files() end, {})
        vim.api.nvim_create_user_command("GitReviewStaged", function() require("git_review").staged_files() end, {})
        vim.api.nvim_create_user_command("GitReviewBranch", function() require("git_review").branch() end, {})
    end,
}
