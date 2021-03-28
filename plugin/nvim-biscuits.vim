:lua require('nvim-biscuits')

augroup NVIM_BISCUITS
    autocmd!
    autocmd BufEnter * :lua require('nvim-biscuits').BufferAttach()
augroup END
