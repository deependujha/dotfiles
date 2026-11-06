# Vim cheatsheet

## Navigation

| Keys | Action |
|------|--------|
| `h j k l` | left / down / up / right |
| `w` / `b` / `e` | next word / previous word / end of word |
| `0` / `^` / `$` | line start / first non-blank / line end |
| `gg` / `G` / `42G` | top / bottom / line 42 |
| `Ctrl-d` / `Ctrl-u` | half page down / up |
| `%` | jump to matching bracket |
| `f{c}` / `t{c}` | to / just before the next `c` on the line (`;` repeats) |
| `Ctrl-o` / `Ctrl-i` | jump back / forward |
| `5j` | 5 lines down (relative numbers make this easy) |

## Editing

| Keys | Action |
|------|--------|
| `i` / `a` | insert before / after cursor |
| `I` / `A` | insert at line start / end |
| `o` / `O` | new line below / above |
| `x` / `dd` / `D` | delete char / line / to end of line |
| `dw` / `ciw` / `ci"` | delete word / change inner word / change inside quotes |
| `cc` / `C` | change line / to end of line |
| `r{c}` | replace one char |
| `u` / `Ctrl-r` | undo / redo (undo persists across sessions) |
| `.` | repeat last change |
| `>>` / `<<` | indent / dedent line |
| `J` | join line below |

## Copy / paste

With this config, yanks also go to the system clipboard.

| Keys | Action |
|------|--------|
| `yy` / `yw` / `y$` | yank line / word / to end of line |
| `p` / `P` | paste after / before |
| `"+p` | paste explicitly from system clipboard |
| `:set paste` | before pasting with the terminal (avoids auto-indent); `:set nopaste` after |

## Visual mode

| Keys | Action |
|------|--------|
| `v` / `V` / `Ctrl-v` | character / line / block selection |
| `y` / `d` / `c` | yank / delete / change selection |
| `>` / `<` | indent / dedent selection |
| `gv` | reselect last selection |
| `Ctrl-v` … `I` … `Esc` | insert text on every selected line |

## Search and replace

| Keys | Action |
|------|--------|
| `/text` / `?text` | search forward / backward |
| `n` / `N` | next / previous match |
| `*` / `#` | search word under cursor forward / backward |
| `Esc` | clear search highlight (mapped in this config) |
| `:s/old/new/g` | replace in current line |
| `:%s/old/new/g` | replace in whole file |
| `:%s/old/new/gc` | replace with confirmation |
| `:'<,'>s/old/new/g` | replace in visual selection |

Search is case-insensitive unless the pattern has a capital letter.

## Saving and quitting

| Command | Action |
|---------|--------|
| `:w` / `:w name` | save / save as |
| `:q` / `:q!` | quit / quit discarding changes |
| `:wq` or `:x` or `ZZ` | save and quit |
| `:qa` / `:wqa` | quit all / save and quit all |
| `:e file` / `:e!` | open file / reload discarding changes |

## Splits and buffers

| Keys | Action |
|------|--------|
| `:sp file` / `:vs file` | horizontal split (opens below) / vertical split (opens right) |
| `Ctrl-w h/j/k/l` | move between splits |
| `Ctrl-w =` | equalize split sizes |
| `Ctrl-w q` / `Ctrl-w o` | close split / close all others |
| `:ls` / `:b N` / `:bn` / `:bp` | list / go to / next / previous buffer |
