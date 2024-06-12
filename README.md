# dementia

Small neovim plugin to lookup and quickly save forgotten files

## Lua installation

```lua
require('lazy').setup({
  {
    'WRadoslaw/dementia',
    requires = { {'nvim-telescope/telescope.nvim'} },
    config = function()
        local dementia = require('dementia')
        local keymap = vim.keymap

        keymap.set('n', '<leader>ms', ':lua require("myplugin").show_modified_buffers()<CR>', { noremap = true, silent = true })
    end
  },
})
```
