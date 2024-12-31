-- Stores an individual pytorch tensor
-- and defines functions to manipulate and display it.

---@class dispynvim.data
---@field name string
---@field shape table

local utils = require('dispynvim.utils')

local M = {}

function M.new(self, name)
  local shape = calculate_shape(name)

  local new = {
    name = name,
    shape = shape,
  }
  setmetatable(new, { __index = M })
  return new
end

function M.get_num_images(self)
  -- Assumes shape (batch, channels, height, width) or (channels, height, width)
  local ndims = table.getn(self.shape)
  if ndims == 1 then
    error("Data is not an image")
    return
  elseif ndims == 2 or ndims == 2 then
    return 1
  elseif ndims == 3 then
    if self.shape[1] == 3 or self.shape[1] == 4 then
      return 1
    else
      error("Expected 3 (RGB) or 4 (RGBA) channels, got " .. self.shape[1])
    end
  else
    -- Batch dimension
    return self.shape[1]
  end
end

-- Gets the output of a command executed in the dap repl
function get_dap_repl_output(command)
  -- Create temporary path to store dap repl output
  local tmp_path = "/tmp/" .. utils.generate_uuid() .. ".txt"

  require('dap.repl').execute("open('" .. tmp_path .. "', 'w').write(str(" .. command .. "))")
  utils.confirm_file_written(tmp_path)

  local file = io.open(tmp_path, "r")
  local command_output = file:read("*a")
  file:close()

  local success = os.remove(tmp_path)
  if not success then
    print("Error removing temporary file: " .. tmp_path)
  end

  return command_output
end

-- Calculates the shape of the data object
function calculate_shape(name)
  local shape = get_dap_repl_output("list(iter(" .. name .. ".shape))")

  shape = string.gsub(shape, "%p", "")
  local dims = {}
  for str in string.gmatch(shape, "([^ ]+)") do
    table.insert(dims, tonumber(str))
  end

  return dims
end

return M


