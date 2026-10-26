local M = {}

-- Compatibility adapter for the pinned live-preview.nvim server API. Keep the
-- actual bind and URL in agreement: choosing a port with a temporary socket races.
function M.setup(opts)
    local preview = require("livepreview")
    if preview._mitander_lifecycle then
        return
    end
    preview._mitander_lifecycle = true

    opts = opts or {}
    local idle_ms = opts.idle_ms or 30000
    local poll_ms = opts.poll_ms or 250
    local server = require("livepreview.server")
    local config = require("livepreview.config")
    local utils = require("livepreview.utils")
    local uv = vim.uv
    local start = preview.start
    local server_start = server.Server.start
    local server_stop = server.Server.stop
    local listening = utils.processes_listening_on_port
    local watch_dir = server.Server.watch_dir

    -- Upstream retains its Linux watcher, but drops the native recursive handle
    -- on macOS/Windows. Retain it so stop() also releases HTML preview watchers.
    server.Server.watch_dir = function(self)
        local system = uv.os_uname().sysname
        if system ~= "Darwin" and system ~= "Windows" then
            return watch_dir(self)
        end
        local watcher = assert(uv.new_fs_event())
        self._watcher = watcher
        local ok, err = watcher:start(
            self.webroot,
            { recursive = true },
            vim.schedule_wrap(function(watch_err, filename, events)
                if self._watcher ~= watcher or watch_err then
                    return
                end
                vim.api.nvim_exec_autocmds("User", {
                    pattern = "LivePreviewDirChanged",
                    data = { filename = filename, events = events },
                })
            end)
        )
        if not ok then
            error("Could not watch preview directory: " .. tostring(err))
        end
    end

    utils.processes_listening_on_port = function(port)
        -- Port zero asks the OS to allocate a port, so there is no owner to query.
        if port == 0 then
            return {}
        end
        return listening(port)
    end

    server.Server.start = function(self, address, _, start_opts)
        server_start(self, address, 0, start_opts)
        assert(self.server:is_active(), "Preview listener is not listening")
        local bound = assert(self.server:getsockname(), "Preview listener did not bind")
        assert(bound.port ~= 0, "Preview listener has no allocated port")
        assert(
            bound.ip == "127.0.0.1" or bound.ip == "::1",
            "Preview listener must stay on loopback"
        )
        -- Both :LivePreview start and the picker build their URL after start().
        config.config.port = bound.port

        local timer = assert(uv.new_timer())
        self._mitander_idle_timer = timer
        ---@type integer?
        local idle_since = uv.hrtime()
        timer:start(
            poll_ms,
            poll_ms,
            vim.schedule_wrap(function()
                -- stop() may already have run while this callback was queued.
                if self._mitander_idle_timer ~= timer then
                    return
                end
                if #server.connecting_clients > 0 then
                    idle_since = nil
                elseif not idle_since then
                    idle_since = uv.hrtime()
                elseif (uv.hrtime() - idle_since) / 1000000 >= idle_ms then
                    if preview.serverObj == self then
                        preview.close()
                    end
                end
            end)
        )
    end

    server.Server.stop = function(self, callback)
        local timer = self._mitander_idle_timer
        self._mitander_idle_timer = nil
        if timer then
            timer:stop()
            timer:close()
        end
        return server_stop(self, callback)
    end

    preview.start = function(filepath)
        config.config.port = 0
        local ok, result = pcall(start, filepath, 0)
        if not ok then
            preview.close()
            vim.notify("Could not start preview: " .. tostring(result), vim.log.levels.ERROR)
            return false
        end
        return result
    end
end

return M
