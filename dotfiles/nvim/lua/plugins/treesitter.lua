return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require('nvim-treesitter.configs').setup({
      -- Install parsers for C and related languages
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query" },
      
      -- Install parsers synchronously
      sync_install = false,
      
      -- Automatically install missing parsers
      auto_install = true,
      
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      
      indent = {
        enable = true
      },
    })
  end,
}
