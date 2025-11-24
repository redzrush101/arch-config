return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500 -- Time in ms to wait before the menu shows up (0.5 seconds)
  end,
  opts = {
    -- You can customize the look here, but defaults are great
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- Add labels to your specific key groups so they look nice in the menu
    wk.add({
      { "<leader>c", group = "Compile/Code" }, -- Labels <space>c as "Compile/Code"
      { "<leader>r", group = "Rename" },       -- Labels <space>r as "Rename"
    })
  end,
}
