local Tokenizer = require("source/tokenizer")

-- Read arguments from user to get filename
local filename = arg[1]
if not filename then
    print("usage: lua azulejo [filename]")
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
local content = file:read("*a") -- read everything
file:close() -- free file just after storing it's content

local tokens = Tokenizer.tokenize(content)
for i, token in ipairs(tokens) do
    print(string.format("(%d) {%s,%s,%d}", 
    i, token.type, tostring(token.value), token.line))
end
