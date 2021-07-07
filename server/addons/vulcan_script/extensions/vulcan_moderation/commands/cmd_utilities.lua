--[[
    Created by Daniel W (Vitex#1248)
]]

require('addons.vulcan_script.globals')

local M = {}

local modules = {
    utilities = require('addons.vulcan_script.utilities'),
    moderation = require('addons.vulcan_script.extensions.vulcan_moderation.moderation'),
    server = require('addons.vulcan_script.server')
}

M.commands = {
    -- Owner Commands
    advertise = {
        rank = modules.moderation.RankOwner,
        category = 'Moderation Utilities',
        description = 'Sends a message to chat without any user',
        usage = '/advertise <message>',
        exec = function(executor, args)
            local message = ''
            for k, v in pairs(args) do
                message = message .. v .. ' '
            end

            -- Check if message is valid
            if not message or not args[1] then modules.server.DisplayDialogError(G_ErrorInvalidMessage, executor) return end

            modules.server.SendChatMessage('[Advertisement] ' .. tostring(message))
        end
    },

    say = {
        rank = modules.moderation.RankOwner,
        category = 'Moderation Utilities',
        description = 'Sends a message to chat without any user',
        usage = '/say <message>',
        exec = function(executor, args)
            local message = args[1] or nil

            if not message then modules.server.DisplayDialogError(G_ErrorInvalidMessage, executor) return end
            modules.server.SendChatMessage('[Console]: ' .. tostring(message))
        end
    },

    -- Admin Commands
    time_play = {
        rank = modules.moderation.RankAdmin,
        category = 'Moderation Utilities',
        description = 'Plays the time',
        usage = '/time_play',
        exec = function(executor, args)
            modules.server.environmentTime.play = true

            for _, client in pairs(G_Clients) do
                client.user:sendLua('extensions.core_environment.setTimeOfDay({time='..modules.server.environmentTime.time..',play='..tostring(modules.server.environmentTime.play)..'})')
                modules.server.DisplayDialog(client, '[Enviroment] Time is playing')
            end
        end
    },

    time_stop = {
        rank = modules.moderation.RankAdmin,
        category = 'Moderation Utilities',
        description = 'Stops the time',
        usage = '/time_stop',
        exec = function(executor, args)
            modules.server.environmentTime.play = false

            for _, client in pairs(G_Clients) do
                client.user:sendLua('extensions.core_environment.setTimeOfDay({time='..modules.server.environmentTime.time..',play='..tostring(modules.server.environmentTime.play)..'})')
                modules.server.DisplayDialog(client, '[Enviroment] Time is not playing')
            end
        end
    },

    set_temp = {
        rank = modules.moderation.RankAdmin,
        category = 'Moderation Utilities',
        description = 'Sets the environment temperature',
        usage = '/set_temp <temp_c>',
        exec = function(executor, args)
            args[1] = args[1] or 0

            for _, client in pairs(G_Clients) do
                client.user:sendLua('extensions.core_environment.setTimeOfDay({time='..modules.server.environmentTime.time..',play=false})')
                modules.server.DisplayDialog(client.data, '[Enviroment] Set temperature to ' .. args[1])
            end
        end
    },

    set_wind = {
        rank = modules.moderation.RankAdmin,
        category = 'Moderation Utilities',
        description = 'Sets the environment temperature',
        usage = '/set_wind (user) (speed_x) (speed_y) (speed_z)',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1])
            local speed_x = (not client.success and args[1] or args[2]) or 0
            local speed_y = (not client.success and args[2] or args[3]) or 0
            local speed_z = (not client.success and args[3] or args[4]) or 0

            modules.server.environmentWind.x = speed_x
            modules.server.environmentWind.y = speed_y
            modules.server.environmentWind.z = speed_z

            if not client.success then
                for _, c in pairs(G_Clients) do
                    if connections[c.user:getID()] then
                        local ply = connections[c.user:getID()]
                        local vehicle = vehicles[ply:getCurrentVehicle()]

                        if vehicle then
                            vehicle:sendLua(string.format('obj:setWind(%s,%s,%s)', speed_x, speed_y, speed_x))
                        end

                        modules.server.DisplayDialog(c.data, string.format('[Enviroment] Set wind speed to %s, %s, %s', speed_x, speed_y, speed_z))
                        return
                    end
                end
            else
                client = client.data

                local ply = connections[client.user:getID()]
                local vehicle = vehicles[ply:getCurrentVehicle()]

                if vehicle then
                    vehicle:sendLua(string.format('obj:setWind(%s,%s,%s)', speed_x, speed_y, speed_x))
                end

                modules.server.DisplayDialog(client.data, string.format('[Enviroment] Set wind speed to %s, %s, %s', speed_x, speed_y, speed_z))
            end
        end
    },

    -- Moderator Commands
    set_time = { -- Store in variable as well so when someone joins it sets their time
        rank = modules.moderation.RankModerator,
        category = 'Moderation Utilities',
        description = 'Sets the time for everyone',
        usage = '/set_time <hh:mm:ss>',
        exec = function(executor, args)
            if not args[1] then modules.server.DisplayDialogError(G_ErrorInvalidArguments, executor) return end
            local time_args = {}

            local i = 1
            for token in string.gmatch(args[1], "[^:]+") do
                time_args[i] = token

                i = i + 1
            end

            if not modules.utilities.IsNumber(time_args[1]) then modules.server.DisplayDialogError(G_ErrorInvalidArguments, executor) return end

            time_args[1] = time_args[1] or 0

            if not time_args[1] then time_args[1] = args[1] end

            time_args[2] = time_args[2] or 0
            time_args[3] = time_args[3] or 0

            local time = (((time_args[1] * 3600 + time_args[2] * 60 + time_args[3]) / 86400) + 0.5) % 1
            modules.server.environmentTime.time = time

            for _, client in pairs(G_Clients) do
                client.user:sendLua('extensions.core_environment.setTimeOfDay({time = '..time..'})')
                modules.server.DisplayDialog(client, string.format('[Enviroment] Set time to %s', args[1]))
            end
        end
    },

    set_fog = {
        rank = modules.moderation.RankModerator,
        category = 'Moderation Utilities',
        description = 'Sets the fog level',
        usage = '/set_fog (client) <value>',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1])
            local fog = (not client.success and args[1] or args[2]) or 0

            if not tonumber(fog) then modules.server.DisplayDialogError(G_ErrorInvalidArguments, executor) return end

            if not client.success or not modules.server.GetUserKey(client.data, 'rank') then
                fog = args[1]
                for _, c in pairs(G_Clients) do
                    c.user:sendLua('extensions.core_environment.setFogDensity('..fog..')')
                    modules.server.DisplayDialog(c, string.format('[Enviroment] Set fog density to %s', fog))
                end
            else
                client = client.data
                client.user:sendLua('extensions.core_environment.setFogDensity('..fog..')')
                modules.server.DisplayDialog(client, string.format('[Enviroment] Set fog density to %s', fog))
            end
        end
    },

    -- Trusted Commands
    tp = {
        rank = modules.moderation.RankTrusted,
        category = 'Moderation Utilities',
        description = 'Teleports you to user or user to other user',
        usage = '/tp <user> (user2)',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1]) or nil
            local client2 = modules.server.GetUser(args[2]) or nil

            -- Check if the client exists
            if not client.success or not modules.server.GetUserKey(client.data, 'rank') then modules.server.DisplayDialogError(G_ErrorInvalidUser, executor) return end
            client = client.data

            -- TODO: When user is TP'd send lua to recover their car to avoid going inside eachother

            if not client2.success then
                local ply = connections[executor.user:getID()]
                local my_vehicle = vehicles[ply:getCurrentVehicle()]

                local their_ply = connections[client.user:getID()]
                local their_vehicle = vehicles[their_ply:getCurrentVehicle()]

                if not their_vehicle then
                    modules.server.DisplayDialogError(G_ErrorNotInVehicle, client)
                    return
                end

                local position = their_vehicle:getTransform():getPosition()
                local rotation = their_vehicle:getTransform():getRotation()
                my_vehicle:setPositionRotation(position[1]+3, position[2], position[3], rotation[1], rotation[2], rotation[3], rotation[4])

                modules.server.DisplayDialog(executor, 'Successfully teleported to ' .. client.user:getName())
            else
                -- Teleport client to client2
                client2 = client2.data

                local ply1 = connections[client.user:getID()]
                local vehicle1 = vehicles[ply1:getCurrentVehicle()]

                local ply2 = connections[client2.user:getID()]
                local vehicle2 = vehicles[ply2:getCurrentVehicle()]

                if not vehicle1 or not vehicle2 then
                    modules.server.DisplayDialogError(G_ErrorNotInVehicle, executor)
                    return
                end

                local position = vehicle2:getTransform():getPosition()
                local rotation = vehicle2:getTransform():getRotation()
                vehicle1:setPositionRotation(position[1]+3, position[2], position[3], rotation[1], rotation[2], rotation[3], rotation[4])

                modules.server.DisplayDialog(executor, string.format('Successfully teleported %s to %s', client.user:getName(), client2.user:getName()))
            end

            client.user:sendLua('recovery.startRecovering() recovery.stopRecovering()')
        end
    },

    -- User Commands (You might want to remove "- 4. Roleplay Utilities")
    help = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Displays all commands',
        usage = '/help (command) (category)',
        exec = function(executor, args)
            local search = args[1]

            if not search then
                modules.server.SendChatMessage(executor.user:getID(), [[
Try /help category or /help commandName.
Categories:
    - 1. Moderation
    - 2. Moderation Utilities
    - 3. Moderation Fun
                ]], modules.server.ColourWarning)

                return
            end

            local count = 0
            if G_Commands[search] ~= nil then
                local command = G_Commands[search]
                if executor.GetRank() >= command.rank and command.description and command.usage then
                    modules.server.SendChatMessage(executor.user:getID(),
                        'Description: ' .. command.description ..
                        '\nUsage: ' .. command.usage .. '\n\n'
                    )
                else
                    modules.server.SendChatMessage(executor.user:getID(), 'You are unable to view this command', modules.server.ColourError)
                    return
                end
            else
                for name, command in pairs(G_Commands) do
                    if command and command.description and command.category and command.usage and name ~= 'reloadModules' then
                        if executor.GetRank() >= command.rank then
                            if tonumber(search) == 1 then
                                -- Moderation
                                if command.category == 'Moderation' then
                                    modules.server.SendChatMessage(executor.user:getID(),
                                        'Command: /' .. name ..
                                        '\nDescription: ' .. command.description ..
                                        '\nUsage: ' .. command.usage .. '\n\n'
                                    )
                                    count = count + 1
                                end
                            elseif tonumber(search) == 2 then
                                -- mod utils
                                if command.category == 'Moderation Utilities' then
                                    modules.server.SendChatMessage(executor.user:getID(),
                                        'Command: /' .. name ..
                                        '\nDescription: ' .. command.description ..
                                        '\nUsage: ' .. command.usage .. '\n\n'
                                    )
                                    count = count + 1
                                end
                            elseif tonumber(search) == 3 then
                                -- mod fun
                                if command.category == 'Moderation Fun' then
                                    modules.server.SendChatMessage(executor.user:getID(),
                                        'Command: /' .. name ..
                                        '\nDescription: ' .. command.description ..
                                        '\nUsage: ' .. command.usage .. '\n\n'
                                    )

                                    count = count + 1
                                end
                            else
                                modules.server.SendChatMessage(executor.user:getID(), 'Invalid page', modules.server.ColourError)
                                return
                            end
                        end
                    end
                end
                
                if count == 0 then
                    modules.server.SendChatMessage(executor.user:getID(), 'Nothing has shown because you do not have the required rank to view these commands', modules.server.ColourError)
                end
            end
        end
    },

    uptime = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Displays server uptime',
        usage = '/uptime',
        exec = function(executor, args)
            modules.server.SendChatMessage(executor.user:getID(), 'Server Uptime: ' .. modules.utilities.GetDateTime('%H:%M:%S', G_Uptime), modules.server.ColourSuccess)
        end
    },

    playtime = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Displays playtime',
        usage = '/playtime (user)',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1])
            local message = 'Playtime: '

            if not client.success then
                client = executor
            else
                client = client.data
                message = client.user:getName() .. '\'s playtime: '
            end

            modules.server.SendChatMessage(executor.user:getID(), message .. modules.utilities.GetDateTime('%H:%M:%S', modules.utilities.GetKey(G_PlayersLocation, client.user:getSecret(), 'playtime')), modules.server.ColourSuccess)
        end
    },

    mods = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Displays active moderators',
        usage = '/mods',
        exec = function(executor, args)
            for _, client in pairs(G_Clients) do
                if modules.utilities.GetKey(G_PlayersLocation, client.user:getSecret(), 'rank') > modules.moderation.RankVIP then
                    if executor.user:getSecret() ~= 'secret_console' then
                        modules.server.SendChatMessage(executor.user:getID(), client.user:getName())
                    end
                end
            end
        end
    },

    discord = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Displays the discord server',
        usage = '/discord',
        exec = function(executor, args)
            executor.user:sendLua("openWebBrowser('"..G_DiscordLink.."')");
        end
    },

    pm = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Send a user a private message',
        usage = '/pm <user> <message>',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1])

            -- Check if the client exists
            if not client.success or not modules.server.GetUserKey(client.data, 'rank') then modules.server.DisplayDialogError(G_ErrorInvalidUser, executor) return end
            client = client.data

            table.remove(args, 1)

            local message = ''
            for _, v in pairs(args) do
                message = message .. v .. ' '
            end

            -- Check if message is valid
            if not message or not args[1] then modules.server.DisplayDialogError(G_ErrorInvalidMessage, executor) return end

            modules.server.SendChatMessage(executor.user:getID(), string.format('you -> %s: %s', client.user:getName(), message))
            modules.server.SendChatMessage(client.user:getID(), string.format('%s -> you: %s', executor.user:getName(), message))
        end
    },

    block = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Blocks a user',
        usage = '/block <user>',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1])

            -- Check if the client exists
            if not client.success or not modules.server.GetUserKey(client.data, 'rank') then modules.server.DisplayDialogError(G_ErrorInvalidUser, executor) return end
            client = client.data

            if client.GetRank() <= modules.moderation.RankVIP then
                for i = 1, #executor.blockList do
                    if client.user:getID() == executor.blockList[i] then
                        modules.server.DisplayDialog(executor, '[Error] User is already blocked')
                    else
                        table.insert( executor.blockList, client.user:getID() )
                        modules.server.DisplayDialog(executor, 'Successfully blocked user')
                    end
                end

                return
            end

            modules.server.DisplayDialog(executor, '[Error] Unable to block a staff member')
        end
    },

    unblock = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Unblocks a user',
        usage = '/unblock <user>',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1])

            -- Check if the client exists
            if not client.success or not modules.server.GetUserKey(client.data, 'rank') then modules.server.DisplayDialogError(G_ErrorInvalidUser, executor) return end
            client = client.data

            for i = 0, #executor.blockList do
                if client.user:getID() == executor.blockList[i] then
                    table.remove( executor.blockList, i )
                else
                    modules.server.DisplayDialog(executor, '[Error] User is not blocked')
                end
            end

            modules.server.DisplayDialog(executor, 'Successfully unblocked user')
        end
    },

    get_blocks = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilties',
        description = 'Lists all blocked users',
        usage = '/get_blocks',
        exec = function(executor, args)
            local j = 1
            for i=1, #executor.blockList do
                local client = modules.server.GetUser(executor.blockList[i])
                if client.success then
                    modules.server.SendChatMessage(executor.user:getID(), client.data.user:getName())
                end

                j = i
            end

            if j <= 1 then
                modules.server.SendChatMessage(executor.user:getID(), '[You have not blocked anyone]', modules.server.ColourWarning)
            end
        end
    },

    votekick = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Votekick a user',
        usage = '/votekick <user>',
        exec = function(executor, args)

        end
    },

    donate = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Displays patreon link',
        usage = '/donate',
        exec = function(executor, args)
            modules.server.SendChatMessage(executor.user:getID(), 'Patreon URL: patreon.com/'..G_PatreonLink, modules.server.ColourSuccess)
        end
    },

    dv = {
        rank = modules.moderation.RankUser,
        category = 'Moderation Utilities',
        description = 'Deletes current vehicle',
        usage = '/dv (user)',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1])

           --[[ Check if a client has been passed through ]]--
            if client.success then
                client = client.data
                if client.GetRank() > modules.moderation.RankVIP then
                    --[[ Delete clients vehicle ]]--
                    local ply = connections[client.user:getID()]
                    local vehicle = vehicles[ply:getCurrentVehicle()]

                    vehicle:remove()

                    client.vehicleCount = client.vehicleCount - 1
                    client.user:sendLua('commands.setFreeCamera()')

                    modules.server.DisplayDialog(executor, 'Successfully removed clients vehicle')
                else
                    modules.server.DisplayDialogError(G_ErrorInsufficentPermissions, executor)
                end
            else
                --[[ Delete executors vehicle ]]--
                local ply = connections[executor.user:getID()]
                local vehicle = vehicles[ply:getCurrentVehicle()]

                vehicle:remove()

                client.vehicleCount = client.vehicleCount - 1
                executor.user:sendLua('commands.setFreeCamera()')
            end
        end
    },
}

local function ReloadModules()
    modules = G_ReloadModules(modules, 'cmd_utilities.lua')
end

M.ReloadModules = ReloadModules
M.commands = M.commands

return M