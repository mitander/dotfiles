return {
    "j-hui/fidget.nvim",
    lazy = false,
    opts = function()
        return {
            notification = {
                override_vim_notify = true,
                configs = {
                    default = vim.tbl_extend("force", require("fidget.notification").default_config, {
                        name = "notify",
                        icon = "•",
                        icon_style = "DiagnosticInfo",
                        debug_annote = "",
                        info_annote = "",
                        warn_annote = "",
                        error_annote = "",
                    }),
                },
            },
        }
    end,
}
