# Vim/Neovim Cheatsheet for Coding

A comprehensive guide to essential Vim/Neovim commands and behaviors for writing code.

**Leader Key**: `<Space>`

---

## Table of Contents

1. [Modes](#modes)
2. [Movement Basics](#movement-basics)
3. [Editing Basics](#editing-basics)
4. [Text Objects](#text-objects)
5. [Search and Replace](#search-and-replace)
6. [File Operations](#file-operations)
7. [Window Management](#window-management)
8. [Buffer Management](#buffer-management)
9. [Visual Mode](#visual-mode)
10. [Copy, Cut, Paste](#copy-cut-paste)
11. [Undo and Redo](#undo-and-redo)
12. [Macros](#macros)
13. [Coding Essentials](#coding-essentials)
14. [Quick Tips](#quick-tips)

---

## Modes

Vim has different modes for different tasks:

| Mode | Description | How to Enter | How to Exit |
|------|-------------|--------------|-------------|
| **Normal** | Navigate and execute commands | Press `<Esc>` | Default mode |
| **Insert** | Type and edit text | `i`, `a`, `o`, etc. | Press `<Esc>` |
| **Visual** | Select text | `v`, `V`, `<C-v>` | Press `<Esc>` |
| **Command** | Execute Ex commands | `:` | Press `<Enter>` or `<Esc>` |
| **Terminal** | Interact with terminal | `:terminal` | `<Esc><Esc>` |

**Key Concept**: Always return to Normal mode with `<Esc>` when you're done with an action.

---

## Movement Basics

### Character-Level Movement (Normal Mode)

| Key | Description |
|-----|-------------|
| `h` | Move left |
| `j` | Move down |
| `k` | Move up |
| `l` | Move right |
| `w` | Jump forward to start of next word |
| `b` | Jump backward to start of previous word |
| `e` | Jump forward to end of word |
| `0` | Jump to start of line |
| `^` | Jump to first non-blank character of line |
| `$` | Jump to end of line |
| `gg` | Go to first line of file |
| `G` | Go to last line of file |
| `{number}G` | Go to line {number} (e.g., `42G` goes to line 42) |

### Screen Movement

| Key | Description |
|-----|-------------|
| `<C-u>` | Scroll up half screen |
| `<C-d>` | Scroll down half screen |
| `<C-b>` | Scroll up full screen (page up) |
| `<C-f>` | Scroll down full screen (page down) |
| `zz` | Center current line on screen |
| `zt` | Move current line to top of screen |
| `zb` | Move current line to bottom of screen |

### Code-Specific Movement

| Key | Description |
|-----|-------------|
| `%` | Jump to matching bracket/parenthesis/brace |
| `{` | Jump to previous blank line (paragraph up) |
| `}` | Jump to next blank line (paragraph down) |
| `gd` | Go to local definition (LSP) |
| `<C-o>` | Jump back to previous location |
| `<C-i>` | Jump forward to next location |

---

## Editing Basics

### Entering Insert Mode

| Key | Description |
|-----|-------------|
| `i` | Insert before cursor |
| `a` | Insert after cursor (append) |
| `I` | Insert at start of line |
| `A` | Insert at end of line (append) |
| `o` | Open new line below and insert |
| `O` | Open new line above and insert |
| `s` | Delete character under cursor and insert |
| `S` | Delete entire line and insert |
| `C` | Delete from cursor to end of line and insert |

### Deleting Text (Normal Mode)

| Key | Description |
|-----|-------------|
| `x` | Delete character under cursor |
| `X` | Delete character before cursor (backspace) |
| `dd` | Delete entire line |
| `D` | Delete from cursor to end of line |
| `dw` | Delete word from cursor |
| `db` | Delete word backward |
| `d$` | Delete to end of line |
| `d0` | Delete to start of line |
| `dG` | Delete to end of file |
| `dgg` | Delete to start of file |

### Changing Text (Normal Mode)

**Change = Delete + Insert Mode**

| Key | Description |
|-----|-------------|
| `cc` | Change entire line |
| `C` | Change from cursor to end of line |
| `cw` | Change word from cursor |
| `ciw` | Change inner word (cursor can be anywhere in word) |
| `ci"` | Change text inside quotes |
| `ci(` | Change text inside parentheses |
| `ci{` | Change text inside braces |
| `cit` | Change inner tag (HTML/XML) |

### Repeating Actions

| Key | Description |
|-----|-------------|
| `.` | Repeat last change |
| `{number}{command}` | Repeat command {number} times (e.g., `3dd` deletes 3 lines) |

---

## Text Objects

Text objects let you operate on semantic units of text.

### Syntax

- `{operator}` + `{a/i}` + `{object}`
  - **Operator**: `d` (delete), `c` (change), `y` (yank/copy), `v` (visual select)
  - **a** (around): Includes surrounding characters (e.g., quotes, brackets)
  - **i** (inner): Excludes surrounding characters
  - **Object**: `w` (word), `s` (sentence), `p` (paragraph), `"` (quotes), `(` `[` `{` (brackets), `t` (tag)

### Examples

| Command | Description |
|---------|-------------|
| `diw` | Delete inner word |
| `daw` | Delete word including surrounding whitespace |
| `ci"` | Change text inside double quotes |
| `ca"` | Change text including the double quotes |
| `di(` | Delete text inside parentheses |
| `da(` | Delete text including parentheses |
| `yi{` | Yank (copy) text inside braces |
| `vit` | Visual select inner HTML tag |
| `dip` | Delete inner paragraph |

### Common Text Objects

| Object | Description |
|--------|-------------|
| `w` | Word |
| `s` | Sentence |
| `p` | Paragraph |
| `"` | Double-quoted string |
| `'` | Single-quoted string |
| `` ` `` | Backtick string |
| `(` or `)` | Parentheses block |
| `[` or `]` | Square brackets block |
| `{` or `}` | Curly braces block |
| `<` or `>` | Angle brackets block |
| `t` | HTML/XML tag |

---

## Search and Replace

### Searching

| Key | Description |
|-----|-------------|
| `/pattern` | Search forward for pattern |
| `?pattern` | Search backward for pattern |
| `n` | Jump to next search result |
| `N` | Jump to previous search result |
| `*` | Search forward for word under cursor |
| `#` | Search backward for word under cursor |
| `<Esc>` | Clear search highlights |

### Replace (Substitute)

**Syntax**: `:s/old/new/flags`

| Command | Description |
|---------|-------------|
| `:s/old/new/` | Replace first occurrence in current line |
| `:s/old/new/g` | Replace all occurrences in current line |
| `:%s/old/new/g` | Replace all occurrences in entire file |
| `:%s/old/new/gc` | Replace all with confirmation prompts |
| `:10,20s/old/new/g` | Replace in lines 10-20 |

**Tip**: Use `<leader>S` to open Spectre for advanced find-and-replace with preview.

---

## File Operations

### Opening Files

| Command | Description |
|---------|-------------|
| `:e filename` | Edit (open) a file |
| `:e!` | Reload current file (discard changes) |
| `<leader>ff` | Find files (Telescope) |
| `<leader>f.` | Recent files (Telescope) |

### Saving Files

| Command | Description |
|---------|-------------|
| `:w` | Write (save) file |
| `:w filename` | Save as filename |
| `:wa` | Write all open buffers |
| `:wq` | Write and quit |
| `:x` | Write and quit (only if changes made) |

### Quitting

| Command | Description |
|---------|-------------|
| `:q` | Quit (fails if unsaved changes) |
| `:q!` | Quit without saving |
| `:qa` | Quit all windows |
| `:qa!` | Quit all without saving |

---

## Window Management

### Creating Windows

| Key/Command | Description |
|-------------|-------------|
| `<leader>wv` | Split window vertically |
| `<leader>wh` | Split window horizontally |
| `:split` or `:sp` | Horizontal split |
| `:vsplit` or `:vs` | Vertical split |

### Navigating Windows

| Key | Description |
|-----|-------------|
| `<C-h>` | Move to left window |
| `<C-j>` | Move to bottom window |
| `<C-k>` | Move to top window |
| `<C-l>` | Move to right window |
| `<C-w>w` | Cycle through windows |

### Resizing Windows

| Key | Description |
|-----|-------------|
| `<C-w>=` | Equalize window sizes |
| `<C-w>_` | Maximize current window height |
| `<C-w>|` | Maximize current window width |
| `<C-w>+` | Increase window height |
| `<C-w>-` | Decrease window height |
| `<C-w>>` | Increase window width |
| `<C-w><` | Decrease window width |

### Closing Windows

| Key/Command | Description |
|-------------|-------------|
| `<C-w>q` | Close current window |
| `<C-w>o` | Close all other windows (only keep current) |
| `:close` | Close current window |

---

## Buffer Management

Buffers are open files in memory (not necessarily visible).

### Buffer Operations

| Command | Description |
|---------|-------------|
| `:buffers` or `:ls` | List all buffers |
| `:bnext` or `:bn` | Next buffer |
| `:bprev` or `:bp` | Previous buffer |
| `:buffer N` or `:b N` | Switch to buffer number N |
| `:bdelete` or `:bd` | Delete (close) current buffer |
| `<leader>fb` | Find buffers (Telescope) |

---

## Visual Mode

### Entering Visual Mode

| Key | Description |
|-----|-------------|
| `v` | Character-wise visual mode |
| `V` | Line-wise visual mode |
| `<C-v>` | Block-wise visual mode (column selection) |

### Visual Mode Operations

After selecting text in visual mode:

| Key | Description |
|-----|-------------|
| `d` | Delete selection |
| `c` | Change selection (delete and enter insert mode) |
| `y` | Yank (copy) selection |
| `>` | Indent selection right |
| `<` | Indent selection left |
| `=` | Auto-indent selection |
| `u` | Lowercase selection |
| `U` | Uppercase selection |
| `~` | Toggle case |

### Visual Block Mode (Column Editing)

1. Press `<C-v>` to enter visual block mode
2. Move cursor to select columns (use `j`/`k` to select multiple lines)
3. Press `I` to insert at start of selection on all lines
4. Type your text
5. Press `<Esc>` - text appears on all selected lines

**Example**: Add `//` comment to multiple lines at column 0:
- `<C-v>` → Select column with `j` → `I//` → `<Esc>`

---

## Copy, Cut, Paste

### Registers

Vim uses registers (clipboards) for storing yanked/deleted text.

| Register | Description |
|----------|-------------|
| `"` | Unnamed register (default for yank/delete) |
| `0` | Last yank only (not deletes) |
| `+` | System clipboard (copy/paste with OS) |
| `*` | System primary selection (X11) |
| `a-z` | Named registers (e.g., `"ayy` yanks line to register `a`) |

### Yank (Copy)

| Key | Description |
|-----|-------------|
| `yy` | Yank (copy) entire line |
| `Y` | Yank entire line (same as `yy`) |
| `yw` | Yank word |
| `yiw` | Yank inner word |
| `y$` | Yank to end of line |
| `yG` | Yank to end of file |
| `"+yy` | Yank line to system clipboard |

### Paste

| Key | Description |
|-----|-------------|
| `p` | Paste after cursor/line |
| `P` | Paste before cursor/line |
| `"+p` | Paste from system clipboard |

### Cut (Delete to Register)

**Note**: All delete commands (`d`, `dd`, `x`) automatically cut to unnamed register.

| Key | Description |
|-----|-------------|
| `dd` | Cut entire line |
| `D` | Cut from cursor to end of line |
| `x` | Cut character under cursor |

### System Clipboard Integration

**Your config has clipboard enabled**, so `y` and `p` work with system clipboard:
- `yy` yanks to both Vim and system clipboard
- `p` pastes from system clipboard if nothing yanked in Vim
- Can also explicitly use `"+y` and `"+p` for system clipboard

---

## Undo and Redo

| Key | Description |
|-----|-------------|
| `u` | Undo last change |
| `<C-r>` | Redo (undo the undo) |
| `U` | Undo all changes on current line |
| `<leader>u` | Toggle undo tree (visual undo history) |

### Undo Tree

The undo tree plugin lets you navigate non-linear undo history:
- Press `<leader>u` to open undo tree
- Use `j`/`k` to navigate history branches
- Press `<Enter>` to restore that state
- Press `q` to close undo tree

---

## Macros

Macros record and replay sequences of commands.

### Recording a Macro

1. Press `q{register}` to start recording (e.g., `qa` records to register `a`)
2. Perform your actions (movement, editing, etc.)
3. Press `q` to stop recording

### Playing a Macro

| Key | Description |
|-----|-------------|
| `@{register}` | Play macro from register (e.g., `@a`) |
| `@@` | Replay last macro |
| `{number}@{register}` | Replay macro N times (e.g., `10@a`) |

### Example Macro

**Task**: Surround every line with quotes

1. `qa` - Start recording to register `a`
2. `I"` - Insert `"` at start of line
3. `<Esc>A"` - Go to end and append `"`
4. `<Esc>j` - Move to next line
5. `q` - Stop recording
6. `10@a` - Replay on next 10 lines

---

## Coding Essentials

### Indentation

| Key | Description |
|-----|-------------|
| `>>` | Indent line right |
| `<<` | Indent line left |
| `==` | Auto-indent line |
| `gg=G` | Auto-indent entire file |
| `=i{` | Auto-indent inside braces |
| `>` | Indent selection (visual mode) |
| `<` | Unindent selection (visual mode) |

**Tip**: In visual mode, `<` and `>` keep you in visual mode for repeated indenting.

### Comments

| Key | Description |
|-----|-------------|
| `<leader>/` | Toggle line comment (normal mode) |
| `<leader>/` | Toggle comment for selection (visual mode) |

### Code Navigation (LSP)

| Key | Description |
|-----|-------------|
| `<leader>cd` | Go to definition |
| `<leader>cD` | Go to declaration |
| `<leader>ci` | Go to implementation |
| `<leader>cr` | Show references |
| `<leader>ch` | Hover documentation |
| `<leader>cs` | Show signature help |
| `<C-o>` | Jump back |
| `<C-i>` | Jump forward |

### Code Actions

| Key | Description |
|-----|-------------|
| `<leader>ca` | Show code actions |
| `<leader>cR` | Rename symbol |
| `<leader>cf` | Format code |
| `<leader>ce` | Show line diagnostics |

### Folding

| Key | Description |
|-----|-------------|
| `za` | Toggle fold under cursor |
| `zc` | Close fold |
| `zo` | Open fold |
| `zR` | Open all folds |
| `zM` | Close all folds |

---

## Quick Tips

### Repeating Commands

- **The dot command `.`** repeats the last change
  - Example: `dd` deletes a line, then `.` deletes another line
  - Works with any change: `ciw`, `x`, `A;`, etc.

### Combining Numbers with Commands

- `{number}{command}` - Repeat command N times
  - `3j` - Move down 3 lines
  - `5dd` - Delete 5 lines
  - `2w` - Move forward 2 words
  - `10>` - Indent 10 lines right (visual mode)

### Line Numbers

- `:set number` - Show line numbers
- `:set relativenumber` - Show relative line numbers (useful for `{number}j/k`)
- Your config has both enabled by default

### Search Current Word

- `*` - Search forward for word under cursor
- `#` - Search backward for word under cursor
- `n` - Next occurrence
- `N` - Previous occurrence

### Jump List

Vim remembers where you've been:
- `<C-o>` - Jump back to previous location
- `<C-i>` - Jump forward to next location
- `:jumps` - Show jump list

### Fast File Navigation

1. **Harpoon** (for frequent files):
   - `<leader>a` - Mark current file
   - `<Shift-Tab>` - Open Harpoon menu

2. **Telescope** (for searching):
   - `<leader>ff` - Find files by name
   - `<leader>fg` - Search text in files (grep)
   - `<leader>fb` - Find open buffers

### Multi-Line Editing

**Example**: Add semicolons to end of 5 lines

1. Move to first line
2. `A;` - Append semicolon
3. `<Esc>` - Return to normal mode
4. `4.` - Repeat on next 4 lines

**Or use visual block mode**:
1. `<C-v>` - Visual block
2. `4j$` - Select end of 5 lines
3. `A;` - Append semicolon
4. `<Esc>` - Apply to all lines

### Quick Edits

| Task | Command |
|------|---------|
| Delete line and stay in normal mode | `dd` |
| Delete line and start typing | `S` or `cc` |
| Add new line above | `O` |
| Add new line below | `o` |
| Delete word and start typing | `ciw` |
| Change rest of line | `C` |
| Append to end of line | `A` |
| Insert at start of line | `I` |

### Searching Files

| Key | Description |
|-----|-------------|
| `<leader>ff` | Find files |
| `<leader>fg` | Grep in files |
| `<leader>fb` | Find buffers |
| `<leader>f.` | Recent files |
| `<leader>fs` | Fuzzy find in current buffer |

### Git Operations

| Key | Description |
|-----|-------------|
| `<leader>gs` | Git status |
| `<leader>gb` | Git branches |
| `<leader>gl` | Open LazyGit |
| `<leader>gd` | Open Diffview |

---

## Common Patterns for Coding

### Pattern 1: Replace All Instances of Variable

```vim
:%s/oldName/newName/gc
```
Or use LSP rename: `<leader>cR`

### Pattern 2: Delete All Empty Lines

```vim
:g/^$/d
```

### Pattern 3: Sort Lines

```vim
:sort
" Or visual select and:
:'<,'>sort
```

### Pattern 4: Remove Trailing Whitespace

```vim
:%s/\s\+$//
```

### Pattern 5: Increment/Decrement Numbers

| Key | Description |
|-----|-------------|
| `<C-a>` | Increment number under cursor |
| `<C-x>` | Decrement number under cursor |

### Pattern 6: Format JSON File

```vim
<leader>cf
" Or:
:%!jq .
```

---

## Escape Hatches

### When Things Go Wrong

| Problem | Solution |
|---------|----------|
| Stuck in insert mode | Press `<Esc>` |
| Stuck in visual mode | Press `<Esc>` |
| Stuck in terminal mode | Press `<Esc><Esc>` |
| Accidental macro recording | Press `q` to stop |
| Made a mistake | Press `u` to undo |
| Can't save file | `:w!` (force write) |
| Want to quit without saving | `:q!` |
| Editor frozen | Press `<C-c>` or `:q!` |

---

## Next Steps

1. **Practice Movement**: Use `hjkl` instead of arrow keys
2. **Master Text Objects**: Practice `ciw`, `di"`, `vi{`, etc.
3. **Learn Dot Command**: Use `.` to repeat actions
4. **Use Visual Mode**: Select text with `v` and operate on it
5. **Embrace Undo**: Don't fear making mistakes - `u` is your friend

---

**More Resources**:
- Run `:Tutor` in Neovim for interactive tutorial
- See `PLUGINS.md` for plugin-specific keymaps
- Press `<Space>` and wait to see which-key popup with available commands