local dap = require "dap"

dap.adapters.lldb = {
    type = "executable",
    command = "/opt/homebrew/opt/llvm/bin/lldb-vscode",
    name = "lldb",
}

dap.configurations.c = {
    {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
            local splits = {}
            for str in string.gmatch(vim.uv.cwd(), "[^/]*") do
                table.insert(splits, str)
            end
            -- use root folder name as binary name
            print("./build/" .. splits[#splits - 1])
            return "./build/" .. splits[#splits - 1]
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
    },
}

dap.configurations.go = {
    {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
            local splits = {}
            for str in string.gmatch(vim.uv.cwd(), "[^/]*") do
                table.insert(splits, str)
            end
            -- use root folder name as binary name
            return splits[#splits - 1]
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
    },
}

dap.configurations.cpp = {
    {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
            local splits = {}
            for str in string.gmatch(vim.uv.cwd(), "[^/]*") do
                table.insert(splits, str)
            end
            -- use root folder name as binary name
            return "./build/" .. splits[#splits - 1]
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
    },
}

dap.configurations.zig = {
    {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
            local splits = {}
            for str in string.gmatch(vim.uv.cwd(), "[^/]*") do
                table.insert(splits, str)
            end
            -- use root folder name as binary name
            return "./zig-out/bin/" .. splits[#splits - 1]
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
    },
}

dap.configurations.rust = {
    {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
            local splits = {}
            for str in string.gmatch(vim.uv.cwd(), "[^/]*") do
                table.insert(splits, str)
            end
            -- use root folder name as binary name
            return "./target/debug/" .. splits[#splits - 1]
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
    },
}

require("dapui").setup()

local nmap = require("utils").nmap
nmap { "<leader>dr", function()
    require("dap").continue()
    require("dap").open()
end }
nmap { "<leader>q", function()
    require("dap").terminate()
    require("dap").close()
end }
nmap { "<leader>bp", require 'dap'.toggle_breakpoint }
nmap { "<leader>bd", require 'dap'.clear_breakpoints }
nmap { "<leader>so", require 'dap'.step_over }
nmap { "<leader>si", require 'dap'.step_into }
nmap { "<leader>du", require 'dapui'.toggle }
