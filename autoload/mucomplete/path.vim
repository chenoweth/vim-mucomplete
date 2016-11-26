fu! mucomplete#path#complete() abort

    let l:prefix = matchstr(strpart(getline('.'), 0, col('.') - 1), '\f\%(\f\|\s\)*$')

    while strlen(l:prefix) > 0 " Try to find an existing path (consider paths with spaces, too)

        if l:prefix ==# '~'

            let l:prefix = glob('~', 0, 1, 1)
            if !empty(l:prefix)
                call complete(col('.') - 1, map(l:prefix, '{ "word": v:val, "menu": "[dir]" }'))
            endif
            return ''

        else

            let l:files = glob(l:prefix.'*', 0, 1, 1)

            if !empty(l:files)
                call complete(col('.') - len(fnamemodify(l:prefix, ":t")), map(l:files,
                            \  '{
                            \      "word": fnamemodify(v:val, ":t"),
                            \      "menu": (isdirectory(v:val) ? "[dir]" : "[file]")
                            \   }'
                            \ ))

                return ''
            endif
        endif
        let l:prefix = matchstr(l:prefix, '\s\zs\f.*$', 1) " Next potential path
    endwhile

    return ''
endfu
