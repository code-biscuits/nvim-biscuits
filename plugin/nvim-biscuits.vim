:lua require('nvim-biscuits')

highlight default BiscuitColor ctermfg=gray
highlight default link BiscuitColorRust BiscuitColor

augroup NVIM_BISCUITS
    autocmd!
    autocmd BufEnter * :lua require('nvim-biscuits').BufferAttach()
augroup END
