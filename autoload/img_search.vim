vim9script

const TMP_DIR = expand('~/.vim/img-search')
const URL_FILE = TMP_DIR .. '/url.txt'

var window: dict<number>

export def SearchImage(mode: string)
    if !exists('g:img_search_api_key') || !exists('g:img_search_engine_id')
        echoerr 'Both g:img_search_api_key and g:img_search_engine_id are required'
        return
    endif

    var searchword = ''
    if mode ==# 'normal'
        searchword = expand('<cword>')
    elseif mode ==# 'visual'
        searchword = GetSelectedWord()
    else
        echoerr 'Invalid mode'
    endif

    if searchword == ''
        return
    endif

    const urls = GetImageUrls(searchword)
    SaveUrlFile(urls)

    ShowImage(1)
enddef

export def ShowImage(idx: number)
    if !filereadable(URL_FILE)
        return
    endif

    const url = readfile(URL_FILE)->get(idx, '')
    if url == ''
        return
    endif

    const sixel = system(printf("curl -s '%s' | convert - -resize '768x432>' jpg:- | img2sixel", url))
    OpenWindow()
    echoraw(printf("\x1b[%d;%dH%s", window.row, window.col, sixel))
enddef

export def ClearImage()
    echoraw(printf("\x1b[%d;%dH\x1b[J", window.row, window.col))
    win_execute(window.id, 'close')
enddef

def GetSelectedWord(): string
    const REG = '"'
    execute 'normal! "' .. REG .. 'y'
    return getreg(REG)->trim(" \t")
enddef

def GetImageUrls(query: string): list<string>
    const url = printf('https://www.googleapis.com/customsearch/v1?key=%s&cx=%s&searchType=image&q=%s',
        g:img_search_api_key, g:img_search_engine_id, query)

    try
        final res: dict<any> = printf("curl -s '%s'", url)->system()->json_decode()
        return res.items->map((key, item) => item.link)
    catch
        echoerr 'Error: ' .. v:exception
    endtry

    return []
enddef

def SaveUrlFile(urls: list<string>)
    if !isdirectory(TMP_DIR)
        mkdir(TMP_DIR, 'p')
    endif

    writefile(urls, URL_FILE)
enddef

def OpenWindow()
    execute "new +set\\ nonumber"

    const winid = win_getid()
    const pos = screenpos(winid, 1, 1)
    window = {
        id: winid,
        row: pos.row,
        col: pos.col,
    }

    silent! wincmd p
enddef
