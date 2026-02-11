return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  ft = { "markdown" },
  -- npm install modifies app/yarn.lock; reset it to avoid Lazy's dirty check
  build = "cd app && npm install && git checkout -- yarn.lock",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
    -- Ensure the repo stays clean before Lazy's git status check
    local dir = vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim"
    if (vim.uv or vim.loop).fs_stat(dir .. "/.git") then
      vim.fn.system({ "git", "-C", dir, "checkout", "--", "app/yarn.lock" })
    end
  end,
}
