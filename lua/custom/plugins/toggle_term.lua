function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set('t', '<C-n>', '<cmd>ToggleTerm<CR>')
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
  vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd 'autocmd! TermOpen term://* lua set_terminal_keymaps()'

return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      on_create = function(term)
        local cwd = vim.fn.getcwd()
        local venv_activate = cwd .. '/venv/bin/activate'

        if vim.fn.filereadable(venv_activate) == 1 then
          term:send('ve', true)
        end
      end,
    },
  },
}
