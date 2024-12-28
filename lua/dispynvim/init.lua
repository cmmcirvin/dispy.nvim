local M = {}

local commands = {
  {
    cmd = "DispynvimShowImage",
    args = "`left/right/float`",
    func = "toggle",
    defn = {
      desc = "Open or close the aerial window. With `!` cursor stays in current window",
      nargs = "?",
      bang = true,
      complete = list_complete({ "left", "right", "float" }),
    },
  },
}

local function create_commands()
  for _, v in pairs(commands) do
    local callback = lazy("command", v.func, vim.tbl_get(v, "meta", "retry_on_setup"))
    vim.api.nvim_create_user_command(v.cmd, callback, v.defn)
  end
end

M.toggle = function(opts)
  print("toggle")
end

return M
