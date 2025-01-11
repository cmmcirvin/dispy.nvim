local utils = require('dispynvim.utils')

local M = {}

-- Creates a new data object
function M.new(self, name)
  local shape = calculate_shape(name)

  local new = {
    name = name,
    shape = shape,
  }
  setmetatable(new, { __index = M })
  return new
end

-- Calculates the number of images in the data object
function M.get_num_images(self)
  local ndims = table.getn(self.shape)
  if ndims == 1 then
    -- Not an image
    error("Data is not an image")
    return
  elseif ndims == 2 then
    -- A single image
    return 1
  elseif ndims == 3 then
    if self.shape[1] == 3 or self.shape[3] == 3 then
      -- RGB image (channels, height, width) or (height, width, channels)
      return 1
    else
      -- Batch of images, assumes size (batch, height, width)
      return self.shape[1]
    end
  elseif ndims == 4 then
    -- Assumes batch is the first dimension
    return self.shape[1]
  else
    error("Data has too many dimensions")
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
