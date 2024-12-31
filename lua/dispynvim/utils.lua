local lfs = require("lfs")
local repl = require("dap.repl")

local M = {}

-- Creates a randomly generated temporary uuid
function M.generate_uuid()
  local handle = io.popen('uuidgen')
  local uuid = handle:read("*a")
  uuid = uuid:gsub("%s+", "")
  handle:close()

  return uuid
end

-- Confirms that a file has been created and written to successfully
-- Hacky logic, works by creating a temporary file and confirming the output matches
function M.confirm_file_written()
  local filename = "/tmp/" .. M.generate_uuid() .. ".txt"
  repl.execute("open('" .. filename .. "', 'w').write('done')")

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

  local file = io.open(filename, "r")
  assert(file:read("*a") == "done")
  file:close()
end

return M
