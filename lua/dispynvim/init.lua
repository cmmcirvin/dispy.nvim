local repl = require("dap.repl")
local data = require("dispynvim.data")
local utils = require("dispynvim.utils")
local lfs = require("lfs")

local M = {}

M.setup = function(cfg)
  default_cfg = {
    n_images = 4,
    cell_aspect_ratio = 18 / 40, -- cell aspect ratio (macos)
    scale = 0.5
  }

  M.cfg = vim.tbl_deep_extend("force", default_cfg, cfg)
end

-- Gets currently selected text under cursor
-- Defaults to the word under cursor if no text is selected
M._get_selected_text = function()
  local m1 = vim.fn.col("'<")
  local m2 = vim.fn.col("'>")
  local line_no = vim.fn.winline()
  local line = vim.api.nvim_get_current_line()
  local selected_text = line:sub(m1, m2)

  if selected_text == "" then
    selected_text = vim.fn.expand("<cword>")
  end

  return selected_text
end

-- Ensures that there is an active nvim-dap session
M.ensure_active_dap_session = function()
  if not require('dap').session() then
    error("No active nvim-dap session")
  end
end

-- Imports the required python libraries for the current session
M.run_imports = function()
  repl.execute("import matplotlib.pyplot as plt")
  repl.execute("import lovely_tensors as lt")
  repl.execute("lt.monkey_patch()")
end

-- Plots statistics of the selected tensor as an image
M.plot_statistics = function()
  M.ensure_active_dap_session()
  M.run_imports()

  local selected_text = M._get_selected_text()
  local tmp_filename = "/tmp/" .. utils.generate_uuid() .. ".png"

  repl.execute(selected_text .. ".plt.fig.savefig('" .. tmp_filename .. "')")
  utils.confirm_file_written()
  M._open_floating_image(tmp_filename)

end

-- Prints statistics of the selected tensor in text format
M.print_statistics = function()
  M.ensure_active_dap_session()
  M.run_imports()

  local selected_text = M._get_selected_text()
  local tmp_filename = "/tmp/" .. utils.generate_uuid() .. ".txt"

  repl.execute("open('" .. tmp_filename .. "', 'w').write(str(" .. selected_text .. "))")
  utils.confirm_file_written()

  M._open_floating_text(tmp_filename)
end

-- Displays the selected tensor as an image
M.display_single_image = function(idx)
  M.ensure_active_dap_session()
  M.run_imports()

  local image = data:new(M._get_selected_text())
  local repl_command

  num_images = image:get_num_images()
  print(num_images)
  if num_images > 1 or #image.shape == 4 then
    if idx == nil then
      idx = math.random(0, num_images - 1)
    elseif idx < 0 or idx >= num_images then
      error("Index out of bounds")
      return
    end
    repl_command = image.name .. "[" .. idx .. "]"
    image.shape = {select(2, unpack(image.shape))}
  else
    repl_command = image.name
  end

  if #image.shape == 2 then
    repl_command = repl_command .. ".unsqueeze(0)"
    image.shape = {1, select(1, unpack(image.shape))}
  end

  if not vim.tbl_contains({1, 3, 4}, image.shape[1]) then
    repl_command = repl_command .. ".permute(2, 0, 1)"
    image.shape = {image.shape[3], image.shape[1], image.shape[2]}
  end

  if #image.shape == 3 and image.shape[1] == 1 then
    repl_command = repl_command .. ".repeat(3, 1, 1)"
    image.shape = {3, select(2, unpack(image.shape))}
  end

  local tmp_filename = "/tmp/" .. utils.generate_uuid() .. ".png"
  repl.execute(repl_command .. ".rgb.fig.savefig('" .. tmp_filename .. "')")

  utils.confirm_file_written()

  M._open_floating_image(tmp_filename)

end

M.plot_weights = function(idx)
  M.ensure_active_dap_session()
  M.run_imports()

  local image = data:new(M._get_selected_text())
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

  repl_command = repl_command .. ".cpu().detach().numpy()"

  local tmp_filename = "/tmp/" .. utils.generate_uuid() .. ".png"

  repl.execute("plt.imsave('" .. tmp_filename .. "', " .. repl_command .. ")")

  utils.confirm_file_written()
  M._open_floating_image(tmp_filename)

end

M.display_random_images = function()
  M.ensure_active_dap_session()
  M.run_imports()

  local image = data:new(M._get_selected_text())
  local repl_command = image.name

  num_images = image:get_num_images()
  image_idxes = {}
  if num_images > M.cfg.n_images then
    for i = 1, M.cfg.n_images do
      idx = math.random(0, num_images - 1)
      table.insert(image_idxes, idx)
    end
  else
    error("Tried to display " .. M.cfg.n_images .. " images, but only " .. num_images .. " images were available.")
    return
  end

  repl_command = repl_command .. "[[" .. table.concat(image_idxes, ",") .. "]]"

  if #image.shape == 4 and image.shape[2] == 1 then
    repl_command = repl_command .. ".repeat(1, 3, 1, 1)"
  end

  local tmp_filename = "/tmp/" .. utils.generate_uuid() .. ".png"

  repl.execute(repl_command .. ".rgb.fig.savefig('" .. tmp_filename .. "')")

  utils.confirm_file_written()
  M._open_floating_image(tmp_filename)
end

-- Opens a new floating window to display an image
M._open_floating_image = function(tmp_filename)

  local win_width = vim.api.nvim_get_option("columns")
  local win_height = vim.api.nvim_get_option("lines")

  local api = require("image")
  local image = api.from_file(tmp_filename)
  local aspect_ratio = image.image_height / image.image_width

  local floating_win_width
  local floating_win_height
  if aspect_ratio <= 1 then
    floating_win_width = math.floor(win_width * M.cfg.scale)
    floating_win_height = math.floor(floating_win_width * aspect_ratio * M.cfg.cell_aspect_ratio)
  elseif aspect_ratio > 1 then
    floating_win_height = math.floor(win_height * M.cfg.scale)
    floating_win_width = math.floor(floating_win_height / aspect_ratio / M.cfg.cell_aspect_ratio)
  end

  if floating_win_width == 0 then
    error("Aspect ratio of image to be displayed is too high.")
    return
  elseif floating_win_height == 0 then
    error("Aspect ratio of image to be displayed is too low.")
    return
  end

  local floating_win_scale_factor = 1.5
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.floor(floating_win_width * floating_win_scale_factor),
    height = math.floor(floating_win_height * floating_win_scale_factor),
    row = 0,
    col = 0,
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

-- Opens a new floating window to display text
M._open_floating_text = function(tmp_filename)

  local win_width = vim.api.nvim_get_option("columns")
  local win_height = vim.api.nvim_get_option("lines")

  local max_width = 0
  local num_lines = 0
  for line in io.lines(tmp_filename) do
    max_width = math.max(max_width, #line)
    num_lines = num_lines + 1
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = max_width,
    height = num_lines,
    col = 0,
    row = 0,
    style = "minimal",
    border = "none",
  })
  vim.api.nvim_command("$read" .. tmp_filename)

  local ns = vim.api.nvim_create_namespace("transparent_bgd")
  vim.api.nvim_set_hl(ns, 'Normal', {bg = 'none'})
  vim.api.nvim_win_set_hl_ns(win, ns)

  vim.api.nvim_create_autocmd({"BufLeave"}, {
    buffer=buf,
    callback=function()
      vim.api.nvim_win_close(win, true)
      local success = os.remove(tmp_filename)
      if not success then
        print("Error removing temporary text file: " .. tmp_filename)
      end
    end
  })

end

return M
