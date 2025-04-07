local M = {}

function M.safeGetAttribute(element, attribute)
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

function M.elementMatches(params)
    local element = params.element
    if not element then return false end

    local matches = true
    
    if params.role then
        matches = matches and M.safeGetAttribute(element, "AXRole") == params.role
    end
    
    if params.subrole then
        matches = matches and M.safeGetAttribute(element, "AXSubrole") == params.subrole
    end
    
    if params.identifier then
        local elementId = M.safeGetAttribute(element, "AXIdentifier")
        matches = matches and elementId and string.find(elementId, params.identifier, 1, true) ~= nil
    end
    
    if params.description then
        local elementDesc = M.safeGetAttribute(element, "AXDescription")
        matches = matches and elementDesc and string.find(elementDesc, params.description, 1, true) ~= nil
    end
    
    return matches
end

function M.getAllElements(element, params)
    local elements = {}
    if M.elementMatches({ 
        element = element, 
        role = params.role,
        subrole = params.subrole,
        identifier = params.identifier,
        description = params.description
    }) then
        table.insert(elements, element)
    end
    
    local children = M.safeGetAttribute(element, "AXChildren")
    if children then
        for _, child in ipairs(children) do
            local found = M.getAllElements(child, params)
            for _, foundElement in ipairs(found) do
                table.insert(elements, foundElement)
            end
        end
    end
    return elements
end

function M.waitFor(params)
    local ncElem = params.element
    local selector = params.selector
    local timeout = params.timeout or 2000000
    local interval = params.interval or 200000

    local elements = M.getAllElements(ncElem, selector)
    local elapsed = 0
    while #elements == 0 and elapsed < timeout do
        hs.timer.usleep(interval)
        elapsed = elapsed + interval
        elements = M.getAllElements(ncElem, selector)
    end
    return #elements > 0 and elements[1] or nil
end

return M
