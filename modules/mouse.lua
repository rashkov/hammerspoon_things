local M = {}

function M.moveMouse(targetX, targetY, steps)
    local startPos = hs.mouse.absolutePosition()
    steps = steps or 2
    
    local mouseEvents = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(e)
        return false
    end):start()

    for i = 1, steps do
        local newX = startPos.x + ((targetX - startPos.x) * (i / steps))
        local newY = startPos.y + ((targetY - startPos.y) * (i / steps))
        
        hs.eventtap.event.newMouseEvent(
            hs.eventtap.event.types.mouseMoved,
            {x = newX, y = newY}
        ):post()
    end

    mouseEvents:stop()
    mouseEvents = nil
end

function M.hoverElement(element)
    local frame = element:attributeValue("AXFrame")
    local frameCenterX = frame.x + frame.w / 2
    local frameCenterY = frame.y + frame.h / 2
    M.moveMouse(frameCenterX, frameCenterY, 2)
end

return M
