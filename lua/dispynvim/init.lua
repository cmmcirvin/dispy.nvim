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

M.display_random_images = function()
  local n_images = 9
  local image = data:new(M._get_selected_text())
  if image.type ~= "numpy.ndarray" and image.type ~= "torch.Tensor" then
    error("Unsupported data type")
  end

  local repl_command = image.name

  num_images = image:get_num_images()
  image_idxes = {}
  if num_images > n_images then
    for i = 1, n_images do
      idx = math.random(0, num_images - 1)
      table.insert(image_idxes, idx)
    end
  else
    error("Tried to display " .. n_images .. " images, but only " .. num_images .. " images were available.")
    return
  end

  if image.type == "torch.Tensor" then
    repl_command = repl_command .. ".cpu().detach().numpy()"
  end

  repl_command = repl_command .. "[[" .. table.concat(image_idxes, ",") .. "]]"
  repl_command = "np.concatenate(" .. repl_command .. ", axis=0)"

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

  local macos_cell_aspect_ratio = 18 / 40

  local floating_win_width
  local floating_win_height
  if aspect_ratio <= 1 then
    floating_win_width = math.floor(win_width * 0.5)
    floating_win_height = math.floor(floating_win_width * aspect_ratio * macos_cell_aspect_ratio)
  elseif aspect_ratio > 1 then
    floating_win_height = math.floor(win_height * 0.5)
    floating_win_width = math.floor(floating_win_height / aspect_ratio / macos_cell_aspect_ratio)
  end

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = floating_win_width,
    height = floating_win_height,
    col = 0,
    row = 0,
    style = "minimal",
    border = "none",
  })

  local ns = vim.api.nvim_create_namespace("transparent_bgd")
  vim.api.nvim_set_hl(ns, 'Normal', {bg = 'none'})
  vim.api.nvim_win_set_hl_ns(win, ns)

  local image = api.from_file(tmp_filename, {
    buffer=buf,
    window=win,
    width=floating_win_width,
    height=floating_win_height,
    with_virtual_padding=false,
    x=0,
    y=0,
  })

  -- BUG: Floating window is occasionally slightly larger than image
  image:render()

  -- Clear image when buffer is closed
  vim.api.nvim_create_autocmd({"BufLeave"}, {
    buffer=buf,
    callback=function()
      image:clear()
      vim.api.nvim_win_close(win, true)
      local success = os.remove(tmp_filename)
      if not success then
        print("Error removing temporary image file: " .. tmp_filename)
      end
    end
  })

end

return M



