ADDON_PREFIX = '[WARDEN]'

function tPrint(msg)
  local tMsg = msg
  if not type(msg) == 'string' then tMsg = tostring(msg) end
  print(ADDON_PREFIX..tMsg)
end

tPrint('addon_init.lua')

local function loadModule(name)
    local status, err = pcall(function()
        -- Load the module
        require(name)
    end)

    if not status then
        -- Tell the user about it
        tPrint('WARNING: '..name..' failed to load!')
        tPrint(err)
    end
end

function Dynamic_Wrap( mt, name )
    if Convars:GetFloat( 'developer' ) == 1 then
        local function w(...) return mt[name](...) end
        return w
    else
        return mt[name]
    end
end

loadModule('util')
loadModule('warden')
loadModule('elementthinker')
loadModule('abilityhook')

tPrint('done loading addon_init.lua')
