-- Stores an individual data object (pandas dataframe, numpy array, torch tensor)
-- and defines functions to manipulate and display it.

---@class dispynvim.data
---@field name string
---@field type string
---@field shape table

local utils = require('dispynvim.utils')

local M = {}

function M.new(self, name)
  local type = calculate_type(name)
  local shape = calculate_shape(name, type)

  local new = {
    name = name,
    type = type,
    shape = shape,
  }
  setmetatable(new, { __index = M })
  return new
end

function M.get_num_images(self)
  -- Assumes the batch dimension is the first dimension
  local ndims = table.getn(self.shape)
  if ndims == 1 then
    error("Data object is not an image")
    return
  elseif ndims == 2 then
    return 1
  else
    return self.shape[1]
  end
end

-- Gets the output of a command executed in the dap repl
function get_dap_repl_output(command)
  -- Create temporary path to store dap repl output
  local tmp_path = "/tmp/" .. utils.generate_uuid() .. ".txt"

  require('dap.repl').execute("open('" .. tmp_path .. "', 'w').write(str(" .. command .. "))")

  while require('lfs').attributes(tmp_path, "size") == nil or require('lfs').attributes(tmp_path, "size") == 0 do end

  local file = io.open(tmp_path, "r")
  local command_output = file:read("*a")
  file:close()

  local success = os.remove(tmp_path)
  if not success then
    print("Error removing temporary file: " .. tmp_path)
  end

  return command_output
end

-- Calculates the type of the data object
function calculate_type(name)

  local type_str = get_dap_repl_output("type(" .. name .. ")")

  if get_dap_repl_output('"pandas.core.frame.DataFrame" in "' .. type_str .. '"') == "True" then
    return "pandas.DataFrame"
  elseif get_dap_repl_output('"numpy.ndarray" in "' .. type_str .. '"') == "True" then
    return "numpy.ndarray"
  elseif get_dap_repl_output('"torch.Tensor" in "' .. type_str .. '"') == "True" then
    return "torch.Tensor"
  end

  error("Could not determine type of data object")
end

-- Calculates the shape of the data object
function calculate_shape(name, type)
  local shape = ""
  if type == "pandas.DataFrame" then
    shape = get_dap_repl_output("list(iter(" .. name .. ".shape))")
  elseif type == "numpy.ndarray" then
    shape = get_dap_repl_output("list(iter(" .. name .. ".shape))")
  elseif type == "torch.Tensor" then
    shape = get_dap_repl_output("list(iter(" .. name .. ".shape))")
  end

  shape = string.gsub(shape, "%p", "")
  local dims = {}
  for str in string.gmatch(shape, "([^ ]+)") do
    table.insert(dims, tonumber(str))
  end

  return dims
end

return M

