ADDON_PREFIX = '[WARDEN]※'

DEBUG_MODE = true

InitLogFile('log/log_warden.txt','log_init\n')
AppendToLogFile('log/log_warden.txt',
    'INIT LOG FILE\n----------------------------------\n\n')

function tPrint(msg)
    if not DEBUG_MODE then return end
    if not msg then return end
    local tMsg = msg
    if not type(tMsg) == 'string' then tMsg = tostring(tMsg) end
    print(ADDON_PREFIX..tMsg)
    AppendToLogFile('log/log_warden.txt',ADDON_PREFIX..tMsg..'\n')
end
tPrint( 'Hello World!' )
tPrint('EXECUTING: addon_init.lua')

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

--load boss regist and ai files
loadModule( 'boss/boss_invoker' )