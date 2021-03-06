vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

import Catch from 'lg.vim'

def completion#spel#suggest(): string #{{{1
    var word_to_complete: string = getline('.')
        ->matchstr('\k\+\%' .. col('.') .. 'c')
    var badword: list<string> = spellbadword(word_to_complete)
    var matches: list<string> = !empty(badword[1])
        ?     spellsuggest(badword[0])
        :     []

    var from_where: number = col('.') - strlen(word_to_complete)

    if !empty(matches)
        complete(from_where, matches)
    endif
    return ''
enddef

def completion#spel#fix(): string #{{{1
    # don't break undo sequence:
    #
    #    - it seems messed up (performs an undo then a redo which gets us in a weird state)
    #    - not necessary here, Vim already breaks the undo sequence

    # Alternative:
    #
    #     var winview: dict<number> = winsaveview()
    #     norm! [S1z=
    #     norm! `^
    #     winrestview(winview)

    var spell_save: bool = &l:spell
    var winid: number = win_getid()
    var bufnr: number = bufnr('%')
    setl spell
    try
        var before_cursor: string = getline('.')
            ->matchstr('.*\%' .. col('.') .. 'c')
        var words: list<string> = split(before_cursor,
            '\%('
            # don't eliminate a keyword nor a single quote when you split the line
            .. '\%(\k\|''\)\@!'
            .. '.\)\+'
            )->reverse()

        var badword: string
        var suggestion: string
        var found_a_badword: bool = false
        for word in words
            badword = spellbadword(word)->get(0, '')
            if empty(badword)
                continue
            endif
            suggestion = spellsuggest(badword)->get(0, '')
            if empty(suggestion)
                continue
            else
                found_a_badword = true
                break
            endif
        endfor

        if found_a_badword
            if exists('#User#AddToUndolistI')
                do <nomodeline> User AddToUndolistI
            endif
            var new_line: string = getline('.')
                ->substitute('\V\<' .. badword .. '\>', suggestion, 'g')
            FixWord = () => setline('.', new_line)
            au SafeState * ++once FixWord()
        endif
    catch
        Catch()
        return ''
    finally
        if winbufnr(winid) == bufnr
            var tabnr: number
            var winnr: number
            [tabnr, winnr] = win_id2tabwin(winid)
            settabwinvar(tabnr, winnr, '&spell', spell_save)
        endif
    endtry
    # Break undo sequence before `setline()` edits the line, so that we can undo
    # if the fix is wrong.
    return "\<c-g>u"
enddef

var FixWord: func
