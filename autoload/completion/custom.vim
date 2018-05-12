fu! completion#custom#easy_c_x_c_p() abort "{{{1
    let cot_save = &cot
    set cot-=noinsert
    " Warning: Keep the timer.{{{
    "
    " Do NOT install an autocmd listening to `CompleteDone`.
    " Because,  for   some  reason,  the   first  time  you  complete   a  word,
    " `CompleteDone` is not fired.
    " As a result, 'cot' would not be restored by the autocmd.
    "}}}
    call timer_start(0, {-> execute('let &cot = '.string(cot_save))})
    return "\<c-x>\<c-p>"
endfu

fu! completion#custom#signature() abort "{{{1
    let func_name = matchstr(getline('.'), '\<\w\+\ze()\?\%'.col('.').'c')
    if empty(func_name)
        return ''
    endif

    let signature = get(filter(readfile($VIMRUNTIME.'/doc/eval.txt'),
    \                          {i,v -> v =~ '^'.func_name.'('}),
    \                   0, '')
    " needed, for example, for `deepcopy()`
    let signature = matchstr(signature, '.\{-})')
    if empty(signature)
        return ''
    endif

    let new_line = substitute(getline('.'), func_name.'\%[()]', signature, '')
    call timer_start(0, {-> setline('.', new_line)})
    return ''
endfu
