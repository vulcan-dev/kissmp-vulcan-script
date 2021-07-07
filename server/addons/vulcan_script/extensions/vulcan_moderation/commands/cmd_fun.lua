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
    --[[ Administator Commands ]]
    imitate = {
        rank = modules.moderation.RankAdmin,
        category = 'Moderation Fun',
        description = 'Imitates a user',
        usage = '/imitate <user> <message>',
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

            if not message then G_DiscordLink(executor.data, '[Error] No message specified') return end

            modules.moderation.SendUserMessage(client, message)
        end
    },

    set_gravity = {
        rank = modules.moderation.RankAdmin,
        category = 'Moderation Fun',
        description = 'Sets gravity for everyone or for a specific user',
        usage = '/set_gravity (user) <value>',
        exec = function(executor, args)
            local client = modules.server.GetUser(args[1])
            local gravity = (not client.success and args[1] or args[2]) or -9.81

            if not client.success then
                client = executor
            else
                client = client.data
            end

            if modules.utilities.IsNumber(gravity) then
                client.user:sendLua('core_environment.setGravity('..gravity..')')
                modules.server.DisplayDialog(client, '[Enviroment] Gravity set to ' .. gravity)
            else
                modules.server.DisplayDialogError(G_ErrorInvalidArguments, executor)
            end
        end
    },

    destroy = {
        rank = modules.moderation.RankAdmin,
        category = 'Moderation Fun',
        description = 'Destroys a users vehicle',
        usage = '/destroy <user>',
        exec = function(executor, args)

        end
    },
}

--[[ Reload Modules ]]
local function ReloadModules()
    modules = G_ReloadModules(modules, 'cmd_fun.lua')
end

--[[ Return ]]
M.ReloadModules = ReloadModules
M.commands = M.commands

return M