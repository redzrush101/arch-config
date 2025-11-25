-- =============================================================================
-- Indent Blankline - Catppuccin Mocha Integration
-- =============================================================================
return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- Catppuccin Mocha colors
    local highlight = {
      "CatppuccinSurface0",
      "CatppuccinSurface1",
    }

    local hooks = require("ibl.hooks")
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, "CatppuccinSurface0", { fg = "#313244" })
      vim.api.nvim_set_hl(0, "CatppuccinSurface1", { fg = "#45475a" })
      vim.api.nvim_set_hl(0, "CatppuccinMauve", { fg = "#cba6f7" })
    end)

    require("ibl").setup({
      indent = {
        char = "│",
        tab_char = "│",
        highlight = highlight,
      },
      scope = {
        enabled = true,
        show_start = true,
        show_end = false,
        highlight = "CatppuccinMauve",
      },
      exclude = {
        filetypes = {
          "help",
          "dashboard",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "oil",
        },
      },
    })
  end,
}
