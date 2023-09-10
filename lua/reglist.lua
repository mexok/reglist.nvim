local M = {
    regnames = {
        "a",  --  1
        "b",  --  2
        "c",  --  3
        "d",  --  4
        "e",  --  5
        "f",  --  6
        "g",  --  7
        "h",  --  8
        "i",  --  9
    },
}

local set = vim.keymap.set
vim.g.REGLIST = {}


function M.get_name(index)
    return M.regnames[index]
end

function M.trim_newline(value)
    value = string.gsub(value, "\n$", "")
    return value
end

function M.push()
    local value = vim.fn.getreg('\"')
    local reglist = vim.g.REGLIST
    table.insert(reglist, value)
    vim.g.REGLIST = reglist
    local reg = M.get_name(#vim.g.REGLIST)
    if reg ~= nil then
        vim.fn.setreg(reg, value)
    end
end

function M.pop()
    if #vim.g.REGLIST == 0 then
        print("Error: Reglist is empty")
        return
    end
    local reg = M.get_name(#vim.g.REGLIST)
    if reg ~= nil then
        vim.fn.setreg('\"', vim.fn.getreg(reg))
    end
    local reglist = vim.g.REGLIST
    table.remove(reglist)
    vim.g.REGLIST = reglist
end

function M.shift()
    if #vim.g.REGLIST == 0 then
        print("Error: Reglist is empty")
        return
    end
    local reglist = vim.g.REGLIST
    vim.fn.setreg('\"', reglist[1])
    for i = 2, #reglist do
        local reg = M.get_name(i-1)
        if reg ~= nil then
            vim.fn.setreg(reg, reglist[i])
        end
        reglist[i-1] = reglist[i]
    end
    table.remove(reglist)
    vim.g.REGLIST = reglist
end

function M.unshift()
    local reglist = vim.g.REGLIST
    local value = vim.fn.getreg('\"')
    table.insert(reglist, 1, value)
    for i = 1, #reglist do
        local reg = M.get_name(i)
        if reg ~= nil then
            vim.fn.setreg(reg, reglist[i])
        end
    end
    vim.g.REGLIST = reglist
end

function M.import()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    local line_start = vstart[2]
    local line_end = vend[2]
    for line = line_start, line_end do
        local content = vim.fn.getline(line)
        vim.fn.setreg('\"', content)
        M.push()
    end
end

function M.export()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = {}
    for i = 1, #vim.g.REGLIST do
        M.shift()
        local content = vim.fn.getreg('\"')
        content = M.trim_newline(content)
        for line in content:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
    end
    vim.api.nvim_buf_set_lines(0, row, row, 0, lines)
    for i = 1, #lines do
        vim.api.nvim_feedkeys("j", 'm', false)
    end
end

function M.print(index)
    local reg = M.get_name(index)
    if reg == nil then
        print(index..': '..M.trim_newline(vim.g.REGLIST[index]))
    else
        print(index..'-'..M.get_name(index)..': '..M.trim_newline(vim.g.REGLIST[index]))
    end
end

function M.glob()
    if #vim.g.REGLIST == 0 then
        print("Reglist is empty")
        return
    end
    for index=1, #vim.g.REGLIST do
        M.print(index)
    end
end

function M.set_default_keymaps(m)
    set({"v"}, m.."i", "<esc><cmd>lua vim.g.REGLIST = {}; require('reglist').import()<cr>", {desc = 'Import reg list'})
    set({"v"}, m.."I", "<esc><cmd>lua require('reglist').import()<cr>", {desc = 'Import reg list (appending)'})
    set({"n"}, m.."e", "<cmd>lua require('reglist').export()<cr>", {desc = 'Export reg list'})
    set({"n", "v"}, m.."g", "<cmd>lua require('reglist').glob()<cr>", {desc = 'Print current registers'})
    set({"n", "v"}, m.."r", "<cmd>lua print(#vim.g.REGLIST)<cr>", {desc = 'Print current reg list size'})

    set("n", m.."p", "<cmd>lua require('reglist').pop()<cr>p", {desc = 'Pop and paste'})
    set("n", m.."P", "<cmd>lua require('reglist').pop()<cr>P", {desc = 'Pop and paste'})
    set("v", m.."p", "<cmd>lua require('reglist').pop()<cr>P", {desc = 'Pop and paste'})

    set("n", m.."s", "<cmd>lua require('reglist').shift()<cr>p", {desc = 'Shift and paste'})
    set("n", m.."S", "<cmd>lua require('reglist').shift()<cr>P", {desc = 'Shift and paste'})
    set("v", m.."s", "<cmd>lua require('reglist').shift()<cr>P", {desc = 'Shift and paste'})

    set("n", m.."y", "yl<cmd>lua require('reglist').push()<cr>", {desc = 'Yank char and push'})
    set("n", m.."Y", "Y<cmd>lua require('reglist').push()<cr>", {desc = 'Yank and push'})
    set("v", m.."y", "y<cmd>lua require('reglist').push()<cr>", {desc = 'Yank and push'})
    set("n", m.."d", "x<cmd>lua require('reglist').push()<cr>", {desc = 'Delete char and push'})
    set("n", m.."D", "D<cmd>lua require('reglist').push()<cr>", {desc = 'Delete and push'})
    set("v", m.."d", "x<cmd>lua require('reglist').push()<cr>", {desc = 'Delete and push'})

    set("n", m.."u", "yl<cmd>lua require('reglist').unshift()<cr>", {desc = 'Yank char and unshift'})
    set("n", m.."U", "Y<cmd>lua require('reglist').unshift()<cr>", {desc = 'Yank and unshift'})
    set("v", m.."u", "y<cmd>lua require('reglist').unshift()<cr>", {desc = 'Yank and unshift'})
    set("n", m.."x", "yl<cmd>lua require('reglist').unshift()<cr>", {desc = 'Delete char and unshift'})
    set("n", m.."X", "Y<cmd>lua require('reglist').unshift()<cr>", {desc = 'Delete and unshift'})
    set("v", m.."x", "y<cmd>lua require('reglist').unshift()<cr>", {desc = 'Delete and unshift'})

    set({"n", "v"}, m.."c", "<cmd>lua vim.g.REGLIST = {}; print(\"Reg list index resetted\")<cr>", {desc = 'Clear reg list'})
end

function M.setup(config)
    if (config.default_mappings) then
        M.set_default_keymaps(config.default_mappings)
    end
    if (config.regnames) then
        M.regnames = config.regnames
    end
end

return M
