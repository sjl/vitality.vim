" ============================================================================
" File:        vitality.vim
" Description: Make Vim play nicely with iTerm2 and tmux.
" Maintainer:  Steve Losh <steve@stevelosh.com>
" License:     MIT/X11
" ============================================================================

" Init {{{

if has('gui_running')
    finish
endif

if !exists('g:vitality_debug') && (exists('loaded_vitality') || &cp)
    finish
endif

let loaded_vitality = 1

if !exists('g:vitality_fix_cursor') " {{{
    let g:vitality_fix_cursor = 1
endif " }}}
if !exists('g:vitality_fix_focus') " {{{
    let g:vitality_fix_focus = 1
endif " }}}
if !exists('g:vitality_change_colors') " {{{
    let g:vitality_change_colors = 1
endif " }}}
if !exists('g:vitality_color_insertmode') " {{{
  let g:vitality_color_insertmode = "green"
endif " }}}
let s:cursor_color_insertmode = "\<Esc>]12;". g:vitality_color_insertmode . "\x7"
if !exists('g:vitality_color_normalmode') " {{{
    let g:vitality_color_normalmode = "default"
endif " }}}
let s:cursor_color_default = "\<Esc>]112\007"
if g:vitality_color_normalmode == 'default'
  let s:cursor_color_normalmode = s:cursor_color_default
else
  let s:cursor_color_normalmode = "\<Esc>]12;". g:vitality_color_normalmode . "\x7"
endif

let s:inside_xterm = exists('$XTERM_VERSION')
let s:inside_iterm = exists('$ITERM_PROFILE')
let s:inside_tmux = exists('$TMUX')

" }}}

function! s:WrapForTmux(s) " {{{
    " To escape a sequence through tmux:
    "
    " * Wrap it in these sequences.
    " * Any <Esc> characters inside it must be doubled.
    let tmux_start = "\<Esc>Ptmux;"
    let tmux_end   = "\<Esc>\\"

    return tmux_start . substitute(a:s, "\<Esc>", "\<Esc>\<Esc>", 'g') . tmux_end
endfunction " }}}

function! s:Vitality() " {{{
    " Escape sequences {{{

    " iTerm2 allows you to turn "focus reporting" on and off with these
    " sequences.
    "
    " When reporting is on, iTerm2 will send <Esc>[O when the window loses focus
    " and <Esc>[I when it gains focus.
    "
    " TODO: Look into how this works with iTerm tabs.  Seems a bit wonky.
    let enable_focus_reporting  = "\<Esc>[?1004h"
    let disable_focus_reporting = "\<Esc>[?1004l"

    " These sequences save/restore the screen.
    " They should NOT be wrapped in tmux escape sequences for some reason!
    let save_screen    = "\<Esc>[?1049h"
    let restore_screen = "\<Esc>[?1049l"

    if s:inside_iterm
      " These sequences tell iTerm2 to change the cursor shape to a bar or block.
      let cursor_to_insertmode   = "\<Esc>]50;CursorShape=1\x7"
      let cursor_to_normalmode = "\<Esc>]50;CursorShape=0\x7"
    elseif s:inside_xterm
      " These sequences tell xterm to change the cursor shape to a blinking underline
      let cursor_to_insertmode   = "\<Esc>[3 q"
      let cursor_to_normalmode = "\<Esc>[1 q"
    endif

    if s:inside_tmux
        " Some escape sequences (but not all, lol) need to be properly escaped
        " to get them through tmux without being eaten.

        let enable_focus_reporting = s:WrapForTmux(enable_focus_reporting)
        let disable_focus_reporting = s:WrapForTmux(disable_focus_reporting)

        let cursor_to_insertmode = s:WrapForTmux(cursor_to_insertmode)
        let cursor_to_normalmode = s:WrapForTmux(cursor_to_normalmode)

        let s:cursor_color_normalmode = s:WrapForTmux(s:cursor_color_normalmode)
        let s:cursor_color_insertmode = s:WrapForTmux(s:cursor_color_insertmode)
        let s:cursor_color_default    = s:WrapForTmux(s:cursor_color_default)
    endif

    " }}}
    " Startup/shutdown escapes {{{

    " When starting Vim, enable focus reporting and save the screen.
    " When exiting Vim, disable focus reporting and save the screen.
    "
    " The "focus/save" and "nofocus/restore" each have to be in this order.
    " Trust me, you don't want to go down this rabbit hole.  Just keep them in
    " this order and no one gets hurt.
    if g:vitality_fix_focus
        let &t_ti = s:cursor_color_normalmode . enable_focus_reporting . save_screen
        let &t_te = s:cursor_color_default . disable_focus_reporting . restore_screen
    endif

    " }}}
    " Insert enter/leave escapes {{{

    if g:vitality_fix_cursor
        " When entering insert mode, change the cursor to a bar.
        let &t_SI .= cursor_to_insertmode
        " When exiting insert mode, change it back to a block.
        let &t_EI .= cursor_to_normalmode
    endif
    if g:vitality_change_colors
        let &t_SI .= s:cursor_color_insertmode
        let &t_EI .= s:cursor_color_normalmode
    endif

    " }}}
    " Focus reporting keys/mappings {{{
    if g:vitality_fix_focus
        " Map some of Vim's unused keycodes to the sequences iTerm2 is going to send
        " on focus lost/gained.
        "
        " If you're already using f24 or f25, change them to something else.  Vim
        " supports up to f37.
        "
        " Doing things this way is nicer than just mapping the raw sequences
        " directly, because Vim won't hang after a bare <Esc> waiting for the rest
        " of the mapping.
        execute "set <f24>=\<Esc>[O"
        execute "set <f25>=\<Esc>[I"

        " Handle the focus gained/lost signals in each mode separately.
        "
        " The goal is to fire the autocmd and restore the state as cleanly as
        " possible.  This is easy for some modes and hard/impossible for others.
        "
        " EXAMPLES:
        nnoremap <silent> <f24> :doautocmd FocusLost %<cr>
        nnoremap <silent> <f25> :doautocmd FocusGained %<cr>

        onoremap <silent> <f24> <esc>:silent doautocmd FocusLost %<cr>
        onoremap <silent> <f25> <esc>:silent doautocmd FocusGained %<cr>

        vnoremap <silent> <f24> <esc>:silent doautocmd FocusLost %<cr>gv
        vnoremap <silent> <f25> <esc>:silent doautocmd FocusGained %<cr>gv

        inoremap <silent> <f24> <c-o>:silent doautocmd FocusLost %<cr>
        inoremap <silent> <f25> <c-o>:silent doautocmd FocusGained %<cr>

        cnoremap <silent> <f24> <c-\>e<SID>DoCmdFocusLost()<cr>
        cnoremap <silent> <f25> <c-\>e<SID>DoCmdFocusGained()<cr>
    endif

    " }}}
endfunction " }}}

function s:DoCmdFocusLost()
    let cmd = getcmdline()
    let pos = getcmdpos()

    silent doautocmd FocusLost %

    call setcmdpos(pos)
    return cmd
endfunction

function s:DoCmdFocusGained()
    let cmd = getcmdline()
    let pos = getcmdpos()

    silent doautocmd FocusGained %

    call setcmdpos(pos)
    return cmd
endfunction

if s:inside_iterm || s:inside_xterm
    call s:Vitality()
endif
