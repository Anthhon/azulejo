-- main.lua
local Tokenizer = require("source/tokenizer")
local Parser = require("source/parser")
local Draw = require("source/draw")
local State = require("source/state")

-- Read arguments from user to get filename
local filename = arg[2]
if not filename then
    print("usage: love source/ [filepath]")
    os.exit(1)
end

-- Check if the file has '.azlj' extension
local dot_pos = filename:find("%.[^%.]+$")
if dot_pos then
    local ext = filename:sub(dot_pos + 1)
    if ext ~= "azlj" then
        print("error: " .. filename .. " has extension '." .. ext .. "' instead of '.azlj'")
        os.exit(1)
    end
else
    print("error: " .. filename .. " is not a '.azlj' file")
    os.exit(1)
end

-- Open '.azlj' file
local file = io.open(filename, "r")
if not file then
    print("error: file " .. filename .. " could not be find/open")
    os.exit(1)
end

-- Read file content
local content = file:read("*a")
file:close()

-- Parse tokens and get commands
local tokens = Tokenizer.tokenize(content)
local commands = Parser.parse(tokens)

-- Initialize grid state
State.initGrid()

-- Execute all commands in order
local function executeCommands(commands)
    for _, cmd in ipairs(commands) do
        if cmd.type == "grid" then
            State.setGridSize(cmd.width, cmd.height)
        elseif cmd.type == "background" then
            local width, height = State.getGridSize()
            Draw.fillRect(1, 1, width, height, cmd.color)
        elseif cmd.type == "color" then
            -- Just update current color, no drawing needed
            -- Color is already set in parser for subsequent commands
        elseif cmd.type == "pixel" then
            local grid_width, grid_height = State.getGridSize()
            if cmd.x >= 1 and cmd.x <= grid_width and cmd.y >= 1 and cmd.y <= grid_height then
                State.setPixelColor(cmd.x, cmd.y, cmd.color)
            else
                print(string.format("warning: pixel at (%d,%d) is outside grid bounds", cmd.x, cmd.y))
            end
        elseif cmd.type == "line" then
            Draw.drawLine(cmd.x1, cmd.y1, cmd.x2, cmd.y2, cmd.color)
        elseif cmd.type == "rect" then
            Draw.drawRect(cmd.x1, cmd.y1, cmd.x2, cmd.y2, cmd.color)
        elseif cmd.type == "fill" then
            Draw.fillRect(cmd.x1, cmd.y1, cmd.x2, cmd.y2, cmd.color)
        elseif cmd.type == "circle" then
            Draw.drawCircle(cmd.x, cmd.y, cmd.radius, cmd.color)
        end
    end
end

-- Execute all commands
executeCommands(commands)

function love.load()
    -- Calculate cell size based on window dimensions
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local grid_width, grid_height = State.getGridSize()
    local cell_size = State.getCellSize()
    
    -- Set cell size to fit the grid in the window
    cell_size = math.min(window_width / grid_width, window_height / grid_height) * 0.5
    State.setCellSize(cell_size)
    
    -- Set window size to exactly fit the grid
    love.window.setMode(grid_width * cell_size, grid_height * cell_size)
    love.window.setTitle("Azulejo - " .. filename)
end

function love.draw()
    -- Get grid dimensions and cell size
    local grid_width, grid_height = State.getGridSize()
    local cell_size = State.getCellSize()
    local background_color = State.grid.background_color
    
    -- Set background color
    if background_color then
        love.graphics.setBackgroundColor(unpack(background_color))
    else
        love.graphics.setBackgroundColor(1, 1, 1)  -- Default white
    end
    
    -- Draw each cell
    for x = 1, grid_width do
        for y = 1, grid_height do
            -- Get cell upper-left position on screen
            local screen_x = (x - 1) * cell_size
            local screen_y = (y - 1) * cell_size
            
            -- Get color for this cell
            local color = State.getPixelColor(x, y)
            
            if color then
                -- Draw pixel with stored color
                love.graphics.setColor(unpack(color))
            else
                -- Draw empty cell with subtle grid pattern
                if (x + y) % 2 == 0 then
                    love.graphics.setColor(0.98, 0.98, 0.98)
                else
                    love.graphics.setColor(1, 1, 1)
                end
            end
            
            -- Draw the cell
            love.graphics.rectangle("fill", screen_x, screen_y, cell_size, cell_size)
            
            -- Draw grid lines
            -- love.graphics.setColor(0.8, 0.8, 0.8)
            -- love.graphics.rectangle("line", screen_x, screen_y, cell_size, cell_size)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
