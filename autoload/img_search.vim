vim9script

const TMP_DIR = expand('~/.vim/img-search')
const URL_FILE = TMP_DIR .. '/url.txt'
const REG_TMP = '"'

var window: dict<number>
var idx = 0

export def SearchImage(mode: string)
    if !exists('g:img_search_api_key') || !exists('g:img_search_engine_id')
        echo 'Both g:img_search_api_key and g:img_search_engine_id are required'
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

    if empty(searchword)
        return
    endif

    const urls = GetImageUrls(searchword)
    SaveUrlFile(urls)

    idx = 0
    ShowImage()
enddef

export def ShowNextImage()
    if idx > 9
        echo 'No image'
        return
    endif

    idx += 1

    ClearImage()
    ShowImage()
enddef

export def ShowPrevImage()
    if idx <= 0
        echo 'No image'
        return
    endif

    idx -= 1

    ClearImage()
    ShowImage()
enddef

export def ClearImage()
    if empty(window)
        return
    endif

    echoraw(printf("\x1b[%d;%dH\x1b[J", window.row, window.col))
    win_execute(window.id, 'close')

    window = {}
enddef

def ShowImage()
    if !filereadable(URL_FILE)
        return
    endif

    const url = readfile(URL_FILE)->get(idx, '')
    if empty(url)
        echo 'No image'
        return
    endif

    setreg(REG_TMP, url)

    const sixelfile = printf('%s/%d.sixel', TMP_DIR, idx)
    var sixel: string

    if filereadable(sixelfile)
        sixel = readfile(sixelfile)->join("\n")
    else
        const maxwidth = exists('g:img_search_max_width') ? g:img_search_max_width : 480
        const maxheight = exists('g:img_search_max_height') ? g:img_search_max_height : 270

        sixel = printf("set -o pipefail; curl -s '%s' | convert - -resize '%dx%d>' jpg:- | img2sixel",
            url, maxwidth, maxheight)->system()
        if v:shell_error
            echo 'Cannot show image'
            return
        endif

        writefile([sixel], sixelfile)
    endif

    window = OpenWindow()
    echoraw(printf("\x1b[%d;%dH%s", window.row, window.col, sixel))
enddef

def GetSelectedWord(): string
    execute 'normal! "' .. REG_TMP .. 'y'
    return getreg(REG_TMP)->trim(" \t")->substitute('[\r\n]\+', ' ', 'g')
enddef

def GetImageUrls(query: string): list<string>
    const encodedquery = system('jq -Rr @uri', query)->trim()
    const url = printf('https://www.googleapis.com/customsearch/v1?key=%s&cx=%s&searchType=image&q=%s',
        g:img_search_api_key, g:img_search_engine_id, encodedquery)

    try
        final res: dict<any> = printf("curl -s '%s'", url)->system()->json_decode()
        return res.items
            ->map((_, item) => item.link)
            ->filter((_, link) => link->tolower()->match('\.\(png\|jpg\|jpeg\)$') >= 0)
    catch
        echoerr v:exception
    endtry

    return []
enddef

def SaveUrlFile(urls: list<string>)
    if !isdirectory(TMP_DIR)
        mkdir(TMP_DIR, 'p')
    endif

    glob(TMP_DIR .. '/*.sixel')->split("\n")->map('delete(v:val)')

    writefile(urls, URL_FILE)
enddef

def OpenWindow(): dict<number>
    silent new +set\ nonumber _IMG_SEARCH_

    const winid = win_getid()
    const pos = screenpos(winid, 1, 1)

    silent! wincmd p
    redraw

    return {
        id: winid,
        row: pos.row,
        col: pos.col,
    }
enddef
