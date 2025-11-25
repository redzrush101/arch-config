return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = 15,
      open_mapping = [[<c-\>]],
      direction = "horizontal",
      close_on_exit = false,
      auto_scroll = true,
      shade_terminals = true,
      shading_factor = 2,
      persist_size = true,
      persist_mode = true,
    })

    local Terminal = require("toggleterm.terminal").Terminal

    -- Compile and run C
    local function compile_and_run_c()
      vim.cmd("write")
      local file = vim.fn.expand("%")
      local output = vim.fn.expand("%:r")
      local cmd = string.format('gcc -g -Wall -Wextra "%s" -o "%s" && "./%s"', file, output, output)

      local term = Terminal:new({
        cmd = cmd,
        direction = "horizontal",
        close_on_exit = false,
      })
      term:toggle()
    end

    -- Compile and run Zig
    local function compile_and_run_zig()
      vim.cmd("write")
      local file = vim.fn.expand("%")
      local cmd = string.format("zig run %s", file)

      local term = Terminal:new({
        cmd = cmd,
        direction = "horizontal",
        close_on_exit = false,
      })
      term:toggle()
    end

    vim.keymap.set("n", "<leader>cc", compile_and_run_c, { desc = "Compile and Run C" })
    vim.keymap.set("n", "<leader>cz", compile_and_run_zig, { desc = "Compile and Run Zig" })
  end,
}
