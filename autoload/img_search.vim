vim9script

const TMP_DIR = expand('~/.vim/img-search')
const URL_FILE = TMP_DIR .. '/url.txt'

const REG_WIN = 'w'
const REG_IMG = 'i'
const REG_TMP = '"'

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

    ShowImage(0)
enddef

export def ShowNextImage()
    const s = getreg(REG_IMG)
    const idx = empty(s) ? 0 : eval(s)

    if idx > 9
        echo 'No image'
        return
    endif

    ClearImage()
    ShowImage(idx + 1)
enddef

export def ShowBackImage()
    const s = getreg(REG_IMG)
    const idx = empty(s) ? 0 : eval(s)

    if idx <= 0
        echo 'No image'
        return
    endif

    ClearImage()
    ShowImage(idx - 1)
enddef

export def ClearImage()
    const s = getreg(REG_WIN)
    if empty(s)
        return
    endif

    const window = eval(s)
    echoraw(printf("\x1b[%d;%dH\x1b[J", window.row, window.col))
    win_execute(window.id, 'close')

    setreg(REG_WIN, '')
enddef

def ShowImage(idx: number)
    setreg(REG_IMG, string(idx))

    const sixelfile = printf('%s/%d.sixel', TMP_DIR, idx)
    var sixel: string

    if filereadable(sixelfile)
        sixel = readfile(sixelfile)->join("\n")
    else
        if !filereadable(URL_FILE)
            return
        endif

        const url = readfile(URL_FILE)->get(idx, '')
        if empty(url)
            echo 'No image'
            return
        endif

        sixel = printf("set -o pipefail; curl -s '%s' | convert - -resize '768x432>' jpg:- | img2sixel", url)
            ->system()
        if v:shell_error
            echo 'Failed to display image'
            return
        endif

        writefile([sixel], sixelfile)
    endif

    const window = OpenWindow()
    echoraw(printf("\x1b[%d;%dH%s", window.row, window.col, sixel))

    setreg(REG_WIN, string(window))
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
