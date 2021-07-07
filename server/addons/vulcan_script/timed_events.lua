local M = {}

require('addons.vulcan_script.globals')

-- local modules = {
--     utilities = require('addons.vulcan_script.utilities')
-- }

local function AddEvent(execFunc, name, time, runOnce)
    -- modules.utilities.Log({level=G_LevelDebug}, string.format('Added event "%s"', name))

    G_TimedEvents[name] = {
        timer = time,
        nextUpdate = 0,
        execFunc = execFunc,
        runOnce = runOnce,
        ran = false,
        name = name,
        firstPass = true
    }
end

local function RemoveEvent(name)
    print('RemoveEvent() ' .. name)
    G_TimedEvents[name] = nil
    -- modules.utilities.Log({level=G_LevelDebug}, string.format('Deleted event "%s"', name))
end

-- local function Update()
--     for _, event in pairs(G_TimedEvents) do
--         if not event.ran then
--             if os.time() >= event.nextUpdate then
--                 event.nextUpdate = os.time() + event.timer

--                 if event.runOnce and event.firstPass then
--                     event.execFunc()
--                     RemoveEvent(event.name)
--                 elseif not event.runOnce then
--                     event.execFunc()
--                 end

--                 event.firstPass = true
--             end
--         end
--     end
-- end

local function Update()
    for _, event in pairs(G_TimedEvents) do
        if not event.ran then
            if os.time() >= event.nextUpdate then
                event.nextUpdate = os.time() + event.timer

                if event.runOnce then
                    if not event.firstPass then
                        event.ran = true

                        G_Try(function ()
                            event.execFunc()
                        end, function ()
                            RemoveEvent(event.name)
                            return
                        end)
                    else
                        event.firstPass = false
                    end

                    event.firstPass = false
                else
                    if not event.firstPass then
                        -- modules.utilities.Log({level=G_LevelDebug}, string.format('Executed event "%s"', event.name))
                        G_Try(function ()
                            event.execFunc()
                        end, function ()
                            RemoveEvent(event.name)
                            return
                        end)
                    else
                        event.firstPass = false
                    end
                end
            end
        end
    end
end

-- local function ReloadModules()
--     modules = G_ReloadModules(modules, 'timed_events.lua')
-- end

M.AddEvent = AddEvent
M.RemoveEvent = RemoveEvent
M.Update = Update

-- M.ReloadModules = ReloadModules

return M