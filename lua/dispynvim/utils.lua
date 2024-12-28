local M = {}

-- Creates a randomly generated temporary uuid
function M.generate_uuid()
  local handle = io.popen('uuidgen')
  local uuid = handle:read("*a")
  uuid = uuid:gsub("%s+", "")
  handle:close()

  return uuid
end

return M

