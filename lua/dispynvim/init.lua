local data = require("dispynvim.data")
local utils = require("dispynvim.utils")
local lfs = require("lfs")

local M = {}

--- Gets currently selected text
M._get_selected_text = function()
  local m1 = vim.fn.col("'<")
  local m2 = vim.fn.col("'>")
  local line_no = vim.fn.winline()
  local line = vim.api.nvim_get_current_line()
  return line:sub(m1, m2)
end

--- @param index index to display at
M._display_image = function()
  local image = data:new(M._get_selected_text())
  print("Displaying an image")
end

-- Takes in a command that outputs an image and saves the image to a temporary file
M._save_image = function(repl_command)
  -- create temporary file for image
  local tmp_filename = "/tmp/" .. utils.generate_uuid() .. ".png"

  require('dap.repl').execute("import matplotlib.pyplot as plt")
  require('dap.repl').execute("plt.imsave('" .. tmp_filename .. "', " .. repl_command .. ")")

  while lfs.attributes(tmp_filename, "size") == nil or lfs.attributes(tmp_filename, "size") == 0 do end

end

M._display_image = function(tmp_filename)

  local win_width = vim.api.nvim_get_option("columns")
  local win_height = vim.api.nvim_get_option("lines")

  local api = require("image")
  local image = api.from_file(tmp_filename)
  local aspect_ratio = image.image_height / image.image_width

  local floating_win_width = math.floor(win_width * 0.5)
  local floating_win_height = math.floor(floating_win_width * aspect_ratio / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = floating_win_width,
    height = floating_win_height - 2,
    row = 0,
    col = 0,
    style = "minimal",
    border = "none",
  })

  local image = api.from_file(tmp_filename, {buffer=buf, window=win, height=floating_win_height, x=0, y=0})

  image.max_height_window_percentage = 100
  image.max_width_window_percentage = 100
  image:render()

  -- Clear image when buffer is closed
  vim.api.nvim_create_autocmd({"BufWinLeave"}, {
    buffer=buf,
    callback=function()
      image:clear()
      local success = os.remove(tmp_filename)
      if not success then
        print("Error removing temporary image file: " .. tmp_filename)
      end
    end
  })

end

return M

