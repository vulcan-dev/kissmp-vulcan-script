local M = {}

local modules = {
    utilities = require('addons.vulcan_script.utilities'),
    timed_events = require('addons.vulcan_script.timed_events')
}

--[[ Colours ]]--
local ColourSuccess = modules.utilities.GetColour(modules.utilities.GetKey(G_ColoursLocation, 'Success'))
local ColourWarning = modules.utilities.GetColour(modules.utilities.GetKey(G_ColoursLocation, 'Warning'))
local ColourError = modules.utilities.GetColour(modules.utilities.GetKey(G_ColoursLocation, 'Error'))

--[[ Enviroment Variables ]]--
local environmentTime = {
    dayscale = 0.5,
    nightScale = 0.5,
    azimuthOverride = 0,
    dayLength = 1800,
    time = 0.80599999427795,
    play = false
}

local environmentWind = {
    x = 0,
    y = 0,
    z = 0
}

--[[ Player Tables ]]
local consolePlayer = {
    --[[ User Table ]]--
    user = {
        getID = function() return 1337 end,
        getName = function() return 'Console' end,
        getSecret = function() return 'secret_console' end,
        getCurrentVehicle = function() return nil end,
        sendChatMessage = function() end,
        kick = function() end,
        sendLua = function() end,
        getIpAddr = function() return nil end
    },

    --[[ Functions ]]--
    GetRank = function() return 7 end,

    --[[ Variables ]]--
    connected = true,
    blockList = {},
    mid = 1337,
}

local function AddClient(client_id)
    G_CurrentPlayers = G_CurrentPlayers + 1

    G_Clients[client_id] = {
        --[[ Userdata ]]--
        user = connections[client_id],

        --[[ Getters ]]--
        GetRank = function() return modules.utilities.GetKey(G_PlayersLocation, connections[client_id]:getSecret(), 'rank') end,

        --[[ Variables ]]--
        canExecute = true, -- for refueling, robbing and repairing so they can't run it twice at once
        vehicleCount = 0,

        blockList = {},
        home = { x = 693.57238769531, y = -44.622077941895, z = 52.016006469727, xr = 0.0019623863045126, yr = 0.0051850276067853, zr = 0.94506084918976, w = -0.32684752345085 },
        mid = G_CurrentPlayers,
        connected = false
    }

    modules.utilities.Log({level=G_LevelDebug}, 'Client added: ' .. G_Clients[client_id].user:getName())
end

local function RemoveClient(client_id)
    G_Clients[client_id] = nil
end

local function GetUser(user) -- ID, Name, Secret
    if not user then return {data=nil, success=false} end

    local utilities = require('addons.vulcan_script.utilities')

    for _, client in pairs(G_Clients) do
        if user == client.user:getName() then
            --[[ (In-Game) Client Name was Found ]]--
            modules.utilities.Log({level=G_LevelDebug}, 'modules.server.GetUser() Returning Name: ' .. user)
            return {data=client, success=true}
        else
            if tonumber(user) == client.mid then
                --[[ (In-Game) Client MID was Found ]]--
                modules.utilities.Log({level=G_LevelDebug}, 'modules.server.GetUser() Returning MID: ' .. tostring(user))
                return {data=client, success=true}
            else
                if tonumber(user) == client.user:getID() then
                    --[[ (In-Game) Client ID was Found ]]--
                    modules.utilities.Log({level=G_LevelDebug}, 'modules.server.GetUser() Returning ClientID: ' .. tostring(user))
                    return {data=client, success=true}
                else
                    if user == client.user:getSecret() then
                        --[[ (In-Game) Client Secret was Found ]]--
                        modules.utilities.Log({level=G_LevelDebug}, 'modules.server.GetUser() Returning Secret: ' .. tostring(user))
                        return {data=client, success=true}
                    end
                end
            end
        end
    end

    --[[ (Not In-Game) Get User by Client Secret ]]--
    if utilities.GetKey(G_PlayersLocation, user) then
        --[[ Secret was found, create fake data and return ]]--
        local data = {
            user = {
                getSecret = function() return user end,
                getName = function() return utilities.GetKey(G_PlayersLocation, user, 'alias')[1] end,
                sendChatMessage = function() end,
                getID = function() return nil end,
                sendLua = function() end,
                kick = function() end
            },

            blockList = {},
            GetRank = function() return utilities.GetKey(G_PlayersLocation, user, 'rank') end,
            GetRoles = function() return utilities.GetKey(G_PlayersLocation, user, 'roles') end,
            mid = -1
        }

        return {data=data, success=true}
    else
        for k, _ in pairs(utilities.GetKey(G_PlayersLocation)) do
            --[[ (Not In-Game) Get Client Alias ]]--

            if k ~= 'secret_console' then
                if user == utilities.GetKey(G_PlayersLocation, k, 'alias')[1] then
                    --[[ Alias has been found, create fake data and return ]]--
                    local data = {
                        user = {
                            getSecret = function() return k end,
                            getName = function() return utilities.GetKey(G_PlayersLocation, k, 'alias')[1] end,
                            sendChatMessage = function() end,
                            getID = function() return nil end,
                            sendLua = function() end
                        },

                        GetRank = function() return utilities.GetKey(G_PlayersLocation, k, 'rank') end,
                        GetRoles = function() return utilities.GetKey(G_PlayersLocation, k, 'roles') end,
                        mid = -1
                    }

                    return {data=data, success=true}
                end
            end
        end
    end

    return {data=nil, success=false}
end

local function GetUserKey(user, key)
    --[[ Check if Key is nil ]]--
    if not key then return end

    local utilities = require('addons.vulcan_script.utilities')

    for _, client in pairs(G_Clients) do
        --[[ Iterate Over All Clients ]]--

        if user == client.user:getSecret() then
            --[[ (In-Game) Client Secret Was Found ]]--
            return utilities.GetKey(G_PlayersLocation, client.user:getSecret(), key) -- in-game name
        else
            if tonumber(user) == client.mid then
                --[[ (In-Game) Client MID Was Found ]]
                return {data=client, success=true} -- mapped id
            else
                for secret, _ in pairs(utilities.GetKey(G_PlayersLocation)) do
                    --[[ Find an Alias of a Client (In-Game & Not In-Game) ]]--

                    for _, name in pairs(_) do
                        if type(name) == 'table' then
                            --[[ Alias Table ]]--

                            for a, b in pairs(name) do
                                --[[ Check if Alias is Equal to User ]]--

                                if a == 1 and user == b then
                                    --[[ Return Player Data ]]--
                                    return utilities.GetKey(G_PlayersLocation, secret, key)
                                end
                            end
                        else
                            if name == user then
                                --[[ No Alias ]]--
                                return utilities.GetKey(G_PlayersLocation, secret, key)
                            else
                                --[[ Nothing found?? Idk, returns secret I guess ]]--
                                return secret
                            end
                        end
                    end
                end
            end
        end
    end
end


local function LuaStrEscape(str, q)
    local escapeMap = {
        ["\n"] = [[\n]],
        ["\\"] = [[\]]
    }

    local qOther = nil
    if not q then
        q = "'"
    end
    if q == "'" then
        qOther = '"'
    end

    local serializedStr = q
    for i = 1, str:len(), 1 do
        local c = str:sub(i, i)
        if c == q then
            serializedStr = serializedStr .. q .. " .. " .. qOther .. c .. qOther .. " .. " .. q
        elseif escapeMap[c] then
            serializedStr = serializedStr .. escapeMap[c]
        else
            serializedStr = serializedStr .. c
        end
    end
    serializedStr = serializedStr .. q
    return serializedStr
end

local vch = {}

local function IsConnected(client, name, exec)
    local vehicle_id = connections[client.user:getID()]:getCurrentVehicle() or nil
    local vehicle = vehicles[vehicle_id] or nil
    vch[name] = {
        vehicle_id = vehicle_id,
        vehicle = vehicle
    }

    modules.timed_events.AddEvent(function()
        if not vch[name].vehicle then
            if connections[client.user:getID()] then
                vch[name].vehicle_id = connections[client.user:getID()]:getCurrentVehicle() or nil
                vch[name].vehicle = vehicles[vch[name].vehicle_id] or nil
            end
        else
            client.connected = true
            exec()

            modules.timed_events.RemoveEvent(name)
        end

    end, name, 2, false)
end

--[[ Game Functions ]]--
local function DisplayDialog(error, client, message, time)
    --[[ Check if we're using normal modules.server.DisplayDialog() or modules.server.DisplayDialogError() ]]
    if not G_Errors[error] then
        time = message
        message = client
        client = error
        error = nil
    end

    time = time or 3

    if client.user then
        --[[ Send to One Client ]]--
        client.user:sendLua(string.format("ui_message('%s', %s)", message, time))
    else
        --[[ Send to All Clients ]]--
        for _, c in pairs(G_Clients) do
            c.user:sendLua(string.format("ui_message('%s', %s)", message, time))
        end
    end
end

local function DisplayDialogError(error, client, time)
    if G_Errors[error] then
        DisplayDialog(error, client, G_Errors[error], time)
    end
end

local function SendChatMessage(client_id, message, colour)
    --if G_CurrentPlayers == 1 then return end --[[ Don't Send Anything to Prevent Spam ]]--

    modules.utilities.Log({level=G_LevelDebug}, string.format('Sending Message (client_id, msg, colour): %s %s %s', client_id or nil, message or nil, colour or nil))
    --[[ Check if Client is Valid ]]--
    if not G_Clients[client_id] then
        colour = message
        message = client_id
    end

    --[[ Check if Colour is Valid ]]--
    if type(colour) ~= 'table' then colour = {} end
    colour.r = colour.r or 1
    colour.g = colour.g or 1
    colour.b = colour.b or 1

    local canSend = true

    --[[ Send to All Because Client is nil ]]--
    if not G_Clients[client_id] then
        message = client_id

        for _, client in pairs(G_Clients) do
            for i = 1, #client.blockList do
                --[[ Loop over the client's block list ]]--

                if client.user:getID() == client.blockList[i] then
                    --[[ Client has been blocked so don't send ]]--
                    canSend = false
                else
                    --[[ Client has not been blocked so send ]]--
                    canSend = true
                end
            end

            --[[ Send Message to All Clients ]]--
            if canSend then
                client.user:sendLua('extensions.kissui.add_message(' .. LuaStrEscape(message) .. ', {r=' ..
                tostring(colour.r) .. ",g=" .. tostring(colour.g) .. ",b=" ..
                tostring(colour.b) .. ",a=1})")
            end
        end
    else
        --[[ Send to One Because Client is Valid ]]--
        for i = 1, #G_Clients[client_id].blockList do
            --[[ Loop over the client's block list ]]--

            if G_Clients[client_id].user:getID() == G_Clients[client_id].blockList[i] then
                --[[ Client has been blocked so don't send ]]--
                canSend = false
            else
                --[[ Client has not been blocked so send ]]--
                canSend = true
            end
        end

        --[[ Send Message to Client ]]--
        if canSend then
            G_Clients[client_id].user:sendLua('extensions.kissui.add_message(' .. LuaStrEscape(message) .. ', {r=' ..
                tostring(colour.r) .. ",g=" .. tostring(colour.g) .. ",b=" ..
                tostring(colour.b) .. ",a=1})")

            canSend = false
        end
    end
end

--[[ Utility Functions ]]--
local function ReloadModules()
    modules = G_ReloadModules(modules, 'server.lua')
end

--[[ Colour Variables ]]--
M.ColourSuccess = ColourSuccess
M.ColourWarning = ColourWarning
M.ColourError = ColourError

--[[ Enviroment Variables ]]--
M.environmentTime = environmentTime
M.environmentWind = environmentWind

--[[ Player Functions & Variables ]]--
M.consolePlayer = consolePlayer
M.AddClient = AddClient
M.RemoveClient = RemoveClient
M.GetUser = GetUser
M.GetUserKey = GetUserKey
M.IsConnected = IsConnected

M.SendChatMessage = SendChatMessage
M.DisplayDialog = DisplayDialog
M.DisplayDialogError = DisplayDialogError

--[[ Utility Functions ]]--
M.ReloadModules = ReloadModules

return M