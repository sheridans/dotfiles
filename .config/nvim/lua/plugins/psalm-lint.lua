return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local lint = require("lint")

      -- Enable psalm for PHP without clobbering other linters.
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.php = opts.linters_by_ft.php or {}
      if not vim.tbl_contains(opts.linters_by_ft.php, "psalm") then
        table.insert(opts.linters_by_ft.php, "psalm")
      end

      -- Prefer project-local psalm and force JSON output.
      lint.linters.psalm = lint.linters.psalm or {}
      lint.linters.psalm.cmd = "vendor/bin/psalm"
      lint.linters.psalm.args = { "--output-format=json", "--no-progress" }
      lint.linters.psalm.ignore_exitcode = true
    end,
  },
}
