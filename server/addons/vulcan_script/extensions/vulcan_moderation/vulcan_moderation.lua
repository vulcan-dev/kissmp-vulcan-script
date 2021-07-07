--[[
    Created by Daniel W (Vitex#1248)
]]

require('addons.vulcan_script.globals')

-- Local Variables --
local M = {}
local next_update = 0 -- used for events

local modules = {
    utilities = require('addons.vulcan_script.utilities'),
    moderation = require('addons.vulcan_script.extensions.vulcan_moderation.moderation'),
    timed_events = require('addons.vulcan_script.timed_events'),
    server = require('addons.vulcan_script.server'),

    cmd_moderation = require('addons.vulcan_script.extensions.vulcan_moderation.commands.cmd_moderation'),
    cmd_utilities = require('addons.vulcan_script.extensions.vulcan_moderation.commands.cmd_utilities'),
    cmd_fun = require('addons.vulcan_script.extensions.vulcan_moderation.commands.cmd_fun')
}

M.callbacks = {
    VK_PlayerConnect = function(client_id)
        local client = G_Clients[client_id]

        -- Check for new alias
        local alias_found = false
        local aliases = {}

        for k, alias in pairs(modules.utilities.GetKey(G_PlayersLocation, client.user:getSecret(), 'alias')) do
            aliases[k] = alias
            if alias == client.user:getName() then
                alias_found = true
            end
        end

        if not alias_found then
            table.insert( aliases, client.user:getName() )
            modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'alias', aliases)
        end

        -- Check if banned
        local ban = modules.moderation.IsBanned(client.user:getSecret())
        if ban.time ~= nil and ban.time > 0 then -- User is banned
            if ban.time <= os.time() then -- Unban the mf
                modules.utilities.Log({level=G_LevelDebug}, 'You have been unbanned')
                modules.moderation.removeBan(client.user:getSecret(), ban.name)
            else
                client.user:kick(string.format('You are banned from this server. Unban date: %s', os.date('%Y-%m-%d %H:%M:%S', ban.time)))
                modules.utilities.Log({level=G_LevelDebug}, string.format('You are banned from this server. Unban date: %s', os.date('%Y-%m-%d %H:%M:%S', ban.time)))
            end
        end

        --[[ Tell them to read the rules if they're new to the server ]]--
        if modules.utilities.GetKey(G_PlayersLocation, client.user:getSecret(), 'playtime') <= 0 then
            modules.server.SendChatMessage(client.user:getID(), 'Make sure to read the rules at /discord before continuing', modules.server.ColourSuccess)
        end
    end,

    VK_PlayerDisconnect = function(client)
        modules.utilities.Log({level=G_LevelInfo}, string.format('[Player] %s has Disconnected', client.user:getName()))
    end,

    VK_VehicleSpawn = function(vehicle_id, client_id)
        local vehicle = vehicles[vehicle_id]
        G_Clients[client_id].vehicleCount = G_Clients[client_id].vehicleCount + 1

        local can_drive = true
        local blacklist = modules.utilities.GetKey(G_BlacklistLocation)

        for k, v in pairs(blacklist) do
            if k == vehicle:getData():getName() then
                if type(v) == 'boolean' then
                    modules.server.DisplayDialogError(G_ErrorVehicleBlacklisted, G_Clients[client_id])
                    vehicle:remove()

                    G_Clients[client_id].vehicleCount = G_Clients[client_id].vehicleCount - 1
                    G_Clients[client_id].user:sendLua('commands.setFreeCamera()')
                    return
                elseif type(v) == 'table' then
                    for _, role in pairs(v) do
                        if not modules.moderation.HasRole(G_Clients[client_id], role) then
                            can_drive = false
                        else
                            can_drive = true
                        end
                    end
                end
            end
        end

        if can_drive then
            if vehicle then
                vehicle:sendLua(string.format('obj:setWind(%s,%s,%s)', modules.server.environmentWind.x, modules.server.environmentWind.y, modules.server.environmentWind.z))
            end
        
            if (vehicle:getData():getName() ~= 'unicycle') then
                modules.server.SendChatMessage(string.format('[Vulcan-Moderation] %s has spawned a %s', G_Clients[client_id].user:getName(), vehicle:getData():getName()), modules.server.ColourWarning)
            end

            G_Clients[client_id].vehicleCount = G_Clients[client_id].vehicleCount + 1
        else
            modules.server.DisplayDialogError(G_ErrorInvalidVehiclePermissions, G_Clients[client_id])
            vehicle:remove()
            
            G_Clients[client_id].vehicleCount = G_Clients[client_id].vehicleCount - 1
            G_Clients[client_id].user:sendLua('commands.setFreeCamera()')
        end
    end,

    VK_VehicleReset = function(vehicle_id, client_id)
        local ply = connections[client_id]
        local vehicle = vehicles[ply:getCurrentVehicle()]

        if vehicle then
            vehicle:sendLua(string.format('obj:setWind(%s,%s,%s)', modules.server.environmentWind.x, modules.server.environmentWind.y, modules.server.environmentWind.z))
        end
        return ""
    end,

    VK_OnStdIn = function(message)
        if string.sub(message, 1, 1) == '/' then
            local args = modules.utilities.ParseCommand(message, ' ')
            args[1] = args[1]:sub(2)

            local command = G_Commands[args[1]]

            if command then
                table.remove(args, 1)
                command.exec(modules.server.GetUser(1337).data, args)
            end
        end
    end,
    
    VK_Tick = function()
        if os.time() >= next_update then
            next_update = os.time() + 5
            
            for _, client in pairs(G_Clients) do
                if client.connected then
                    -- Playtime & Rules
                    if client.user:getID() ~= 1337 then
                        modules.utilities.EditKey(G_PlayersLocation, client.user:getSecret(), 'playtime', modules.utilities.GetKey(G_PlayersLocation, client.user:getSecret(), 'playtime') + 5)
                    end
                end
            end
        end
    end
}

local function ReloadModules()
    G_RemoveCommandTable(modules.cmd_moderation.commands)
    G_RemoveCommandTable(modules.cmd_utilities.commands)
    G_RemoveCommandTable(modules.cmd_fun.commands)

    modules.moderation.ReloadModules()

    modules.cmd_moderation.ReloadModules()
    modules.cmd_utilities.ReloadModules()
    modules.cmd_fun.ReloadModules()
    modules = G_ReloadModules(modules, 'vulcan_moderation.lua') -- IMPORTANT! This might have to go after all other modules have been reloaded

    G_AddCommandTable(modules.cmd_moderation.commands)
    G_AddCommandTable(modules.cmd_utilities.commands)
    G_AddCommandTable(modules.cmd_fun.commands)

end

M.callbacks = M.callbacks
M.ReloadModules = ReloadModules

return M