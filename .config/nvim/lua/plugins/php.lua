return {
  -- Ensure PHP treesitter + related parsing is installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "c",
        "css",
        "diff",
        "html",
        "javascript",
        "json",
        "jsondoc",
        "jsonc",
        "lua",
        "markdown",
        "markdown_inline",
        "php",
        "phpdoc",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "twig",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      })
    end,
  },

  -- Install & configure the PHP LSP via Mason + lspconfig
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "intelephense", "php-cs-fixer", "phpstan", "psalm" })
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        php = { "php_cs_fixer" },
      },
    },
  },

  -- Tell LazyVim/LSPconfig to actually start intelephense for PHP buffers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          settings = {
            intelephense = {
              -- Helps large vendor dirs / monorepos
              files = { maxSize = 5000000 },

              -- This is the big one for frameworks like Laminas/Mezzio:
              -- make sure your project has composer install run so vendor/autoload.php exists.
              environment = {
                includePaths = { "vendor" },
              },
            },
          },
        },
      },
    },
  },
}
