--[[
    Created by Daniel W (Vitex#1248)
]]

require('addons.vulcan_script.globals')

--[[ Notes:
    If you plan on using this then I recommend you read the README's and the Extension.md (will update later on)
    If you find anything in here related to my Roleplay Extension then let me know so I can remove it.
    If you have any issues, please create a new issue here https://github.com/vulcan-dev/kissmp-vulcan-script/issues

    Command /dv needs fixing
]]

local modules = {
    utilities = require('addons.vulcan_script.utilities'),
    timed_events = require('addons.vulcan_script.timed_events'),
    server = require('addons.vulcan_script.server')
}

local extensions = {}
local nextUpdate = 0
local nextUpdate2 = 0
local prefix = '/'

-- [[ ==================== Hooking Start ==================== ]] --
hooks.register('OnPlayerConnected', 'VK_PLAYER_CONNECT', function(client_id)
    --[[ Add Client to Table ]]--
    modules.server.AddClient(client_id)
    local client = G_Clients[client_id]

    modules.utilities.Log({level=G_LevelInfo}, string.format("%s is connecting [ %s ]", client.user:getName(), client.user:getSecret()))

    --[[ Create new User Object if it doesn't exist ]]--
    if not modules.utilities.GetKey(G_PlayersLocation, client.user:getSecret(), 'rank', G_LevelError, true, true) then
        modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'rank', 0)
        modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'alias', {G_Clients[client_id].user:getName()})
        modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'warns', {})
        modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'bans', {})
        modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'vehicleLimit', 2)
        modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'mute_time', 0)
        modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'playtime', 0)

        modules.utilities.Log({level=G_LevelInfo}, string.format('Creating new user object for %s', client.user:getName()))
    end

    modules.server.IsConnected(client, client.user:getName(), function()
        --[[ Connected ]]--
        modules.utilities.Log({level=G_LevelInfo}, string.format("%s has connected", client.user:getName()))
        modules.server.DisplayDialog(client, string.format('%s has joined!', client.user:getName()), 3)

        --[[ Kick if Unknown (Specified in server.json) ]]
        if modules.utilities.GetKey(G_ServerLocation, 'options', 'kick_unknown') and client.user:getName() == 'Unknown' then
            client.user:kick('Please join back with a different name')
        end

        --[[ Set Time of Day ]]--
        client.user:sendLua(string.format('extensions.core_environment.setTimeOfDay({dayscale=%s,nightScale=%s,azimuthOverride=%s,dayLength=%s,time=%s,play=%s})',
            modules.server.environmentTime.dayscale,
            modules.server.environmentTime.nightScale,
            modules.server.environmentTime.azimuthOverride,
            modules.server.environmentTime.dayLength,
            modules.server.environmentTime.time,
            modules.server.environmentTime.play
        ))

        --[[ User Help ]]--
        modules.server.SendChatMessage(client.user:getID(), 'Use /help for a list of commands (only show for your rank)', modules.server.ColourSuccess)

        --[[ Load Extension Hook VK_PlayerConnect ]]--
        for _, extension in pairs(extensions) do
            if extension.callbacks.VK_PlayerConnect then
                extension.callbacks.VK_PlayerConnect(client_id)
            end
        end
    end)
end)

hooks.register('OnPlayerDisconnected', 'VK_PLAYER_DISCONNECT', function(client_id)
    local oldClient = G_Clients[client_id]
    G_Clients[client_id].connected = false
    modules.server.RemoveClient(client_id)

    modules.utilities.Log({level=G_LevelInfo}, string.format("%s has Disconnected [ %s ]", oldClient.user:getName(), oldClient.user:getSecret()))

    --[[ Load Extension Hook VK_PlayerDisconnect ]]--
    for _, extension in pairs(extensions) do
        if extension.callbacks.VK_PlayerDisconnect then
            extension.callbacks.VK_PlayerDisconnect(oldClient)
        end
    end

    oldClient = nil
end)

hooks.register('OnVehicleSpawned', 'VK_PLAYER_VEHICLE_SPAWN', function(vehicle_id, client_id)
    --[[ Load Extension Hook VK_VehicleSpawn ]]--
    for _, extension in pairs(extensions) do
        if extension.callbacks.VK_VehicleSpawn then
            extension.callbacks.VK_VehicleSpawn(vehicle_id, client_id)
        end
    end

    modules.utilities.Log({level=G_LevelDebug}, string.format('%s vehicle count: %d', G_Clients[client_id].user:getName(), G_Clients[client_id].vehicleCount))
end) -- Vehicle Spawned

hooks.register('OnVehicleRemoved', 'VK_PLAYER_VEHICLE_REMOVED', function(vehicle_id, client_id)
    --[[ Load Extension Hook VK_VehicleRemoved ]]--
    for _, extension in pairs(extensions) do
        if extension.callbacks.VK_VehicleRemoved then
            extension.callbacks.VK_VehicleRemoved(vehicle_id, client_id)
        end
    end
end)

hooks.register('OnVehicleResetted', 'VK_PLAYER_VEHICLE_RESET', function(vehicle_id, client_id)
    --[[ Load Extension Hook VK_VehicleReset ]]--
    for _, extension in pairs(extensions) do
        if extension.callbacks.VK_VehicleReset then
            extension.callbacks.VK_VehicleReset(vehicle_id, client_id)
        end
    end
end)

hooks.register('OnChat', 'VK_PLAYER_CHAT', function(client_id, message)
    local executor = G_Clients[client_id]

    --[[ Check if the Client is Muted ]]--
    local mute_time = modules.utilities.GetKey(G_PlayersLocation, executor.user:getSecret(), 'mute_time')
    if mute_time ~= nil and mute_time > 0 then
        if mute_time <= os.time() then
            modules.utilities.Log({level=G_LevelDebug}, 'You have been unmuted')
            modules.utilities.EditKey(G_PlayersLocation, executor.user:getSecret(), 'mute_time', 0)
        else
            modules.server.SendChatMessage(executor.user:getID(), 'You are muted', modules.server.ColourError)
            return ""
        end
    end

    --[[ Check if Command ]]
    modules.utilities.Log({level=G_LevelInfo}, string.format('%s said: %s', G_Clients[client_id].user:getName(), message))
    if string.sub(message, 1, 1) == prefix then
        local args = modules.utilities.ParseCommand(message, ' ')
        args[1] = args[1]:sub(2)

        local command = G_Commands[args[1]]

        if command then
            if executor.GetRank() >= command.rank then
                table.remove(args, 1)
                G_Try(function ()
                    command.exec(executor, args)
                end, function(err)
                    modules.server.SendChatMessage(executor.user:getID(), string.format('[ %s Failed. Please post it in bug-reports in /discord ]\nMessage: %s', message, err), modules.server.ColourError)
                    modules.utilities.Log({level=G_LevelError}, string.format('Command failed! User: %s\n  Message: %s', executor.user:getName(), err))
                    return ""
                end)
            end
        else
            modules.server.SendChatMessage(executor.user:getID(), 'Invalid Command, please use /help', modules.server.ColourWarning)
        end
    else
        modules.moderation.SendUserMessage(executor, message)
    end

    --[[ Load Extension Hook VK_OnMessageReceive ]]--
    for _, extension in pairs(extensions) do
        if extension.callbacks.VK_OnMessageReceive then
            extension.callbacks.VK_OnMessageReceive(client_id, message)
        end
    end

    return ""
end) -- OnChat

hooks.register('OnStdIn', 'VK_PLAYER_STDIN', function(input);
    --[[ Reload all Modules ]]--
    if input == '!rl' then
        G_ServerLocation = './addons/vulcan_script/settings/server.json'

        G_PlayersLocation = './addons/vulcan_script/settings/players.json'
        G_ColoursLocation = './addons/vulcan_script/settings/colours.json'

        modules = G_ReloadModules(modules, 'main.lua')

        --[[ Reload all Extensions & Modules ]]--
        extensions = G_ReloadExtensions(extensions)
        for _, v in pairs(extensions) do v.ReloadModules() end

        -- Load all extensions
        for _, v in pairs(modules.utilities.GetKey(G_ServerLocation, 'options', 'extensions')) do
            extensions[v] = G_Try(function()
                package.loaded[v] = nil
                return require(string.format('addons.vulcan_script.extensions.%s.%s', v, v))
            end, function()
                modules.utilities.Log({level=G_LevelFatal}, '[Extension] Failed Loading Extension: '..v)
            end)

            modules.utilities.Log({level=G_LevelDebug}, '[Extension] Reloaded Extension: '..v)
        end

        if G_Level < G_LevelDebug then modules.utilities.Log({level=G_LevelInfo}, 'Successfully reloaded all extensions and modules') end

    end

    for _, extension in pairs(extensions) do
        if extension.callbacks.VK_OnStdIn then
            extension.callbacks.VK_OnStdIn(input)
        end
    end
end)

hooks.register("Tick", "VK_TICK", function()
    modules.timed_events.Update()

    --[[ Garbage Debugging ]]--
    if os.time() > nextUpdate then
        nextUpdate = os.time() + 4
        modules.utilities.Log({level=G_LevelDebug}, string.format('Memory Usage: %.3f KB', collectgarbage('count')))
        collectgarbage("collect")
        collectgarbage("collect")
    end

    if os.time() > nextUpdate2 then
        nextUpdate2 = os.time() + 1200
        modules.server.SendChatMessage('[This server is using Vulcan-Moderation by Vitex#1248]', modules.server.ColourWarning)
    end

    -- Server uptime
    G_Uptime = G_Uptime + 1

    -- Update extension hook
    for _, extension in pairs(extensions) do
        if extension.callbacks.VK_Tick then
            extension.callbacks.VK_Tick(1 - 60)
        end
    end
end)
-- [[ ==================== Hooking End ==================== ]] --

local function Initialize()
    --[[ Make sure to change the log level if you don't want console spam :) ]]--
    G_Level = G_LevelDebug
    modules.utilities.Log({level=G_LevelInfo}, '[Server] Initialized')

    modules = G_ReloadModules(modules, 'main.lua')

    --[[ Load all Extensions ]]--
    for _, v in pairs(modules.utilities.GetKey(G_ServerLocation, 'options', 'extensions')) do
        extensions[v] = G_Try(function()
            return require(string.format('addons.vulcan_script.extensions.%s.%s', v, v))
        end, function()
            modules.utilities.Log({level=G_LevelFatal}, '[Extension] Failed Loading Extension: '..v)
        end)

        modules.utilities.Log({level=G_LevelDebug}, '[Extension] Loaded Extension: '..v)
    end

    --[[ Load all Extension Modules ]]--
    for _, v in pairs(extensions) do
        v.ReloadModules()
    end

    G_Verbose = modules.utilities.GetKey(G_ServerLocation, 'log', 'verbose')
    G_LogFile = modules.utilities.GetKey(G_ServerLocation, 'log', 'file')

    G_DiscordLink = modules.utilities.GetKey(G_ServerLocation, 'options', 'discord_link')
    G_PatreonLink = modules.utilities.GetKey(G_ServerLocation, 'options', 'patreon_link')

    prefix = modules.utilities.GetKey(G_ServerLocation, 'options', 'command_prefix')

    --[[ Set Colours ]]--
    modules.server.ColourSuccess = modules.utilities.GetColour(modules.utilities.GetKey(G_ColoursLocation, 'Success'))
    modules.server.ColourWarning = modules.utilities.GetColour(modules.utilities.GetKey(G_ColoursLocation, 'Warning'))
    modules.server.ColourError = modules.utilities.GetColour(modules.utilities.GetKey(G_ColoursLocation, 'Error'))

    --[[ Create Console ]]--
    G_Clients[1337] = modules.server.consolePlayer

    modules.moderation = require('addons.vulcan_script.extensions.vulcan_moderation.moderation')
end

Initialize()