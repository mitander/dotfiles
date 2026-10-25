-- Run with: nvim --clean --headless -l tests/nvim-preview.lua [plugin-directory]
-- The optional lane exercises the installed plugin, with disposable loopback sockets.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = root .. "/nvim/.config/nvim/lua/?.lua;" .. package.path
local uv = vim.uv
local plugin = arg[1]
local config = { address = "127.0.0.1", port = 5500, dynamic_root = true }
local server = { Server = {}, connecting_clients = {} }
local preview = {}
local utils = {}
local fail_start = false
local failed_socket

if plugin then
    vim.opt.rtp:append(plugin)
    package.path = plugin .. "/lua/?.lua;" .. plugin .. "/lua/?/init.lua;" .. package.path
    require("livepreview.config").set(config)
    config = require("livepreview.config").config
    server = require("livepreview.server")
    preview = require("livepreview")
    utils = require("livepreview.utils")
else
    -- Minimal upstream API fixture. Lifecycle decisions belong to the adapter,
    -- while real TCP connections independently observe binds and disconnects.
    function server.Server:start(address, port)
        self.server = assert(uv.new_tcp())
        assert(self.server:bind(address, port))
        if fail_start == "listen" then
            failed_socket = self.server
            return nil, "EIO: fixture listen failure"
        end
        assert(self.server:listen(16, function()
            local client = assert(uv.new_tcp())
            self.server:accept(client)
            client:read_start(function(_, data)
                if data then
                    server.connecting_clients[#server.connecting_clients + 1] = client
                    client:write("HTTP/1.1 101 Switching Protocols\r\n\r\n")
                else
                    for i, peer in ipairs(server.connecting_clients) do
                        if peer == client then
                            table.remove(server.connecting_clients, i)
                            break
                        end
                    end
                    client:close()
                end
            end)
        end))
        if fail_start then
            failed_socket = self.server
            error("fixture startup failure")
        end
    end
    function server.Server:stop(callback)
        for _, client in ipairs(server.connecting_clients) do
            client:close()
        end
        server.connecting_clients = {}
        self.server:close(callback)
        if self._watcher then
            self._watcher:close()
            self._watcher = nil
        end
    end
    function server.Server:watch_dir()
        error("unexpected non-native watcher")
    end
    function preview.close()
        if preview.serverObj then
            preview.serverObj:stop()
            preview.serverObj = nil
        end
    end
    function preview.start(_, port)
        utils.processes_listening_on_port(port)
        preview.close()
        preview.serverObj = setmetatable({}, { __index = server.Server })
        preview.serverObj:start(config.address, port, {})
        return true
    end
    utils.processes_listening_on_port = function()
        error("automatic ports must not run a shell port query")
    end
    package.loaded["livepreview"] = preview
    package.loaded["livepreview.server"] = server
    package.loaded["livepreview.config"] = { config = config }
    package.loaded["livepreview.utils"] = utils
end

local clients = {}
local blocker = assert(uv.new_tcp())
local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
local file = directory .. "/preview.md"
vim.fn.writefile({ "# Preview" }, file)
local html = directory .. "/preview.html"
vim.fn.writefile({ "<p>Preview</p>" }, html)
local function wait_for(predicate, message)
    assert(vim.wait(2000, predicate, 5), message)
end
local function pause(ms)
    vim.wait(ms, function()
        return false
    end, 5)
end
local function connect(port)
    local client = assert(uv.new_tcp())
    clients[#clients + 1] = client
    local response = ""
    local connected = false
    client:connect("127.0.0.1", port, function(err)
        assert(not err, err)
        connected = true
        client:read_start(function(_, data)
            response = response .. (data or "")
        end)
        client:write(
            "GET / HTTP/1.1\r\nHost: localhost\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"
        )
    end)
    wait_for(function()
        return connected and response:find("101", 1, true)
    end, "preview must accept a real WebSocket connection")
    return client
end

local function check()
    -- Hold the configured port to model another editor, without touching 5500.
    assert(blocker:bind("127.0.0.1", 0))
    assert(blocker:listen(16, function() end))
    config.port = blocker:getsockname().port
    local occupied_port = config.port
    require("mitander.preview").setup({ idle_ms = 200, poll_ms = 10 })
    require("mitander.preview").setup() -- must not stack wrappers
    assert(preview.start(file, occupied_port))
    local first = preview.serverObj
    local first_port = config.port
    assert(first_port ~= 0 and first_port ~= occupied_port)
    assert(first.server:getsockname().ip == "127.0.0.1")
    local client = connect(first_port)
    pause(300)
    assert(preview.serverObj == first, "a connected page must prevent idle shutdown")

    local second_tab = connect(first_port)
    client:close()
    wait_for(function()
        return #server.connecting_clients == 1
    end, "closed page must be forgotten")
    pause(300)
    assert(preview.serverObj == first, "remaining tabs must keep the preview alive")
    second_tab:close()
    wait_for(function()
        return #server.connecting_clients == 0
    end, "last closed page must be forgotten")
    pause(50)
    local refreshed = connect(first_port)
    pause(300)
    assert(preview.serverObj == first, "refresh within grace must cancel shutdown")
    refreshed:close()
    wait_for(function()
        return preview.serverObj == nil
    end, "abandoned preview must stop")
    assert(first._mitander_idle_timer == nil, "idle shutdown must release its timer")

    -- Rebinding the exact port proves the listener really released it.
    local probe = assert(uv.new_tcp())
    assert(probe:bind("127.0.0.1", first_port))
    assert(probe:listen(16, function() end))
    assert(preview.start(file))
    assert(config.port ~= first_port, "new preview must not steal another listener")
    probe:close()
    wait_for(function()
        return preview.serverObj == nil
    end, "a preview with no initial browser must time out too")

    assert(preview.start(html))
    local explicit = preview.serverObj
    local timer = explicit._mitander_idle_timer
    -- The fixture does not choose filetype-specific events like upstream does.
    if not plugin and uv.os_uname().sysname == "Darwin" then
        explicit.webroot = directory
        explicit:watch_dir()
    end
    local watcher = explicit._watcher
    preview.close()
    assert(timer:is_closing(), "explicit close must release the timer")
    if watcher then
        assert(watcher:is_closing(), "explicit close must release the HTML watcher")
    end
    assert(preview.start(file))
    local replacement = preview.serverObj
    local keepalive = connect(config.port)
    pause(300)
    assert(preview.serverObj == replacement, "old queued timers must not close a new preview")
    keepalive:close()
    preview.close()

    if plugin then
        dofile(plugin .. "/plugin/livepreview.lua")
        dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/markdown.lua")[2].config()
        config = require("livepreview.config").config
        local open_browser = utils.open_browser
        local url
        utils.open_browser = function(value)
            url = value
        end
        vim.cmd("LivePreview start " .. vim.fn.fnameescape(file))
        utils.open_browser = open_browser
        assert(url == ("http://127.0.0.1:%d/preview.md"):format(config.port), "browser URL must use the bound port")
        vim.cmd("LivePreview close")
    else
        for _, failure in ipairs({
            { mode = true, message = "fixture startup failure" },
            { mode = "listen", message = "Preview listener is not listening" },
        }) do
            fail_start = failure.mode
            local notify = vim.notify
            local message
            vim.notify = function(text)
                message = text
            end
            local result = preview.start(file)
            vim.notify = notify
            assert(result == false and message:find(failure.message, 1, true))
            assert(preview.serverObj == nil and failed_socket:is_closing(), "failed startup must release its listener")
            fail_start = false
            assert(preview.start(file), "a startup failure must not prevent retry")
            preview.close()
        end
    end
end

local ok, err = xpcall(check, debug.traceback)
preview.close()
for _, client in ipairs(clients) do
    if not client:is_closing() then
        client:close()
    end
end
blocker:close()
vim.fn.delete(directory, "rf")
assert(ok, err)
print("nvim preview lifecycle checks passed" .. (plugin and " (installed plugin)" or ""))
