:lua require('nvim-biscuits')

highlight default BiscuitColor ctermfg=gray guifg=gray

augroup NVIM_BISCUITS
    autocmd!
    autocmd BufEnter * :lua require('nvim-biscuits').BufferAttach()
augroup END
