return {
  'mistweaverco/kulala.nvim',
  keys = {
    { '<leader>rs', desc = '[S]end request' },
    { '<leader>ra', desc = 'Send [a]ll requests' },
    { '<leader>rb', desc = 'Open scratchpad' },
  },
  ft = { 'http', 'rest' },
  opts = {
    global_keymaps = true,
    global_keymaps_prefix = '<leader>r',
    kulala_keymaps_prefix = '',
  },
}
