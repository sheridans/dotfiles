return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false, -- Use latest
  opts = {
    provider = "claude", -- Default to Claude
    claude = {
      model = "claude-sonnet-4-20250514",
    },
    -- Supports: claude, openai, gemini, copilot
  },
  build = "make", -- or "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" on Windows
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    "MeanderingProgrammer/render-markdown.nvim",
  },
}
