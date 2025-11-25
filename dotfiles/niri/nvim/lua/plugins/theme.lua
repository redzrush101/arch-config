-- =============================================================================
-- Neovim Theme - Catppuccin Mocha
-- =============================================================================
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      no_italic = false,
      no_bold = false,
      no_underline = false,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      color_overrides = {},
      custom_highlights = function(colors)
        return {
          -- Custom statusline colors
          StatusLine = { bg = colors.mantle },
          StatusLineNC = { bg = colors.mantle },
          
          -- Better visual mode
          Visual = { bg = colors.surface1 },
          VisualNOS = { bg = colors.surface1 },
          
          -- Cursor line
          CursorLine = { bg = colors.surface0 },
          CursorLineNr = { fg = colors.lavender, bold = true },
          
          -- Float borders
          FloatBorder = { fg = colors.mauve },
          
          -- Telescope
          TelescopeBorder = { fg = colors.mauve },
          TelescopePromptBorder = { fg = colors.mauve },
          TelescopeResultsBorder = { fg = colors.surface1 },
          TelescopePreviewBorder = { fg = colors.surface1 },
          
          -- Which-key
          WhichKeyBorder = { fg = colors.mauve },
          
          -- Indent guides
          IblIndent = { fg = colors.surface0 },
          IblScope = { fg = colors.mauve },
        }
      end,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = {
          enabled = true,
          indentscope_color = "mauve",
        },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
          inlay_hints = {
            background = true,
          },
        },
        indent_blankline = {
          enabled = true,
          scope_color = "mauve",
          colored_indent_levels = false,
        },
        mason = true,
        telescope = {
          enabled = true,
        },
        which_key = true,
      },
    })

    -- Apply the colorscheme
    vim.cmd.colorscheme("catppuccin")
  end,
}
