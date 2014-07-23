local function loadModule(name)
    local status, err = pcall(function()
        -- Load the module
        require(name)
    end)

    if not status then
        -- Tell the user about it
        print('WARNING: '..name..' failed to load!')
        print(err)
    end
end

function tPrint(msg)
  local PREFIX = '[EXINVOKER]'
  print PREFIX..msg
end

tPrint('executing addon_init.lua')
loadModule('addon')
loadModule('addon')
tPrint('done addon_init')
