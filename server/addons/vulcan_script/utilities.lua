--[[
    Created by Daniel W (Vitex#1248)
]]

require('addons.vulcan_script.globals')

local M = {}

local modules = {
    timed_events = require('addons.vulcan_script.timed_events')
}

--[[ JSON Locations ]]--
G_ServerLocation = './addons/vulcan_script/settings/server.json'
G_PlayersLocation = './addons/vulcan_script/settings/players.json'
G_ColoursLocation = './addons/vulcan_script/settings/colours.json'
G_BlacklistLocation = './addons/vulcan_script/settings/blacklist.json'
G_Locations = './addons/vulcan_script/settings/locations.json'

--[[ Utility Functions ]]--
local function GetDateTime(format, time)
    format = format or '%Y-%m-%d %H:%M:%S'

    return os.date(format, time)
end

local function Log(named, ...)
    --[[ Check if arg level is > the set Level in initialize(). If not then don't send unless it's important like Error or Fatal ]]--
    if named.level and (named.level > G_Level) and named.level < G_LevelError then return end

    --[[ Maps the number to a string for outputting ]]--
    local level_str = G_LogLevel[named.level] or G_LogLevel[G_LevelInfo]

    local file = named.level or G_LogFile

    local args = {}

    --[[ Check if arg named exists, if not then assign args to arg named ]]--
    if type(named) == 'string' then
        if ... then
            args = {named .. ...}
        else
            args = {named}
        end
    else
        args = {...}
    end

    local str = ''

    --[[ Loop over each argument and convert them to a string ]]--
    for _, value in ipairs(args) do
        if value:sub(#value) ~= ' ' then str = str .. value .. ' ' --[[ No space found at end so add one ]]--
        else str = str .. value end -- ' ' --[[ Space found at end so don't add another ]]--
    end

    local output = string.format('[%s] [%s]: %s', level_str, GetDateTime(), str)

    --[[ Write to File ]]--
    if file then
        local f = io.open(string.format('./addons/vulcan_script/logs/%s.log', GetDateTime('%Y-%m-%d')), 'a+')

        --[[ Write to File if Exists ]]--
        if f then
            f:write(string.format('[%s] [%s]: %s\n', level_str, GetDateTime('%H:%M:%S'), str))
            f:close()
        else
            output = output .. '( ERROR: Could not write to file)'
        end
    end

    if level_str == G_LogLevel[G_LevelFatal] then
        --[[ Fatal Error, close server ]]--
        output = output .. '(Closing Server)'
        print(output)
        os.execute('pause')
        os.exit(1)
    else
        --[[ Print the message ]]--
        print(output)
    end
end

--[[ Utility Data ]]--
local function EditKey(filename, object, key, value, log_level)
    if not object then Log({level=G_LevelError}, 'Invalid object specified in EditKey') return end
    log_level = log_level or G_LevelError

    -- Read all contents from file
    local file = io.open(filename, 'r')
    local current_data = decode_json(file:read('*all'))
    file:close()

    -- Write contents back to file with edits
    if not current_data[object] then current_data[object] = {} end

    if object and key and value or type(value) == 'boolean' then
        current_data[object][key] = value
    else
        if object and not key and not value then
            current_data[object] = {}
        end
    end

    file = io.open(filename, 'w+')
    file:write(encode_json_pretty(current_data))
    file:close()
end

local function GetKey(filename, object, key, log_level, bypass, create)
    if object == 'secret_console' then return end

    log_level = log_level or G_LevelError
    bypass = bypass or false

    local file = G_Try(function()
        return io.open(filename, 'r');
    end, function()
        Log({level=G_LevelError}, string.format('Error opening "%s"', filename))
    end)

    local json_data = decode_json(file:read('*all'))

    file:close()

    if not object and not key then
        return json_data
    end

    if object and key then
        return G_Try(function()
            if create and not json_data[object] then
                EditKey(filename, object, {})
                return nil
            else
                return json_data[object][key]
            end
        end, function()
            if not bypass then
                Log({level=log_level}, string.format('Failed reading %s.%s from file "%s"', object, key, filename)) 
            end
        end)
    else
        if object and not key then
            return G_Try(function()
                return json_data[object]
            end, function()
                if not bypass then Log({level=log_level}, string.format('Failed reading %s from file "%s"', object, filename)) end
                return nil
            end)
        end
    end

    if json_data[object] ~= nil then
        if json_data[object] and not json_data[object][key] then
            return json_data[object]
        else
            if json_data[object][key] then
                return json_data[object][key]
            end
        end
    else
        return nil
    end
end

local function ParseCommand(cmd)
    local parts = {}
    local len = cmd:len()
    local escape_sequence_stack = 0
    local in_quotes = false

    local cur_part = ""
    for i = 1, len, 1 do
        local char = cmd:sub(i, i)
        if escape_sequence_stack > 0 then
            escape_sequence_stack = escape_sequence_stack + 1
        end
        local in_escape_sequence = escape_sequence_stack > 0
        if char == "\\" then
            escape_sequence_stack = 1
        elseif char == " " and not in_quotes then
            table.insert(parts, cur_part)
            cur_part = ""
        elseif char == '"' and not in_escape_sequence then
            in_quotes = not in_quotes
        else
            cur_part = cur_part .. char
        end
        if escape_sequence_stack > 1 then
            escape_sequence_stack = 0
        end
    end
    if cur_part:len() > 0 then
        table.insert(parts, cur_part)
    end
    return parts
end

local function StartsWith(string, start)
    return string.sub(string,1,string.len(start))==start
end

local function GetColour(colour)
    for key, value in pairs(colour) do -- Convert RGB uint8 to 0-1
        colour[key] = value / 255
    end

    return colour
end

local function IsNumber(sIn)
    return tonumber(sIn) ~= nil
end

local function ReloadModules()
    modules = G_ReloadModules(modules, 'utilities.lua')
end

M.Log = Log
M.GetDateTime = GetDateTime
M.IsNumber = IsNumber

M.ParseCommand = ParseCommand
M.GetKey = GetKey
M.EditKey = EditKey
M.GetColour = GetColour
M.StartsWith = StartsWith
M.ReloadModules = ReloadModules

return M