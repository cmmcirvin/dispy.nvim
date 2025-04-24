local repl = require("dap.repl")
local data = require("dispynvim.data")
local utils = require("dispynvim.utils")
local lfs = require("lfs")

local M = {}

-- Save script file
local function create_script()
    local script = [=[#!/usr/bin/env -S uv run --no-project
# /// script
# requires-python = ">=3.8"
# dependencies = [
#   "torchshow>=0.5.0",
#   "torch",
#   "matplotlib",
#   "lovely_tensors",
#   "argparse"
# ]
# ///

import sys
import torch
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--mode", choices=["show_tensor", "plot_statistics"], help="Mode to display the tensor", default="show_tensor")
parser.add_argument("--filename", help="Filename of the tensor to display", default="/tmp/tmp.pkl")
parser.add_argument("--suptitle", help="Matplotlib title", default=None)
args = parser.parse_args()

tensor = __import__('pickle').load(open(args.filename, 'rb'))

if args.mode == "show_tensor":
    import torchshow as ts
    # Use torchshow to save the tensor as an image
    ts.show(tensor, suptitle=args.suptitle)
elif args.mode == "plot_statistics":
    import lovely_tensors as lt
    import matplotlib.pyplot as plt
    # Use lovely_tensors to plot tensor statistics
    fig = plt.figure()
    ax = fig.add_subplot()
    lt.plot(torch.tensor(tensor), ax=ax)
    plt.show()

]=]

    vim.fn.mkdir(vim.fn.fnamemodify(M.cfg.script_path, ":h"), "p")
    -- vim.fn.mkdir(M.cfg.output_dir, "p")

    local file = io.open(M.cfg.script_path, "w")
    file:write(script)
    file:close()

    vim.fn.system("chmod +x " .. vim.fn.shellescape(M.cfg.script_path))
end

M.setup = function(cfg)
  default_cfg = {
    script_path = vim.fn.stdpath("data") .. "/dispy.nvim/display_tensors.py",
  }

  M.cfg = vim.tbl_deep_extend("force", default_cfg, cfg)

  create_script()

end

M._open_window = function(args)


  local command = M.cfg.script_path
  for key, value in pairs(args) do
    command = command .. ' --' .. key .. ' ' .. vim.fn.shellescape(value)
  end

  M.current_job_id = vim.fn.jobstart(command, {
    rpc = true
  })

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

M._save_tensor_to_pkl = function(selected_text)

  local args = {
    expression = "__import__('pickle').dump(" .. selected_text .. ", open('/tmp/dispy.pkl', 'wb'))",
    context = "repl"
  }

  local session = require('dap').session()
  session:evaluate(args, function(err, resp)
    if err then
      error("Error saving tensor [" .. selected_text .. "]: " .. err.message)
      return
    end
  end)

end

M._plot = function(args)

  M.ensure_active_dap_session()
  M._save_tensor_to_pkl(M._get_selected_text())
  M._open_window(args)

end

-- Displays the tensor as an image
M.show_tensor = function()

  local args = {
    mode = "show_tensor",
    filename = "/tmp/dispy.pkl",
    suptitle = M._get_selected_text(),
  }

  M._plot(args)

end

-- Plots relevant statistics
M.plot_statistics = function()

  local args = {
    mode = "plot_statistics",
    filename = "/tmp/dispy.pkl",
  }

  M._plot(args)

end

return M
