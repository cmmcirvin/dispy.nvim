local lfs = require("lfs")

local M = {}

-- Creates a randomly generated temporary uuid
function M.generate_uuid()
  local handle = io.popen('uuidgen')
  local uuid = handle:read("*a")
  uuid = uuid:gsub("%s+", "")
  handle:close()

  return uuid
end

function M.confirm_file_written(filename)
  -- Make sure the file is written to
  local start = os.time()
  local file_size = lfs.attributes(filename, "size")
  while file_size == nil or file_size == 0 do
    file_size = lfs.attributes(filename, "size")
    if os.time() - start > 1 then
      -- Timeout
      error("Error writing to temporary file: " .. filename)
      return
    end
  end
end

return M

