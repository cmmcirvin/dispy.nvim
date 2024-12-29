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
  local selected_text = line:sub(m1, m2)

  if selected_text == "" then
    selected_text = vim.fn.expand("<cword>")
  end

  print(selected_text)

  return selected_text
end

--- @param index index to display at
M.display_single_image = function(idx)
  local image = data:new(M._get_selected_text())
  if image.type ~= "numpy.ndarray" and image.type ~= "torch.Tensor" then
    error("Unsupported data type")
  end

  local repl_command

  num_images = image:get_num_images()
  if num_images > 1 then
    if idx == nil then
      idx = math.random(0, num_images - 1)
    elseif idx < 0 or idx >= num_images then
      error("Index out of bounds")
      return
    end
    repl_command = image.name .. "[" .. idx .. "]"
  else
    repl_command = image.name
  end

  if image.type == "torch.Tensor" then
    repl_command = repl_command .. ".cpu().detach().numpy()"
  end

  local tmp_filename = "/tmp/" .. utils.generate_uuid() .. ".png"

  require('dap.repl').execute("import matplotlib.pyplot as plt")
  require('dap.repl').execute("plt.imsave('" .. tmp_filename .. "', " .. repl_command .. ")")

  utils.confirm_file_written(tmp_filename)

  M._open_floating_window(tmp_filename)

end

M._open_floating_window = function(tmp_filename)

  local win_width = vim.api.nvim_get_option("columns")
  local win_height = vim.api.nvim_get_option("lines")

  local api = require("image")
  local image = api.from_file(tmp_filename)
  local aspect_ratio = image.image_height / image.image_width

  local floating_win_width = math.floor(win_width * 0.5)
  local floating_win_height = math.floor(floating_win_width * aspect_ratio / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
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



