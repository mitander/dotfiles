return {
    "j-hui/fidget.nvim",
    lazy = false,
    init = function()
        -- Typed :messages follows notifications. :execute 'messages' stays native.
        vim.cmd([[
            cnoreabbrev <expr> messages getcmdtype() == ':' && getcmdline() ==# 'messages' ? 'Fidget history' : 'messages'
        ]])
    end,
    opts = function()
        return {
            notification = {
                override_vim_notify = true,
                configs = {
                    default = vim.tbl_extend(
                        "force",
                        require("fidget.notification").default_config,
                        {
                            name = "notify",
                            icon = "•",
                            icon_style = "DiagnosticInfo",
                            debug_annote = "",
                            info_annote = "",
                            warn_annote = "",
                            error_annote = "",
                        }
                    ),
                },
            },
        }
    end,
}
