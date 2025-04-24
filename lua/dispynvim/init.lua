local repl = require("dap.repl")

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
#   "pandas",
#   "argparse"
# ]
# ///

import argparse
import matplotlib.pyplot as plt
import pandas as pd
import sys
import torch

parser = argparse.ArgumentParser()
parser.add_argument("--mode", choices=["show_tensor", "plot_statistics", "time_series"], help="Mode to display the tensor", default="show_tensor")
parser.add_argument("--tensor_name", help="Name of the tensor", default=None)
args = parser.parse_args()

tensor = torch.tensor(__import__('pickle').load(open("/tmp/dispy.pkl", 'rb')))

if args.mode == "show_tensor":
    # If IQ data, plot a spectrogram
    if tensor.is_complex():
      plt.specgram(tensor)
      plt.title("Spectrogram")
      plt.show()
    else:
      import torchshow as ts
      # Use torchshow to save the tensor as an image
      ts.show(tensor, suptitle=args.tensor_name)
elif args.mode == "plot_statistics":
    # Use lovely_tensors to plot tensor statistics
    import lovely_tensors as lt
    if tensor.is_complex():
      fig, axs = plt.subplots(2, 1)
      lt.plot(tensor.real, ax=axs[0])
      axs[0].set_ylabel("Real", rotation=90, va="center", labelpad=15)
      lt.plot(tensor.imag, ax=axs[1])
      axs[1].set_ylabel("Imaginary", rotation=90, va="center", labelpad=15)
    else:
      fig = plt.figure()
      ax = fig.add_subplot()
      lt.plot(tensor, ax=ax)
    plt.show()
elif args.mode == "time_series":
    import seaborn as sns
    if tensor.is_complex():
      df = pd.DataFrame({'real': tensor.numpy().real, 'imag': tensor.numpy().imag})
      sns.lineplot(data=df, x='real', y='imag')
    else:
      df = pd.DataFrame({'x': tensor.numpy()})
      sns.lineplot(data=df, x='x', y='y')
    plt.show()
else:
    raise ValueError("Invalid mode: {}".format(args.mode))

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

  vim.fn.jobstart(command, {
    rpc = true,
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

M._save_tensor_to_pkl = function(tensor_name)

  local args = {
    expression = "__import__('pickle').dump(" .. tensor_name .. ", open('/tmp/dispy.pkl', 'wb'))",
    context = "repl"
  }

  local session = require('dap').session()
  session:evaluate(args, function(err, resp)
    if err then
      error("Error saving tensor [" .. tensor_name .. "]: " .. err.message)
      return
    end
  end)

end

M.plot = function(args)

  args.tensor_name = M._get_selected_text()

  print(args.tensor_name)
  print(args.mode)

  M.ensure_active_dap_session()
  M._save_tensor_to_pkl(args.tensor_name)
  M._open_window(args)

end

return M
