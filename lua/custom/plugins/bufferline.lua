return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = 'nvim-tree/nvim-web-devicons',
  config = function()
    vim.opt.termguicolors = true
    require('bufferline').setup {
      options = {
        mode = 'buffers',
        diagnostics = 'nvim_lsp',
        indicator = {
          icon = '▶▶',
          style = 'icon',
        },
        offsets = {
          {
            filetype = 'Neo-tree',
            text = 'File Explorer',
            text_align = 'center',
            separator = true,
          },
        },
        show_buffer_close_icons = true,
        show_close_icon = false,
        -- separator_style = 'slant',
      },
    }
  end,
}
