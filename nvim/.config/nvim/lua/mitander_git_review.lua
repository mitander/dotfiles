local M = {}

local namespace = vim.api.nvim_create_namespace("mitander_git_review")
local buffers_by_root = {}
local states = {}

local msg_begin =
    "── Commit message ─────────────────────────────────────────"
local msg_end =
    "── Files ──────────────────────────────────────────────────"

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "git review" })
end

local function git(root, args)
    local cmd = { "git" }
    if root then
        vim.list_extend(cmd, { "-C", root })
    end
    vim.list_extend(cmd, args)

    local output = vim.fn.systemlist(cmd)
    return output, vim.v.shell_error
end

local function git_one(root, args, fallback)
    local output, code = git(root, args)
    if code == 0 and output[1] and output[1] ~= "" then
        return vim.trim(output[1])
    end
    return fallback
end

local function git_root()
    local output = vim.fn.system({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
    if vim.v.shell_error == 0 then
        return vim.trim(output)
    end
end

local function require_root(root)
    root = root or git_root()
    if not root then
        notify("Not inside a git repository", vim.log.levels.WARN)
    end
    return root
end

local function git_ref_exists(root, ref)
    local _, code = git(root, { "rev-parse", "--verify", "--quiet", ref })
    return code == 0
end

local function default_branch(root)
    local origin_head = git_one(root, { "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })
    if origin_head then
        return origin_head
    end

    for _, ref in ipairs({ "origin/main", "origin/master", "main", "master" }) do
        if git_ref_exists(root, ref) then
            return ref
        end
    end
end

local function preview_pager()
    if vim.fn.executable("delta") == 1 then
        return "delta --width=$COLUMNS"
    end
end

local function review_winopts(title)
    return {
        title = title,
        height = 0.88,
        width = 0.92,
        row = 0.50,
        col = 0.50,
        preview = {
            layout = "flex",
            flip_columns = 140,
            horizontal = "right:60%",
            vertical = "down:65%",
            scrollbar = "float",
        },
    }
end

local function format_error(output, code)
    local message = table.concat(output or {}, "\n")
    if message == "" then
        message = "git exited with code " .. tostring(code)
    end
    return message
end

local function parse_status_line(line)
    local x = line:sub(1, 1)
    local y = line:sub(2, 2)
    local path = line:sub(4):gsub([["]], "")

    if path:match("%s%->%s") then
        local renamed_to = select(2, path:match("(.*)%s%->%s(.*)"))
        if renamed_to then
            path = renamed_to
        end
    end

    return {
        raw = line,
        x = x,
        y = y,
        path = path,
    }
end

local function status_sections(root)
    local output, code = git(root, { "status", "--porcelain=v1", "-uall" })
    if code ~= 0 then
        notify(format_error(output, code), vim.log.levels.ERROR)
        return { staged = {}, unstaged = {}, untracked = {} }
    end

    local sections = { staged = {}, unstaged = {}, untracked = {} }
    for _, line in ipairs(output) do
        if line ~= "" then
            local item = parse_status_line(line)
            if item.x == "?" and item.y == "?" then
                table.insert(sections.untracked, item)
            else
                if item.x ~= " " then
                    table.insert(sections.staged, item)
                end
                if item.y ~= " " then
                    table.insert(sections.unstaged, item)
                end
            end
        end
    end

    return sections
end

local function read_message(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return { "" }
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local message = {}
    local in_message = false

    for _, line in ipairs(lines) do
        if line == msg_begin then
            in_message = true
        elseif line == msg_end then
            break
        elseif in_message then
            table.insert(message, line)
        end
    end

    if #message == 0 then
        return { "" }
    end

    return message
end

local function message_text(bufnr)
    local text = table.concat(read_message(bufnr), "\n")
    return vim.trim(text)
end

local function display_status(item)
    local x = item.x == " " and "·" or item.x
    local y = item.y == " " and "·" or item.y
    return x .. y
end

local function append_section(lines, line_to_item, title, items, section)
    table.insert(lines, "")
    table.insert(lines, title .. " (" .. tostring(#items) .. ")")

    if #items == 0 then
        table.insert(lines, "  (none)")
        return
    end

    for _, item in ipairs(items) do
        table.insert(lines, string.format("  %s  %s", display_status(item), item.path))
        line_to_item[#lines] = vim.tbl_extend("force", item, { section = section })
    end
end

local function highlight(bufnr, state)
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for index, line in ipairs(lines) do
        local row = index - 1
        if index == 1 or line == msg_begin or line == msg_end or line:match("^%u[%w ]+ %(%d+%)$") then
            vim.api.nvim_buf_add_highlight(bufnr, namespace, "Title", row, 0, -1)
        elseif line:match("^Keys:") then
            vim.api.nvim_buf_add_highlight(bufnr, namespace, "Comment", row, 0, -1)
        end
    end

    for row, item in pairs(state.line_to_item or {}) do
        local hl = item.section == "staged" and "DiffAdd" or "DiffChange"
        if item.section == "untracked" then
            hl = "DiagnosticWarn"
        end
        vim.api.nvim_buf_add_highlight(bufnr, namespace, hl, row - 1, 2, 4)
    end
end

local function render(bufnr, state)
    local message = state.message or read_message(bufnr)
    local sections = status_sections(state.root)
    local branch = git_one(state.root, { "branch", "--show-current" }, "(detached)")
    local head = git_one(state.root, { "rev-parse", "--short", "HEAD" }, "unknown")
    local upstream = git_one(state.root, { "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" }, "no upstream")

    local lines = {
        "Git review",
        "Root: " .. state.root,
        "Branch: " .. branch .. " @ " .. head .. "  Upstream: " .. upstream,
        "Keys: r refresh │ o open │ d diff │ s stage │ u unstage │ x discard │ S stage all │ U unstage all │ c commit │ q close",
        "",
        msg_begin,
    }

    vim.list_extend(lines, message)
    table.insert(lines, msg_end)

    local line_to_item = {}
    append_section(lines, line_to_item, "Staged", sections.staged, "staged")
    append_section(lines, line_to_item, "Unstaged", sections.unstaged, "unstaged")
    append_section(lines, line_to_item, "Untracked", sections.untracked, "untracked")

    state.line_to_item = line_to_item
    state.message = message

    local current_win = vim.api.nvim_get_current_win()
    local restore_view
    if vim.api.nvim_win_get_buf(current_win) == bufnr then
        restore_view = vim.fn.winsaveview()
    end

    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modified = false
    vim.bo[bufnr].modifiable = true

    highlight(bufnr, state)

    if restore_view then
        restore_view.lnum = math.min(restore_view.lnum, #lines)
        vim.fn.winrestview(restore_view)
    end
end

local function current_state(bufnr)
    local state = states[bufnr]
    if not state then
        notify("No git review state for this buffer", vim.log.levels.ERROR)
    end
    return state
end

local function current_item(bufnr)
    local state = current_state(bufnr)
    if not state then
        return
    end

    local row = vim.api.nvim_win_get_cursor(0)[1]
    local item = state.line_to_item[row]
    if not item then
        notify("Put the cursor on a changed file first", vim.log.levels.WARN)
    end
    return state, item
end

local function run_and_refresh(bufnr, args, success_message)
    local state = current_state(bufnr)
    if not state then
        return
    end

    state.message = read_message(bufnr)
    local output, code = git(state.root, args)
    if code ~= 0 then
        notify(format_error(output, code), vim.log.levels.ERROR)
        return
    end

    if success_message then
        notify(success_message)
    end
    vim.cmd.checktime()
    render(bufnr, state)
end

local function stage_item(bufnr)
    local _, item = current_item(bufnr)
    if not item then
        return
    end
    run_and_refresh(bufnr, { "add", "--", item.path }, "staged " .. item.path)
end

local function unstage_item(bufnr)
    local _, item = current_item(bufnr)
    if not item then
        return
    end
    run_and_refresh(bufnr, { "reset", "--", item.path }, "unstaged " .. item.path)
end

local function discard_item(bufnr)
    local _, item = current_item(bufnr)
    if not item then
        return
    end

    local prompt = "Discard all changes in " .. item.path .. "?"
    if item.section == "untracked" then
        prompt = "Delete untracked file " .. item.path .. "?"
    end
    if vim.fn.confirm(prompt, "&Yes\n&No", 2) ~= 1 then
        return
    end

    if item.section == "untracked" then
        run_and_refresh(bufnr, { "clean", "-f", "--", item.path }, "deleted " .. item.path)
    else
        run_and_refresh(bufnr, { "checkout", "HEAD", "--", item.path }, "discarded " .. item.path)
    end
end

local function open_path(root, path)
    if not path:match("^/") then
        path = root .. "/" .. path
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
end

local function open_item(bufnr)
    local state, item = current_item(bufnr)
    if not item then
        return
    end
    open_path(state.root, item.path)
end

local function open_diff_buffer(path, output)
    if #output == 0 then
        output = { "No diff for " .. path }
    end

    vim.cmd("botright vsplit")
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.api.nvim_buf_set_name(bufnr, "git-diff://" .. path)
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].buflisted = false
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "diff"
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
    vim.bo[bufnr].modifiable = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = bufnr, silent = true })
end

local function diff_item(bufnr)
    local state, item = current_item(bufnr)
    if not item then
        return
    end

    state.message = read_message(bufnr)

    local args
    if item.section == "untracked" then
        args = { "diff", "--no-index", "--", "/dev/null", item.path }
    elseif item.section == "staged" then
        args = { "diff", "--cached", "--", item.path }
    else
        args = { "diff", "--", item.path }
    end

    local output, code = git(state.root, args)
    if code ~= 0 and not (item.section == "untracked" and code == 1) then
        notify(format_error(output, code), vim.log.levels.ERROR)
        return
    end

    open_diff_buffer(item.path, output)
end

local function refresh(bufnr)
    local state = current_state(bufnr)
    if not state then
        return
    end
    state.message = read_message(bufnr)
    render(bufnr, state)
end

local function stage_all(bufnr)
    run_and_refresh(bufnr, { "add", "-A" }, "staged all changes")
end

local function unstage_all(bufnr)
    run_and_refresh(bufnr, { "reset" }, "unstaged all changes")
end

local function commit(bufnr)
    local state = current_state(bufnr)
    if not state then
        return
    end

    state.message = read_message(bufnr)
    local text = message_text(bufnr)
    if text == "" then
        notify("Write a commit message in the form first", vim.log.levels.WARN)
        return
    end

    local _, diff_code = git(state.root, { "diff", "--cached", "--quiet" })
    if diff_code == 0 then
        notify("No staged changes to commit", vim.log.levels.WARN)
        return
    elseif diff_code > 1 then
        notify("Could not inspect staged changes", vim.log.levels.ERROR)
        return
    end

    local message_file = vim.fn.tempname()
    vim.fn.writefile(vim.split(text, "\n", { plain = true }), message_file)

    local output, code = git(state.root, { "commit", "-F", message_file })
    vim.fn.delete(message_file)

    if code ~= 0 then
        notify(format_error(output, code), vim.log.levels.ERROR)
        return
    end

    notify(table.concat(output, "\n"))
    state.message = { "" }
    vim.cmd.checktime()
    render(bufnr, state)
end

local function setup_buffer(bufnr)
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "hide"
    vim.bo[bufnr].buflisted = false
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "gitreview"

    local opts = { buffer = bufnr, silent = true, nowait = true }
    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, opts)
    vim.keymap.set("n", "r", function()
        refresh(bufnr)
    end, opts)
    vim.keymap.set("n", "s", function()
        stage_item(bufnr)
    end, opts)
    vim.keymap.set("n", "u", function()
        unstage_item(bufnr)
    end, opts)
    vim.keymap.set("n", "x", function()
        discard_item(bufnr)
    end, opts)
    vim.keymap.set("n", "S", function()
        stage_all(bufnr)
    end, opts)
    vim.keymap.set("n", "U", function()
        unstage_all(bufnr)
    end, opts)
    vim.keymap.set("n", "o", function()
        open_item(bufnr)
    end, opts)
    vim.keymap.set("n", "<cr>", function()
        open_item(bufnr)
    end, opts)
    vim.keymap.set("n", "d", function()
        diff_item(bufnr)
    end, opts)
    vim.keymap.set("n", "c", function()
        commit(bufnr)
    end, opts)
end

local function is_oil_win(winid)
    if not vim.api.nvim_win_is_valid(winid) then
        return false
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    return vim.w[winid].oil_sidebar == true or vim.bo[bufnr].filetype == "oil"
end

local function find_review_target_win()
    local current = vim.api.nvim_get_current_win()
    if not is_oil_win(current) then
        return current
    end

    local oil_target = vim.w[current].oil_target_win
    if oil_target and vim.api.nvim_win_is_valid(oil_target) and not is_oil_win(oil_target) then
        return oil_target
    end

    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(winid).relative == "" and not is_oil_win(winid) then
            return winid
        end
    end
end

local function select_review_target_win()
    local target = find_review_target_win()
    if target and vim.api.nvim_win_is_valid(target) then
        vim.api.nvim_set_current_win(target)
        return
    end

    vim.cmd("rightbelow vertical new")
end

local function open_review_buffer(root)
    local bufnr = buffers_by_root[root]
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        bufnr = vim.api.nvim_create_buf(false, false)
        buffers_by_root[root] = bufnr
        states[bufnr] = { root = root, message = { "" }, line_to_item = {} }
        vim.api.nvim_buf_set_name(bufnr, "git-review://" .. vim.fn.fnamemodify(root, ":t"))
        setup_buffer(bufnr)
    end

    local win = vim.fn.bufwinid(bufnr)
    if win ~= -1 then
        vim.api.nvim_set_current_win(win)
    else
        select_review_target_win()
        vim.api.nvim_set_current_buf(bufnr)
    end

    local state = states[bufnr]
    state.message = read_message(bufnr)
    render(bufnr, state)
end

function M.form(opts)
    local root = require_root(opts and opts.root)
    if not root then
        return
    end
    open_review_buffer(root)
end

local function fzf_root(opts)
    return require_root(opts and opts.cwd)
end

local function fzf_stage_all(_, opts)
    local root = fzf_root(opts)
    if not root then
        return
    end

    local output, code = git(root, { "add", "-A" })
    if code ~= 0 then
        notify(format_error(output, code), vim.log.levels.ERROR)
    end
end

local function fzf_unstage_all(_, opts)
    local root = fzf_root(opts)
    if not root then
        return
    end

    local output, code = git(root, { "reset" })
    if code ~= 0 then
        notify(format_error(output, code), vim.log.levels.ERROR)
    end
end

local function fzf_form(_, opts)
    local root = fzf_root(opts)
    if root then
        M.form({ root = root })
    end
end

local function fzf_hunks(selected, opts)
    if not selected[1] then
        return
    end

    local file = require("fzf-lua.path").entry_to_file(selected[1], opts).path
    require("fzf-lua").git_hunks({
        file = file,
        cwd = opts.cwd,
        cmd = "git --no-pager diff --color=always {ref1} {ref} -- {file}",
        preview_pager = preview_pager(),
        winopts = review_winopts(" Git Hunks "),
    })
end

local function fzf_staged_hunks(selected, opts)
    if not selected[1] then
        return
    end

    local file = require("fzf-lua.path").entry_to_file(selected[1], opts).path
    require("fzf-lua").git_hunks({
        file = file,
        cwd = opts.cwd,
        cmd = "git --no-pager diff --cached --color=always -- {file}",
        preview_pager = preview_pager(),
        winopts = review_winopts(" Staged Hunks "),
    })
end

function M.status()
    local root = require_root()
    if not root then
        return
    end

    local actions = require("fzf-lua.actions")

    require("fzf-lua").git_status({
        prompt = "Review> ",
        cwd = root,
        no_resume = true,
        preview_pager = preview_pager(),
        winopts = review_winopts(" Git Status "),
        actions = {
            ["enter"] = { fn = actions.file_edit, header = "open" },
            ["ctrl-s"] = { fn = actions.git_stage_unstage, reload = true, header = "stage/unstage" },
            ["ctrl-a"] = { fn = fzf_stage_all, reload = true, header = "stage all" },
            ["ctrl-u"] = { fn = fzf_unstage_all, reload = true, header = "unstage all" },
            ["ctrl-x"] = { fn = actions.git_reset, reload = true, header = "discard" },
            ["ctrl-d"] = { fn = fzf_hunks, header = "hunks" },
            ["ctrl-f"] = { fn = fzf_form, header = "form" },
        },
    })
end

function M.changed_files()
    local root = require_root()
    if not root then
        return
    end

    require("fzf-lua").git_diff({
        ref = "HEAD",
        cwd = root,
        prompt = "Changed> ",
        no_resume = true,
        preview_pager = preview_pager(),
        winopts = review_winopts(" Git Diff "),
        actions = {
            ["ctrl-f"] = { fn = fzf_form, header = "form" },
        },
    })
end

function M.staged_files()
    local root = require_root()
    if not root then
        return
    end

    require("fzf-lua").git_diff({
        cwd = root,
        cmd = "git --no-pager diff --cached --name-only",
        preview = "git diff --cached --color -- {file}",
        prompt = "Staged> ",
        no_resume = true,
        preview_pager = preview_pager(),
        winopts = review_winopts(" Staged Diff "),
        actions = {
            ["ctrl-d"] = { fn = fzf_staged_hunks, header = "hunks" },
            ["ctrl-f"] = { fn = fzf_form, header = "form" },
        },
    })
end

function M.branch()
    local root = require_root()
    if not root then
        return
    end

    local base = default_branch(root)
    if not base then
        notify("No main/master ref found", vim.log.levels.WARN)
        return
    end

    require("fzf-lua").git_diff({
        ref = base .. "...HEAD",
        prompt = "Branch> ",
        cwd = root,
        no_resume = true,
        preview_pager = preview_pager(),
        winopts = review_winopts(" Branch Review: " .. base .. "...HEAD "),
        actions = {
            ["ctrl-f"] = { fn = fzf_form, header = "form" },
        },
    })
end

return M
