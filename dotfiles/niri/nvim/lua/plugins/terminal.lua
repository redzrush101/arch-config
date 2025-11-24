return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = 15,
      open_mapping = [[<c-\>]],
      direction = "horizontal",
      close_on_exit = false, -- Keep window open to see errors
      auto_scroll = true,
    })

    local Terminal = require('toggleterm.terminal').Terminal

    local function compile_and_run()
      vim.cmd("write") -- Save the file automatically before running
      
      local file = vim.fn.expand('%')
      local output = vim.fn.expand('%:r')
      -- Command: gcc file.c -o file && ./file
      local cmd = string.format('gcc -g -Wall "%s" -o "%s" && "./%s"', file, output, output)
      
      local term = Terminal:new({
        cmd = cmd,
        direction = "horizontal",
        close_on_exit = false,
      })
      term:toggle()
    end

    vim.keymap.set("n", "<leader>cc", compile_and_run, { desc = "Compile and Run C" })
  end,
}
