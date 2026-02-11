-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = "unnamedplus"

-- Prefer wl-clipboard when running on Wayland.
if vim.env.WAYLAND_DISPLAY ~= nil or vim.env.XDG_SESSION_TYPE == "wayland" then
  vim.g.clipboard = {
    name = "wl-clipboard",
    copy = {
      ["+"] = "wl-copy --type text/plain",
      ["*"] = "wl-copy --type text/plain",
    },
    paste = {
      ["+"] = "wl-paste --no-newline",
      ["*"] = "wl-paste --no-newline",
    },
    cache_enabled = 0,
  }
end

vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    prefix = "●",
  },
  float = { border = "rounded" },
})
