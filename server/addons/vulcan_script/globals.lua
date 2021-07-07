--[[
    Created by Daniel W (Vitex#1248)
]]

package.path = ';?.lua;./addons/vulcan_script/?.lua;./addons/vulcan_script/extensions/vulcan_moderation/?.lua;./addons/vulcan_script/extensions/vulcan_moderation/commands/?.lua;./addons/vulcan_script/?.lua;' .. package.path

--[[ Clients and Player Count ]]--
G_Clients = {}
G_CurrentPlayers = 0

--[[ Logging Levels ]]--
G_LevelInfo = 1
G_LevelDebug = 2
G_LevelError = 3
G_LevelFatal = 4

G_LogLevel = {
    [G_LevelInfo] = 'Info',
    [G_LevelDebug] = 'Debug',
    [G_LevelError] = 'Error',
    [G_LevelFatal] = 'Fatal'
}

G_Level = G_LevelDebug

--[[ Verbose & Log File ]]--
G_Verbose = nil
G_LogFile = nil

--[[ Links ]]--
G_DiscordLink = ''
G_PatreonLink = ''

G_Uptime = 0
G_Cooldown = 0

G_TimedEvents = {}
G_Commands = {}

--[[ Utility Functions ]]--
function G_Try(f, catch_f)
    local result, exception = pcall(f)
    if not result then
        if catch_f then catch_f(exception) end
    end

    return exception
end

function G_ReloadModules(modules, filename)
    local utilities = require('addons.vulcan_script.utilities')
    filename = filename or ''

    for module_name, _ in pairs(modules) do
        package.loaded[module_name] = nil

        modules[module_name] = require(module_name)
        utilities.Log({level=G_LevelDebug}, string.format('[%s] [Module] Reloaded %s', filename, module_name))
    end

    return modules
end

function G_ReloadExtensions(extensions, filename)
    filename = filename or ''

    for ext, _ in pairs(extensions) do
        package.loaded[string.format('addons.vulcan_script.extensions.%s.%s', ext, ext)] = nil

        extensions[ext] = require(string.format('addons.vulcan_script.extensions.%s.%s', ext, ext))
    end

    return extensions
end

--[[ G_DisplayDialog Errors ]]--
G_ErrorInvalidUser = 0
G_ErrorInvalidArguments = 1
G_ErrorInvalidMessage = 2
G_ErrorVehicleBlacklisted = 3
G_ErrorInvalidVehiclePermissions = 4
G_ErrorInsufficentPermissions = 5
G_ErrorCannotPerformUser = 6
G_ErrorNotInVehicle = 7

G_Errors = {
    [G_ErrorInvalidUser] = 'Invalid User Specified',
    [G_ErrorInvalidArguments] = 'Invalid Arguments',
    [G_ErrorInvalidMessage] = 'Invalid Message Specified',
    [G_ErrorVehicleBlacklisted] = 'This Vehicle is Blacklisted',
    [G_ErrorInvalidVehiclePermissions] = 'You Do Not Have The Required Permissions to Drive This Vehicle',
    [G_ErrorInsufficentPermissions] = 'You Do Not Have The Required Permissions to Perform This Action',
    [G_ErrorCannotPerformUser] = 'You Do Not Have The Required Permissions to Perform This Action On This User',
    [G_ErrorNotInVehicle] = 'User is Not in a Vehicle'
}

--[[ Command Utilites ]]--
function G_AddCommandTable(table)
    for key, value in pairs(table) do
        G_Commands[key] = value
    end
end

function G_RemoveCommandTable(table)
    for key, _ in pairs(table) do
        G_Commands[key] = nil
    end
end