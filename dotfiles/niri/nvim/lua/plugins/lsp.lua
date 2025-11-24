return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp", -- Connects LSP to auto-completion
    },
    config = function()
      -- 1. Setup Mason (the installer)
      require("mason").setup()

      -- 2. Setup Mason-LSPConfig (the bridge)
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd" }, -- Auto-install C language server
        
        -- This 'handlers' function is the magic that makes it work automatically
        handlers = {
          function(server_name)
            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
            })
          end,
          
          -- Custom configuration specifically for C/C++ (clangd)
          ["clangd"] = function()
            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            require("lspconfig").clangd.setup({
              capabilities = capabilities,
              cmd = { 
                "clangd", 
                "--background-index", 
                "--clang-tidy", 
                "--header-insertion=iwyu" 
              },
            })
          end,
        }
      })

      -- 3. Keymaps (Assign these only when LSP is active)
      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP actions',
        callback = function(event)
          local opts = { buffer = event.buf }
          
          -- Navigation
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)     -- Go to definition
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)           -- Hover Info
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts) -- Rename variable
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts) -- Code Action
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)     -- Find References
        end
      })
    end,
  },
}
