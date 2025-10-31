local accessibility = require('modules.accessibility')
local mouse = require('modules.mouse')

local M = {}

function M.getNotificationCenterAxElement()
    local ncApp = hs.application.get("com.apple.notificationcenterui")
    if not ncApp then
        print("Could not find Notification Center application")
        return
    end
    local ncElem = hs.axuielement.applicationElement(ncApp)
    if not ncElem then
        print("Could not get accessibility element for Notification Center")
        return
    end
    return ncElem
end

function M.expandAllNotificationStacks(ncElem)
    local notificationStacks = accessibility.getAllElements(ncElem, {
        role = "AXGroup",
        subrole = "AXNotificationCenterAlertStack"
    })
    for _, stack in ipairs(notificationStacks) do
        print("Expanding notification stack")
        local frameCenterX = stack:attributeValue("AXFrame").x + stack:attributeValue("AXFrame").w / 2
        local frameCenterY = stack:attributeValue("AXFrame").y + stack:attributeValue("AXFrame").h / 2
        hs.eventtap.leftClick({x = frameCenterX, y = frameCenterY})
    end
    if #notificationStacks == 0 then
        print("No notification stacks found")
        return
    end
    accessibility.waitFor({
        element = ncElem,
        selector = {
            role = "AXHeading",
        },
        timeout = 5000000,
        interval = 100000
    })
end

function M.printAllNotifications()
    local ncElem = M.getNotificationCenterAxElement()
    if not ncElem then return end

    M.expandAllNotificationStacks(ncElem)
    local notificationAlerts = accessibility.getAllElements(ncElem, {
        role = "AXGroup",
        subrole = "AXNotificationCenterAlert"
    })
    for _, alert in ipairs(notificationAlerts) do
        print(alert:attributeValue("AXDescription"))
    end
end

function M.dismissTopNotification()
    local ncElem = M.getNotificationCenterAxElement()
    if not ncElem then return end

    local originalMousePos = hs.mouse.absolutePosition()
    
    M.expandAllNotificationStacks(ncElem)
    local notificationAlerts = accessibility.getAllElements(ncElem, {
        role = "AXGroup",
        subrole = "AXNotificationCenterAlert"
    })
    if #notificationAlerts == 0 then
        print("No notifications to dismiss")
        return
    end

    table.sort(notificationAlerts, function(a, b)
        return a:attributeValue("AXFrame").y < b:attributeValue("AXFrame").y
    end)
    
    local topAlert = notificationAlerts[1]
    mouse.hoverElement(topAlert)
    
    local closeButton = accessibility.waitFor({
        element = ncElem,
        selector = {
            role = "AXButton",
            identifier = "xmark",
            description = "Close"
        },
        timeout = 5000000,
        interval = 100000
    })
    
    if not closeButton then
        print("No close button found")
        return
    end

    local frame = closeButton:attributeValue("AXFrame")
    local closeButtonX = frame.x + frame.w / 2
    local closeButtonY = frame.y + frame.h / 2
    mouse.moveMouse(closeButtonX, closeButtonY, 2)
    hs.eventtap.leftClick({x = closeButtonX, y = closeButtonY})
    hs.mouse.absolutePosition(originalMousePos)
end

function M.clearAllNotifications()
    local ncElem = M.getNotificationCenterAxElement()
    if not ncElem then return end

    local originalMousePos = hs.mouse.absolutePosition()

    -- First, expand any collapsed notification stacks
    M.expandAllNotificationStacks(ncElem)

    -- Find notification stacks (same as expandAllNotificationStacks uses)
    local notificationStacks = accessibility.getAllElements(ncElem, {
        role = "AXGroup",
        subrole = "AXNotificationCenterAlertStack"
    })

    -- If we have stacks, try to find and click the "Clear All" button
    if #notificationStacks > 0 then
        -- Sort by Y position to get the top stack
        table.sort(notificationStacks, function(a, b)
            return a:attributeValue("AXFrame").y < b:attributeValue("AXFrame").y
        end)

        -- Hover over the top stack
        local topStack = notificationStacks[1]
        mouse.hoverElement(topStack)

        local clearAllButton = accessibility.waitFor({
            element = ncElem,
            selector = {
                role = "AXButton",
                description = "Clear All"
            },
            timeout = 5000000,
            interval = 100000
        })

        if clearAllButton then
            print("Clicking Clear All button")
            local frame = clearAllButton:attributeValue("AXFrame")
            local buttonCenterX = frame.x + frame.w / 2
            local buttonCenterY = frame.y + frame.h / 2
            hs.eventtap.leftClick({x = buttonCenterX, y = buttonCenterY})
            hs.mouse.absolutePosition(originalMousePos)
            return
        end
    end

    -- No stacks or Clear All button not found, fall back to closing individual notifications
    print("Using individual close buttons")
    local notificationAlerts = accessibility.getAllElements(ncElem, {
        role = "AXGroup",
        subrole = "AXNotificationCenterAlert"
    })
    if #notificationAlerts == 0 then
        print("No notifications to dismiss")
        hs.mouse.absolutePosition(originalMousePos)
        return
    end

    -- Close notifications one by one, starting from the top
    while #notificationAlerts > 0 do
        table.sort(notificationAlerts, function(a, b)
            return a:attributeValue("AXFrame").y < b:attributeValue("AXFrame").y
        end)

        local topAlert = notificationAlerts[1]
        mouse.hoverElement(topAlert)

        local closeButton = accessibility.waitFor({
            element = ncElem,
            selector = {
                role = "AXButton",
                identifier = "xmark",
                description = "Close"
            },
            timeout = 5000000,
            interval = 100000
        })

        if not closeButton then
            print("No close button found for notification")
            break
        end

        local frame = closeButton:attributeValue("AXFrame")
        local closeButtonX = frame.x + frame.w / 2
        local closeButtonY = frame.y + frame.h / 2
        mouse.moveMouse(closeButtonX, closeButtonY, 2)
        hs.eventtap.leftClick({x = closeButtonX, y = closeButtonY})

        -- Wait a bit and refresh the notification list
        hs.timer.usleep(200000) -- 200ms delay
        notificationAlerts = accessibility.getAllElements(ncElem, {
            role = "AXGroup",
            subrole = "AXNotificationCenterAlert"
        })
    end

    hs.mouse.absolutePosition(originalMousePos)
end

return M
