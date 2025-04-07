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