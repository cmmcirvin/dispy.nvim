# 🔍 dispy.nvim

Visualize PyTorch tensors directly in neovim while debugging with [nvim-dap](https://github.com/mfussenegger/nvim-dap). Powered by [image.nvim](https://github.com/3rd/image.nvim) and [lovely-tensors](https://github.com/xl0/lovely-tensors).

https://github.com/user-attachments/assets/3fc63e04-a14c-4a39-a5b4-478e844b4637

## 🔥 Features

While you're debugging your Python code, dispy.nvim lets you
- View PyTorch tensors as images directly in your terminal
- Sample and plot multiple images from a batch
- Visualize statistical plots of tensor values
- and more!

## ⚡️ Requirements
- Neovim 0.10.x
- [image.nvim](https://github.com/3rd/image.nvim) - used to display images in Kitty
- [lovely-tensors](https://github.com/xl0/lovely-tensors) - takes care of some of the plotting / statistical functionality automatically

## 📦 Installation

Install like you would any other neovim plugin.

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  "cmmcirvin/dispy.nvim",
  dependencies = {
    "mfussenegger/nvim-dap",
    "3rd/image.nvim"
  }
}
```

Default setup:

```lua
require("dispynvim").setup({
  n_images = 4,              -- Number of images to extract from batched tensors
  cell_aspect_ratio = 18/40, -- Cell aspect ratio (18/40 on MacOS)
  scale = 0.5,               -- Scale of the images to be displayed
})
```

It is also recommended to define several keymaps.

```lua
vim.keymap.set({'n', 'v'}, '<leader>pi', ':lua require("dispynvim").display_single_image()<CR>')
vim.keymap.set({'n', 'v'}, '<leader>pl', ':lua require("dispynvim").display_random_images()<CR>')
vim.keymap.set({'n', 'v'}, '<leader>ps', ':lua require("dispynvim").plot_statistics()<CR>')
vim.keymap.set({'n', 'v'}, '<leader>pt', ':lua require("dispynvim").print_statistics()<CR>')
```

## 🚧 Future Work
- Currently, the plugin has been tested on MacOS only.
- Extend support to numpy arrays / pandas dataframes
- Add additional plotting capabilities
- The current method for executing code (by directly calling the nvim-dap repl) is a bit hacky and can impact the state of the currently running program
