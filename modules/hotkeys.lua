local M = {}

function M.init()
    -- Reload configuration
    hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
        hs.reload()
        hs.application.launchOrFocus("Hammerspoon")
    end)

    -- Hide Hammerspoon console
    hs.hotkey.bind({"cmd", "alt", "ctrl"}, "H", function()
        local hammerspoon = hs.application.find("Hammerspoon")
        if hammerspoon then
            hammerspoon:hide()
        end
    end)

    -- Print windows
    hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
        local windows = hs.window.visibleWindows()
        print("\n-------- Visible Windows --------")
        for _, window in ipairs(windows) do
            local app = window:application()
            local appName = app and app:name() or "Unknown"
            local frame = window:frame()
            print(string.format("%s - %s [x:%.0f y:%.0f w:%.0f h:%.0f]", 
                appName, 
                window:title(), 
                frame.x, frame.y, frame.w, frame.h))
        end
        print("")
    end)

    -- Notification hotkeys
    hs.hotkey.bind({"cmd", "alt", "ctrl"}, "X", function()
        local notifications = require('modules.notifications')
        notifications.printAllNotifications()
    end)

    -- hs.hotkey.bind({"cmd", "alt", "ctrl", "fn"}, "SPACE", function()
    --     print("Clearing one notification")
    --     local notifications = require('modules.notifications')
    --     notifications.dismissTopNotification()
    -- end)

    -- Clear all notifications
    hs.hotkey.bind({"cmd", "alt", "ctrl"}, "space", function()
        print("Clearing all notifications")
        local notifications = require('modules.notifications')
        notifications.clearAllNotifications()
    end)
end

return M
