command! MarkdownRunner lua require'markdown_runner'.runNormal()
" command! MarkdownRunnerInsert lua require'markdown_runner'.runInsert()

if !exists("g:markdown_runners")
  let g:markdown_runners = {
        \ '': getenv('SHELL'),
        \ 'js': 'node',
        \ 'javascript': 'node',
        \ }
endif

" if !exists("g:markdown_runner_populate_location_list")
"   let g:markdown_runner_populate_location_list = 0
" endif
