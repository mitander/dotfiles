local ok, fzf_lua = pcall(require, "fzf-lua")
if not ok then
    return
end

fzf_lua.setup {
    winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.55,
        preview = {
            layout = "flex",
            flip_columns = 130,
            scrollbar = "float",
        },
    },
    previewers = {
        bat = { theme = "base16" },
    },
    files = {
        fd_opts = "--no-ignore --color=never --type f --hidden --follow  --exclude .git",
        action = { ["ctrl-l"] = fzf_lua.actions.arg_add },
        cwd = vim.loop.cwd()
    },
    grep = {
        rg_glob = true,
        rg_opts = "--hidden --column --line-number --no-heading"
            .. " --color=always --smart-case -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'",
    },
    git = {
        status = {
            cmd = "git status -su",
            winopts = {
                preview = { vertical = "down:70%", horizontal = "right:70%" },
            },
            actions = {
                ["ctrl-x"] = { fzf_lua.actions.git_reset, fzf_lua.actions.resume },
            },
            preview_pager = vim.fn.executable "delta" == 1 and "delta --width=$COLUMNS",
        },
        commits = {
            winopts = { preview = { vertical = "down:60%" } },
            preview_pager = vim.fn.executable "delta" == 1 and "delta --width=$COLUMNS",
        },
        bcommits = {
            winopts = { preview = { vertical = "down:60%" } },
            preview_pager = vim.fn.executable "delta" == 1 and "delta --width=$COLUMNS",
        },
        branches = {
            winopts = {
                preview = { vertical = "down:75%", horizontal = "right:75%" },
            },
        },
        files = {
            cmd = "git ls-files  --exclude-standard --other -c",
        },
    },
    diagnostics = { icon_padding = " " },
    file_ignore_patterns = {
        "jpg",
        "jpeg",
        "ttf",
        "otf",
        "png",
        "vendor",
        ".vscode",
        ".gitlab/",
        "*cache*",
        ".git/",
    },
}

if vim.ui then
    fzf_lua.register_ui_select {
        winopts = {
            win_height = 0.30,
            win_width = 0.70,
            win_row = 0.40,
        },
    }
end
