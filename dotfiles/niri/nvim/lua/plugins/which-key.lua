return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {},
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    wk.add({
      { "<leader>c", group = "Compile/Code" },
      { "<leader>r", group = "Rename" },
      { "<leader>f", group = "Format" },
      { "<leader>d", group = "Diagnostics" },
      { "<leader>e", group = "Explorer" },
    })
  end,
}
