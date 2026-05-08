local Tokenizer = require("source/tokenizer")
local Parser = {}

-- Helper function to parse hex color to RGB
local function hexToRgb(hex_color)
    -- Remove '#' prefix
    local hex = hex_color:sub(2)
    
    if #hex == 6 then
        -- RGB format
        local r = tonumber(hex:sub(1,2), 16) / 255
        local g = tonumber(hex:sub(3,4), 16) / 255
        local b = tonumber(hex:sub(5,6), 16) / 255
        return {r, g, b, 1}
    elseif #hex == 8 then
        -- RGBA format
        local r = tonumber(hex:sub(1,2), 16) / 255
        local g = tonumber(hex:sub(3,4), 16) / 255
        local b = tonumber(hex:sub(5,6), 16) / 255
        local a = tonumber(hex:sub(7,8), 16) / 255
        return {r, g, b, a}
    else
        return nil -- Invalid color
    end
end

-- Helper function to parse coordinate from token
local function parseCoord(coord_str)
    local x, y = coord_str:match("^(%d+),(%d+)$")
    if x and y then
        return tonumber(x), tonumber(y)
    end
    return nil, nil
end

-- Command constructors
function Parser.newBackgroundCommand(color)
    return {type = "background", color = color}
end

function Parser.newColorCommand(color)
    return {type = "color", color = color}
end

function Parser.newPixelCommand(color, x, y)
    return {type = "pixel", color = color, x = x, y = y}
end

function Parser.newLineCommand(color, x1, y1, x2, y2)
    return {type = "line", color = color, x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

function Parser.newRectCommand(color, x1, y1, x2, y2)
    return {type = "rect", color = color, x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

function Parser.newFillCommand(color, x1, y1, x2, y2)
    return {type = "fill", color = color, x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

function Parser.newCircleCommand(color, x, y, radius)
    return {type = "circle", color = color, x = x, y = y, radius = radius}
end

-- Parse tokens, check validity, and return commands
function Parser.parse(tokens)
    -- Check if tokens table is empty
    if #tokens < 2 then
        print("error: file contains no valid commands")
        os.exit(1)
    end

    -- Check for size command at first token
    local size_command = tokens[1]
    if size_command.type ~= Tokenizer.TokenType.COMMAND or size_command.value ~= "size" then
        print(string.format("error: first command must be 'size' (got '%s' at line %d)", 
        size_command.value or "nil", size_command.line or 1))
        os.exit(1)
    end

    -- Check size value exists
    local size_value = tokens[2]
    if not size_value then
        print(string.format("error: line %d: 'size' command requires a size value (e.g., size 16x16)", size_command.line))
        os.exit(1)
    end
    
    -- Check size value type
    if size_value.type ~= Tokenizer.TokenType.SIZE then
        print(string.format("error: line %d: 'size' must be followed by a size value (got %s)", 
        size_command.line, size_value.type))
        os.exit(1)
    end

    -- Parse size value
    local size_str = size_value.value
    local grid_width, grid_height = size_str:match("^(%d+)x(%d+)$")
    grid_width = tonumber(grid_width)
    grid_height = tonumber(grid_height)
    
    if not grid_width or not grid_height then
        print(string.format("error: line %d: invalid size format '%s'", size_command.line, size_str))
        os.exit(1)
    end

    -- This is gonna be returned as a query of the commands to be ran in order
    local commands = {}
    
    -- Store grid info as first "command"
    table.insert(commands, {type = "grid", width = grid_width, height = grid_height})
    
    -- Current color for subsequent commands
    local current_color = nil

    -- Validate remaining commands
    local i = 3
    while i <= #tokens do
        local token = tokens[i]

        if token.type == Tokenizer.TokenType.COMMAND then
            -- Check for illegal duplicate size
            if token.value == "size" then
                print(string.format("error: line %d: 'size' can only appear as the first command", token.line))
                os.exit(1)
            end

            -- Validate command-specific arguments
            if token.value == "background" then
                if i + 1 > #tokens or tokens[i + 1].type ~= Tokenizer.TokenType.COLOR then
                    print(string.format("error: line %d: '%s' requires a color value", token.line, token.value))
                    os.exit(1)
                end

                local color_token = tokens[i + 1]
                local color = hexToRgb(color_token.value)
                
                if not color then
                    print(string.format("error: line %d: invalid color format '%s'", token.line, color_token.value))
                    os.exit(1)
                end
                
                table.insert(commands, Parser.newBackgroundCommand(color))
                i = i + 2  -- Skip command and color
                
            elseif token.value == "color" then
                if i + 1 > #tokens or tokens[i + 1].type ~= Tokenizer.TokenType.COLOR then
                    print(string.format("error: line %d: '%s' requires a color value", token.line, token.value))
                    os.exit(1)
                end

                local color_token = tokens[i + 1]
                local color = hexToRgb(color_token.value)
                
                if not color then
                    print(string.format("error: line %d: invalid color format '%s'", token.line, color_token.value))
                    os.exit(1)
                end
                
                current_color = color
                table.insert(commands, Parser.newColorCommand(color))
                i = i + 2  -- Skip command and color
                
            elseif token.value == "line" or 
                   token.value == "rect" or 
                   token.value == "fill" then
                if i + 2 > #tokens then
                    print(string.format("error: line %d: '%s' requires 2 coordinates", token.line, token.value))
                    os.exit(1)
                end

                local coord1_token = tokens[i + 1]
                local coord2_token = tokens[i + 2]
                
                if coord1_token.type ~= Tokenizer.TokenType.COORD or
                   coord2_token.type ~= Tokenizer.TokenType.COORD then
                    print(string.format("error: line %d: '%s' requires 2 coordinates (got %s and %s)", 
                    token.line, token.value, coord1_token.type, coord2_token.type))
                    os.exit(1)
                end
                
                local x1, y1 = parseCoord(coord1_token.value)
                local x2, y2 = parseCoord(coord2_token.value)
                
                if not x1 or not y1 or not x2 or not y2 then
                    print(string.format("error: line %d: invalid coordinate format", token.line))
                    os.exit(1)
                end
                
                local color = current_color or {0, 0, 0, 1}
                
                if token.value == "line" then
                    table.insert(commands, Parser.newLineCommand(color, x1, y1, x2, y2))
                elseif token.value == "rect" then
                    table.insert(commands, Parser.newRectCommand(color, x1, y1, x2, y2))
                elseif token.value == "fill" then
                    table.insert(commands, Parser.newFillCommand(color, x1, y1, x2, y2))
                end
                
                i = i + 3  -- Skip command and 2 coordinates
                
            elseif token.value == "pixel" then
                if i + 1 > #tokens or tokens[i + 1].type ~= Tokenizer.TokenType.COORD then
                    print(string.format("error: line %d: pixel requires 1 coordinate", token.line))
                    os.exit(1)
                end

                local coord_token = tokens[i + 1]
                local x, y = parseCoord(coord_token.value)
                
                if not x or not y then
                    print(string.format("error: line %d: invalid coordinate format", token.line))
                    os.exit(1)
                end
                
                local color = current_color or {0, 0, 0, 1}
                table.insert(commands, Parser.newPixelCommand(color, x, y))
                i = i + 2  -- Skip command and coordinate
                
            elseif token.value == "circle" then
                if i + 2 > #tokens then
                    print(string.format("error: line %d: circle requires a coordinate and radius", token.line))
                    os.exit(1)
                end
                
                local coord_token = tokens[i + 1]
                local radius_token = tokens[i + 2]
                
                if coord_token.type ~= Tokenizer.TokenType.COORD then
                    print(string.format("error: line %d: circle requires a coordinate (got %s)", 
                    token.line, coord_token.type))
                    os.exit(1)
                end
                
                if radius_token.type ~= Tokenizer.TokenType.NUMBER then
                    print(string.format("error: line %d: circle requires a number for radius (got %s)", 
                    token.line, radius_token.type))
                    os.exit(1)
                end
                
                local x, y = parseCoord(coord_token.value)
                local radius = radius_token.value
                
                if not x or not y then
                    print(string.format("error: line %d: invalid coordinate format", token.line))
                    os.exit(1)
                end
                
                if radius <= 0 then
                    print(string.format("error: line %d: radius must be greater than 0", token.line))
                    os.exit(1)
                end
                
                local color = current_color or {0, 0, 0, 1}
                table.insert(commands, Parser.newCircleCommand(color, x, y, radius))
                i = i + 3  -- Skip command, coordinate, and radius
            else
                print(string.format("error: line %d: unknown command '%s'", token.line, token.value))
                os.exit(1)
            end
        else
            print(string.format("error: line %d: unexpected token type '%s' (expected command)", 
            token.line, token.type))
            os.exit(1)
        end
    end
    
    return commands
end

-- Keep original check function for backward compatibility
function Parser.check(tokens)
    local commands = Parser.parse(tokens)
    return commands ~= nil
end

return Parser
