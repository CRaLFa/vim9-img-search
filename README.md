# vim9-img-search

Image search plugin for Vim 9

## Installation

Using [dein.vim](https://github.com/Shougo/dein.vim) plugin manager:

```vim
dein#add('CRaLFa/vim9-img-search')
```

## Variables

* `g:img_search_api_key`: API key for Google Custom Search API (required)
* `g:img_search_engine_id`: Search engine ID for Google Custom Search API (required)
* `g:img_search_max_width`: Max image width (default: 480)
* `g:img_search_max_height`: Max image height (default: 270)

### Example

In `~/.vimrc`:

```vim
let g:img_search_api_key = 'AIzaSxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
let g:img_search_engine_id = '7e1ffxxxxxxxxxxxx'
let g:img_search_max_width = 768
let g:img_search_max_height = 432
```

## Usage

Press `Alt` + `i` to search image using the word under the cursor in Normal mode or the string in the selected range in Visual mode as the keyword.
When the search is completed, a new window will open in the lower half of the screen to display the result images.

The maximum number of search results is 10.
`Alt` + `b` displays the previous image, and `Alt` + `n` displays the next image.

The URL of the image being displayed is set in the unnamed register and can be pasted with `p` or `P`.

Press `Alt` + `j` to close the search results window.
