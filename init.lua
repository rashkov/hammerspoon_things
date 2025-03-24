hs.hotkey.bind({"cmd", "alt", "ctrl"}, "N", function()
    -- hs.notify.new({title = "Your Title3", informativeText = "Your message hereee"}):send()

    -- simulate hovering
    local clickX = 1565
    local clickY = 44

    print("Moving mouse to", clickX, clickY)
    hs.mouse.absolutePosition({x = clickX, y = clickY})
    hs.timer.usleep(1200000)  -- Short delay

    print("Moving mouse to", clickX + 1, clickY - 1)
    hs.mouse.absolutePosition({x = clickX + 1, y = clickY - 1})

    -- Give some time to see the output before clicking
    hs.timer.doAfter(0.1, function()
        -- hs.eventtap.leftClick({x = clickX, y = clickY})
        if isCloseButton(clickX, clickY) then
            hs.eventtap.leftClick({x = clickX, y = clickY})
        end
    end)
end)


local timer = nil
local toggleTimer = function()
    if timer then
        timer:stop()
        timer = nil
    else
        timer = hs.timer.new(1, printElement):start()
    end
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "M", toggleTimer)

function reloadDotHammerspoon()
    hs.reload()
    -- bring up hammerspoon console
    hs.application.launchOrFocus("Hammerspoon")
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", reloadDotHammerspoon)

-- hide hammerspoon console
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "H", function()
    local hammerspoon = hs.application.find("Hammerspoon")
    if hammerspoon then
        hammerspoon:hide()
    end
end)

function getApplicationName(element)
    local current = element
    local count = 0
    while current and count < 100 do
        if current:attributeValue("AXRole") == "AXApplication" then
            return current:attributeValue("AXTitle")
        end
        current = current:attributeValue("AXParent")
        count = count + 1
    end
    if count >= 100 then
        print("Warning: Reached maximum depth while searching for application name")
    end
    return nil
end

local function safeGetAttribute(element, attribute)
    local status, value = pcall(function() 
        return element:attributeValue(attribute)
    end)
    if status then
        return value
    else
        print(string.format("Error getting %s: %s", attribute, value))
        return nil
    end
end

local function printWithIndent(indent, ...)
    print(string.rep(" ", indent) .. ...)
end

function printElement(element, indent)
    print("\n")
    indent = indent or 0
    local screen = hs.screen.primaryScreen()
    local frame = screen:frame()
    local fullFrame = screen:fullFrame()
    local mousePos = hs.mouse.absolutePosition()

    -- Print everything we know about the widget under the mouse
    element = element or hs.axuielement.systemElementAtPosition(mousePos.x, mousePos.y)
    if not element then
        printWithIndent(indent, "No element found at position")
        return
    end

    -- Print each attribute separately with error handling
    local attributes = {
        {"Element", element},  -- Special case, just the element itself
        {"Application", "special_app"},  -- Special case for app name
        {"Role", "AXRole"},
        {"Subrole", "AXSubrole"},
        {"Identifier", "AXIdentifier"},
        {"Title", "AXTitle"},
        {"Description", "AXDescription"},
        {"Value", "AXValue"},
        {"Help", "AXHelp"},
        {"Parent", "AXParent"},
        {"Children", "AXChildren"},
        {"Window", "AXWindow"},
        {"Window Number", "AXWindowNumber"},
        {"Bundle Identifier", "AXBundleIdentifier"}
    }

    for _, attr in ipairs(attributes) do
        local label, key = attr[1], attr[2]
        if label == "Element" then
            printWithIndent(indent, string.format("Element: %s", tostring(element)))
        elseif label == "Application" then
            local appName = getApplicationName(element)
            if appName then
                printWithIndent(indent, string.format("Element Application: %s", appName))
            end
        elseif label == "Parent" then
            local parent = element:attributeValue("AXParent")
            if parent then
                printWithIndent(indent, string.format("Element Parent: %s", tostring(parent)))
                -- call printMousePosition on the parent but indent everything by 4 spaces
                printElement(parent, indent + 4)
            end
        else
            local value = safeGetAttribute(element, key)
            if value ~= nil and value ~= "" then
                printWithIndent(indent, string.format("%s: %s", label, tostring(value)))
            end
        end
    end
    print("\n")
end

-- print all windows on current desktop
function printAllWindowsOnCurrentDesktop()
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
end
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", printAllWindowsOnCurrentDesktop)

function isCloseButton(clickX, clickY)
    -- Check what's at the position
    local element = hs.axuielement.systemElementAtPosition(clickX, clickY)
    if not element then
        print("No UI element found at position")
        return false
    end

    ---- First check if it's a close button
    --local isClose = element:attributeValue("AXRole") == "AXButton" 
    --    and element:attributeValue("AXDescription") == "Close"

    --if not isClose then
    --    return false
    --end

    -- Check if it's in the notification hierarchy
    local parent = element:attributeValue("AXParent")
    while parent do
        local role = parent:attributeValue("AXRole")
        -- NotificationCenter's window should be at the top of our target hierarchy
        if role == "AXWindow" then
            local app = parent:attributeValue("AXParent")
            if app and app:attributeValue("AXRole") == "AXApplication" then
                -- We found the expected hierarchy
                -- print(app:attributeValue("AXTitle"), app:attributeValue("AXSubrole"), app:attributeValue("AXIdentifier"), app:attributeValue("AXRole"),
                --     app:attributeValue("AXIdentifier"),
                --     app:attributeValue("AXRole"),
                --     app:attributeValue("AXSubrole"),
                --     app:attributeValue("AXTitle"),
                -- )
                -- print whether the app is a notification
                -- return true if AXTitle partially matches "Notification" case insensitive
                print("title", app:attributeValue("AXTitle"))
                return string.find(app:attributeValue("AXTitle"), "Notification", 1, true) ~= nil
            end
        end
        parent = parent:attributeValue("AXParent")
    end
    
    return false
end

-- Function to recursively search for notification stack
local function findNotificationStack(element, role, subrole)
    if element:attributeValue("AXRole") == role and 
        element:attributeValue("AXSubrole") == subrole then
        return element
    end

    local children = element:attributeValue("AXChildren")
    if children then
        for _, child in ipairs(children) do
            local found = findNotificationStack(child, role, subrole)
            if found then return found end
        end
    end
    return nil
end

local function elementMatches(params)
    -- All parameters are optional
    local element = params.element
    if not element then return false end

    -- Check each attribute if specified
    local matches = true
    
    if params.role then
        matches = matches and safeGetAttribute(element, "AXRole") == params.role
    end
    
    if params.subrole then
        matches = matches and safeGetAttribute(element, "AXSubrole") == params.subrole
    end
    
    if params.identifier then
        local elementId = safeGetAttribute(element, "AXIdentifier")
        matches = matches and elementId and string.find(elementId, params.identifier, 1, true) ~= nil
    end
    
    if params.description then
        local elementDesc = safeGetAttribute(element, "AXDescription")
        matches = matches and elementDesc and string.find(elementDesc, params.description, 1, true) ~= nil
    end
    
    return matches
end

-- Function to recursively search for all elements with a given role and subrole
local function getAllElements(element, params)
    local elements = {}
    if elementMatches({ 
        element = element, 
        role = params.role,
        subrole = params.subrole,
        identifier = params.identifier,
        description = params.description
    }) then
        table.insert(elements, element)
    end
    
    local children = safeGetAttribute(element, "AXChildren")
    if children then
        for _, child in ipairs(children) do
            local found = getAllElements(child, params)
            for _, foundElement in ipairs(found) do
                table.insert(elements, foundElement)
            end
        end
    end
    return elements
end

local function getNotificationCenterAxElement()
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

local function waitFor(params)
    local ncElem = params.element
    local selector = params.selector
    local timeout = params.timeout or 2000000  -- 2 seconds default timeout
    local interval = params.interval or 200000  -- 200ms default polling interval

    -- poll for existence of element with role and subrole
    local elements = getAllElements(ncElem, selector)
    local elapsed = 0
    while #elements == 0 and elapsed < timeout do
        hs.timer.usleep(interval)
        elapsed = elapsed + interval
        elements = getAllElements(ncElem, selector)
    end
    return #elements > 0 and elements[1] or nil
end

local function expandAllNotificationStacks(ncElem)
    local notificationStacks = getAllElements(ncElem, {
        role = "AXGroup",
        subrole = "AXNotificationCenterAlertStack"
    })
    for _, stack in ipairs(notificationStacks) do
        print("Expanding notification stack")
        local frameCenterX = stack:attributeValue("AXFrame").x + stack:attributeValue("AXFrame").w / 2
        local frameCenterY = stack:attributeValue("AXFrame").y + stack:attributeValue("AXFrame").h / 2
        -- moveMouse(frameCenterX, frameCenterY, 2)
        hs.eventtap.leftClick({x = frameCenterX, y = frameCenterY})
    end
    if #notificationStacks == 0 then
        print("No notification stacks found")
        return
    end
    waitFor({
        element = ncElem,
        selector = {
            role = "AXHeading",
        },
        timeout = 5000000,  -- optional: 5 second timeout
        interval = 100000   -- optional: 100ms polling interval
    })
end

local function printAllNotificationAlerts(ncElem)
    local notificationAlerts = getAllElements(ncElem, {
        role = "AXGroup",
        subrole = "AXNotificationCenterAlert"
    })
    -- sort them from top to bottom
    table.sort(notificationAlerts, function(a, b)
        return a:attributeValue("AXFrame").y < b:attributeValue("AXFrame").y
    end)
    for _, alert in ipairs(notificationAlerts) do
        print(alert:attributeValue("AXDescription"))
    end
end

local function dismissTopNotification()
    local ncElem = getNotificationCenterAxElement()
    if not ncElem then
        print("Could not get accessibility element for Notification Center")
        return
    end
    expandAllNotificationStacks(ncElem)
    local notificationAlerts = getAllElements(ncElem, {
        role = "AXGroup",
        subrole = "AXNotificationCenterAlert"
    })
    if #notificationAlerts == 0 then
        print("No notifications to dismiss")
        return
    end
    -- sort them from top to bottom
    table.sort(notificationAlerts, function(a, b)
        return a:attributeValue("AXFrame").y < b:attributeValue("AXFrame").y
    end)
    local topAlert = notificationAlerts[1]
    hoverElement(topAlert)
    local closeButtonSelector = {
        role = "AXButton",
        identifier = "xmark",
        description = "Close"
    }
    local closeButton = waitFor({
        element = ncElem, -- close button lives under the notification center element, not the top alert
        selector = closeButtonSelector,
        timeout = 5000000,  -- optional: 5 second timeout
        interval = 100000   -- optional: 100ms polling interval
    })
    if not closeButton then
        print("No close button found")
        return
    end
    local closeButtonX = closeButton:attributeValue("AXFrame").x + closeButton:attributeValue("AXFrame").w / 2
    local closeButtonY = closeButton:attributeValue("AXFrame").y + closeButton:attributeValue("AXFrame").h / 2
    moveMouse(closeButtonX, closeButtonY, 2)
    hs.eventtap.leftClick({x = closeButtonX, y = closeButtonY})
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "X", function()
    local ncElem = getNotificationCenterAxElement()
    if not ncElem then
        print("Could not get accessibility element for Notification Center")
        return
    end

    expandAllNotificationStacks(ncElem)
    -- waitFor({
    --     element = ncElem,
    --     selector = {
    --         role = "AXHeading",
    --     },
    --     timeout = 5000000,  -- optional: 5 second timeout
    --     interval = 100000   -- optional: 100ms polling interval
    -- })
    printAllNotificationAlerts(ncElem)
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "SPACE", function()
    local ncElem = getNotificationCenterAxElement()
    if not ncElem then
        print("Could not get accessibility element for Notification Center")
        return
    end
    expandAllNotificationStacks(ncElem)
    dismissTopNotification()
end)

-- use eventtap to move mouse in a way that is recognized by the system as a natural user gesture
function moveMouse(targetX, targetY, steps)
    -- Get current mouse position
    local startPos = hs.mouse.absolutePosition()
    steps = steps or 2
    -- Create mouse movement event tap
    local mouseEvents = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(e)
        return false  -- Let events pass through
    end):start()

    -- Move mouse gradually with actual mouse events
    for i = 1, steps do
        local newX = startPos.x + ((targetX - startPos.x) * (i / steps))
        local newY = startPos.y + ((targetY - startPos.y) * (i / steps))
        
        -- Post a real mouse movement event
        hs.eventtap.event.newMouseEvent(
            hs.eventtap.event.types.mouseMoved,
            {x = newX, y = newY}
        ):post()
        
        -- hs.timer.usleep(20000)  -- 20ms delay between steps
    end

    -- Clean up event tap
    mouseEvents:stop()
    mouseEvents = nil
end

function hoverElement(element)
    local frameCenterX = element:attributeValue("AXFrame").x + element:attributeValue("AXFrame").w / 2
    local frameCenterY = element:attributeValue("AXFrame").y + element:attributeValue("AXFrame").h / 2
    moveMouse(frameCenterX, frameCenterY, 2)
end

