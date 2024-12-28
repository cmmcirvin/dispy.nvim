-- Stores an individual data object (pandas dataframe, numpy array, torch tensor)
-- and defines functions to manipulate it.

---@class dispynvim.Data
---@field name string
---@field type string

local Data = {}

function Data.new(name, type)
  local new = {
    name = name,
    type = type,
  }
  setmetatable(new, { __index = Data })
  return new
end

function Data.__tostring(self)
  return string.format("Data: %s (%s)", self.name, self.type)
end
