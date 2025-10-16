# Neovim Configuration & Plugin Documentation

**Leader Key**: `<Space>`

Last Updated: October 2025 - Added DevRun 30+ variable system, interactive configuration builder, and exploded WAR support

This document provides comprehensive documentation for all plugins, their configurations, and keybindings.

---

## Table of Contents

### Core Navigation & UI
- [Essential Keys](#essential-keys)
- [Window Management](#window-management)
- [File Explorer (Neo-tree)](#file-explorer-neo-tree)
- [Finding & Navigation (Telescope)](#finding--navigation-telescope)
- [Harpoon (Quick File Access)](#harpoon-quick-file-access)

### Development Tools
- [LSP & Code Actions](#lsp--code-actions)
- [Completion (nvim-cmp)](#completion-nvim-cmp)
- [Treesitter (Syntax Highlighting)](#treesitter-syntax-highlighting)
- [Formatting & Linting (none-ls)](#formatting--linting-none-ls)
- [Debugging (DAP)](#debugging-dap)

### Language-Specific
- [Java Development (JDTLS)](#java-development)
- [Flutter/Dart Development](#flutterdart-development)

### Database Tools
- [Database Client (nvim-dbee)](#database-client-nvim-dbee)

### Task Runners
- [DevRun (Spring Boot/Gradle)](#devrun-spring-bootgradle)

### Version Control
- [Git Operations](#git-operations)

### Productivity & Utilities
- [Comments](#comments)
- [Search & Replace (Spectre)](#search--replace)
- [Undo Tree](#undo-tree)
- [AI Assistant (Claude Code)](#claude-code-ai-assistant)

### Advanced
- [LspLogLens (LSP Log Viewing & AI Analysis)](#lsploglens-lsp-log-viewing--ai-analysis)
- [Custom Commands](#custom-commands)

### Reference
- [Telescope Internal Navigation](#telescope-internal-navigation)
- [Quick Reference Card](#quick-reference-card)
- [Which-Key Groups](#which-key-groups)

---

## Essential Keys

| Key | Description | Mode |
|-----|-------------|------|
| `<Esc>` | Remove search highlights | Normal |
| `<Esc><Esc>` | Exit terminal mode | Terminal |
| `<C-h>` | Move focus to left window | Normal |
| `<C-l>` | Move focus to right window | Normal |
| `<C-j>` | Move focus to lower window | Normal |
| `<C-k>` | Move focus to upper window | Normal |
| `<` | Indent left (stays in visual mode) | Visual |
| `>` | Indent right (stays in visual mode) | Visual |

---

## Window Management

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>wv` | Split window vertically | Normal |
| `<leader>wh` | Split window horizontally | Normal |

---

## File Explorer (Neo-tree)

**Plugin**: `nvim-neo-tree/neo-tree.nvim`
**Purpose**: Modern file system explorer with git integration

### Configuration

**Location**: `lua/plugins/neotree.lua`

**Key Settings**:
- Position: Left sidebar (width: 40)
- Auto-close: Closes if it's the last window
- Git status: Enabled with custom symbols
- Diagnostics: Enabled (shows LSP errors in tree)
- File watcher: Enabled for auto-refresh
- Follow current file: Enabled (auto-focuses current file)

**Dependencies**: plenary.nvim, nui.nvim, nvim-web-devicons

**Behavior**:
- Files open in editor window (focus moves automatically)
- Neo-tree stays open when opening files
- Space key disabled to avoid leader key conflicts

### Global Keymaps

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>ee` | Toggle file explorer | Normal |
| `<leader>ef` | Focus file explorer | Normal |
| `<leader>ec` | Close file explorer | Normal |

### Neo-tree Internal Keys (when in Neo-tree window)

**Core Navigation**:

| Key | Description |
|-----|-------------|
| `j` / `k` | Move up/down |
| `↑` / `↓` | Move up/down (arrow keys) |
| `<CR>` / `<2-LeftMouse>` | Open file or toggle directory |
| `<Space>` | Disabled (to avoid conflict with leader key) |
| `?` | Show help with all keybindings |
| `R` | **Refresh/reset tree** (reload from filesystem) |
| `q` | Close Neo-tree window |

**File & Directory Operations**:

| Key | Description |
|-----|-------------|
| `a` | Add new file (use `/` at end for directory) |
| `A` | Add new directory |
| `d` | Delete file/directory |
| `r` | Rename file/directory |
| `c` | Copy file/directory |
| `x` | Cut file/directory |
| `p` | Paste (after copy/cut) |
| `y` | Copy name to clipboard |
| `Y` | Copy relative path to clipboard |
| `gy` | Copy absolute path to clipboard |

**Opening Files**:

| Key | Description |
|-----|-------------|
| `<CR>` | Open file (keeps Neo-tree open, focus moves to file) |
| `s` | Open in vertical split |
| `S` | Open in horizontal split |
| `t` | Open in new tab |
| `w` | Open with window picker |

**Tree Management**:

| Key | Description |
|-----|-------------|
| `z` | Close all nodes (collapse tree) |
| `Z` | Expand all nodes |
| `H` | Toggle hidden files visibility |
| `.` | Set root to current directory |
| `<BS>` / `-` | Navigate up one directory level |

**Git Integration** (when git_status enabled):

Neo-tree shows git status symbols for files:
- `✚` - Added file
- `` - Modified file
- `✖` - Deleted file
- `󰁕` - Renamed file
- `` - Untracked file
- `` - Ignored file
- `󰄱` - Unstaged changes
- `` - Staged changes
- `` - Conflict

**Usage Tips**:

1. **Refresh on External Changes**: Press `R` to reload the tree if files were modified outside Neovim
2. **Quick File Creation**: Press `a` and type `path/to/file.ext` to create nested files
3. **Directory Creation**: Press `A` or use `a` with trailing `/` (e.g., `newdir/`)
4. **Window Management**:
   - Neo-tree is positioned on the left and stays open when files are opened
   - Files open in the editor window on the right (focus automatically moves there)
   - If windows get misaligned, use `<C-w>=` to equalize window sizes
5. **Auto-Refresh**: Your config has `use_libuv_file_watcher = true` for automatic refresh on external changes
6. **Follow Current File**: Neo-tree automatically finds and focuses your current file when you switch buffers

---

## Finding & Navigation (Telescope)

**Plugin**: `nvim-telescope/telescope.nvim`
**Purpose**: Fuzzy finder for files, grep, LSP symbols, and more

### Configuration

**Location**: `lua/plugins/telescope.lua`

**Extensions**:
- `telescope-fzf-native.nvim` - Native FZF sorting for better performance
- `telescope-ui-select.nvim` - Use Telescope for `vim.ui.select` (code actions, etc.)

**Dependencies**: plenary.nvim

**Key Features**:
- Smart path display
- Live grep with ripgrep
- Git integration (status, branches)
- LSP integration (definitions, references, symbols)
- Quickfix list integration
- Custom keymaps for navigation within picker

### File Operations (`<leader>f` prefix)

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>ff` | Find files | Normal |
| `<leader>fg` | Live grep (search in files) | Normal |
| `<leader>fd` | Find diagnostics | Normal |
| `<leader>fr` | Resume last search | Normal |
| `<leader>f.` | Find recent files | Normal |
| `<leader>fb` | Find buffers | Normal |
| `<leader>fs` | Fuzzy find in current buffer | Normal |
| `<leader>fq` | Quickfix list | Normal |
| `<leader>fQ` | Quickfix history | Normal |

### LSP Navigation via Telescope

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>fI` | Find LSP implementations | Normal |
| `<leader>fR` | Find LSP references | Normal |
| `<leader>fD` | Find LSP definitions | Normal |
| `<leader>fT` | Find LSP type definitions | Normal |
| `<leader>fS` | Find document symbols | Normal |

---

## Harpoon (Quick File Access)

**Plugin**: `ThePrimeagen/harpoon` (branch: harpoon2)
**Purpose**: Quick navigation between frequently used files

### Configuration

**Location**: `lua/plugins/harpoon.lua`

**Integration**: Uses Telescope for the file picker UI

**Dependencies**: plenary.nvim

### How It Works

1. Mark files you frequently access with `<leader>a`
2. Access marked files via `<Shift-Tab>` (opens Telescope picker)
3. Navigate through your marked files quickly
4. Files persist across Neovim sessions

### Keybindings

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>a` | Add current file to Harpoon | Normal |
| `<Shift-Tab>` | Toggle Harpoon menu (via Telescope) | Normal |

### Workflow Example

1. Open important project files
2. Press `<leader>a` on each to mark them
3. Later, press `<Shift-Tab>` to quickly jump to any marked file
4. Much faster than `<leader>ff` for frequently used files

---

## LSP & Code Actions

All LSP keymaps use `<leader>c` prefix:

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>ce` | Show line diagnostics (error details) | Normal |
| `<leader>ch` | Hover documentation | Normal |
| `<leader>cs` | Show signature help | Normal |
| `<leader>cd` | Go to definition | Normal |
| `<leader>cD` | Go to declaration | Normal |
| `<leader>ci` | Go to implementation | Normal |
| `<leader>cr` | Go to references | Normal |
| `<leader>ca` | Code actions | Normal, Visual |
| `<leader>cR` | Rename symbol | Normal |
| `<leader>cf` | Format code (async) | Normal, Visual |

---

## Completion (nvim-cmp)

Completion keymaps work in **Insert mode**:

| Key | Description | Mode |
|-----|-------------|------|
| `<C-k>` | Previous suggestion | Insert |
| `<C-j>` | Next suggestion | Insert |
| `<C-Space>` | Show completions | Insert |
| `<C-e>` | Close completion window | Insert |
| `<CR>` | Confirm selection (only when explicitly selected) | Insert |
| `<C-b>` | Scroll documentation backward | Insert |
| `<C-f>` | Scroll documentation forward | Insert |

---

## Git Operations

All Git keymaps use `<leader>g` prefix:

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>gs` | Git status (Telescope) | Normal |
| `<leader>gb` | Git branches (Telescope) | Normal |
| `<leader>gh` | Preview hunk | Normal |
| `<leader>gB` | Git blame | Normal |
| `<leader>gn` | Open Neogit | Normal |
| `<leader>gl` | Open LazyGit | Normal |
| `<leader>gd` | Open Diffview | Normal |

---

## Debugging (DAP)

All Debug keymaps use `<leader>d` prefix:

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>dt` | Toggle breakpoint | Normal |
| `<leader>dc` | Debug continue/start | Normal |
| `<leader>dx` | Close debug UI | Normal |
| `<leader>db` | Set breakpoint | Normal |
| `<leader>dB` | Set conditional breakpoint | Normal |
| `<leader>dr` | Open debug REPL | Normal |

### Debug Stepping (`<leader>ds` subgroup)

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>dso` | Step over | Normal |
| `<leader>dsi` | Step into | Normal |
| `<leader>dsu` | Step out | Normal |

---

## Java Development

**Note**: Java keymaps are only active in `.java` files (buffer-local).
**Configuration**: Java LSP (JDTLS) is automatically configured via ftplugin when opening .java files.
**Location**: Keymaps defined in `lua/config/jdtls.lua`, loaded by `ftplugin/java.lua` (Neovim standard).

### Source Actions (`<leader>Js` prefix)

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>Jsi` | Organize imports | Normal |

### Refactor Actions (`<leader>Jr` prefix)

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>Jrv` | Extract variable | Normal, Visual |
| `<leader>Jrc` | Extract constant | Normal, Visual |
| `<leader>Jrm` | Extract method | Visual |

### Test Actions (`<leader>t` prefix)

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>tt` | Run test method | Normal, Visual |
| `<leader>tc` | Run test class | Normal |
| `<leader>tg` | Generate tests | Normal |
| `<leader>to` | Open test class (go to test/subject) | Normal |

### Build Actions (`<leader>J` prefix)

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>JU` | Update all project configurations | Normal |
| `<leader>JB` | Build all projects | Normal |

---

## Flutter/Dart Development

All Flutter keymaps use `<leader>F` prefix:

### Run and Reload

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>Fr` | Run Flutter app | Normal |
| `<leader>Fq` | Quit Flutter app | Normal |
| `<leader>FR` | Restart Flutter app (full restart) | Normal |
| `<leader>Fh` | Hot reload (preserves state) | Normal |

### Devices and Emulators

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>Fd` | List Flutter devices | Normal |
| `<leader>Fe` | List/launch Flutter emulators | Normal |

### DevTools

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>FT` | Open Flutter DevTools | Normal |

### UI and Logs

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>Fo` | Toggle Flutter outline (widget tree) | Normal |
| `<leader>FL` | Toggle Flutter log window | Normal |
| `<leader>Fl` | Clear Flutter logs | Normal |

### Pub Commands

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>Fp` | Run `flutter pub get` | Normal |
| `<leader>FP` | Run `flutter pub upgrade` | Normal |

### Utilities

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>Fc` | Copy profiler URL | Normal |
| `<leader>Fs` | Restart Dart LSP | Normal |
| `<leader>Fn` | Rename (creates both .dart and test file) | Normal |

---

## Database Client (nvim-dbee)

**Plugin**: `kndndrj/nvim-dbee`
**Purpose**: Interactive database client for Neovim with support for multiple database types

### Supported Databases
- SQLite
- MySQL
- PostgreSQL
- And more...

### Configuration

**Location**: `lua/plugins/nvim-dbee.lua`

**Key Settings**:
- Drawer position: Left (width 30)
- Result window: Bottom split (height 15)
- Connection sources:
  - JSON file: `~/.local/share/nvim/dbee/connections.json`
  - Environment variable: `DBEE_CONNECTIONS`

**Dependencies**: nui.nvim

### Connection Setup

Create a connections file at `~/.local/share/nvim/dbee/connections.json`:

```json
{
  "connections": [
    {
      "name": "Local PostgreSQL",
      "type": "postgres",
      "url": "postgresql://user:password@localhost:5432/dbname"
    },
    {
      "name": "SQLite DB",
      "type": "sqlite",
      "url": "sqlite://path/to/database.db"
    }
  ]
}
```

Or set environment variable:
```bash
export DBEE_CONNECTIONS='[{"name":"mydb","type":"postgres","url":"..."}]'
```

### Keybindings

All database keymaps use `<leader>D` prefix:

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>Dt` | Toggle dbee UI | Normal |
| `<leader>De` | Execute query | Normal |
| `<leader>Ds` | Save query results | Normal |
| `<leader>Dc` | Close dbee | Normal |

### Usage Tutorial

1. **Open dbee**: Press `<leader>Dt` to open the database UI
2. **Select connection**: Navigate to your connection in the drawer and press `<CR>`
3. **Browse tables**: Expand database tree to see tables and schemas
4. **Write query**: Open a scratchpad or SQL buffer
5. **Execute**: Press `BB` or `<leader>De` to run the query
6. **View results**: Results appear in the bottom split with pagination

### dbee Internal Keys (when in dbee UI)

| Key | Description |
|-----|-------------|
| `BB` | Execute query under cursor |
| `o` | Toggle tree node (expand/collapse) |
| `<CR>` | Perform action on item |
| `cw` | Edit connection or scratchpad |
| `dd` | Delete connection or scratchpad |
| `q` | Close dbee window |

### Tips

1. **Query History**: dbee saves your query history automatically
2. **Multiple Connections**: You can have multiple connections open simultaneously
3. **Export Results**: Use `<leader>Ds` to save query results to a file
4. **Scratchpads**: Create temporary SQL scratchpads for quick queries

**Status**: Alpha - Expect breaking changes

---

## DevRun (Multi-Type Task Runner)

**Plugin**: DevRun (custom local plugin)
**Purpose**: JSON-based task runner with type system supporting Gradle, Tomcat, and generic commands

### Overview

A complete type-safe task runner system with JSON schema validation. Supports multiple executor types: **Gradle** tasks, **Tomcat** server deployment, and generic **shell commands**. Features include VM arguments, environment variables, task chaining, and real-time log streaming.

### Configuration

**Location**: `lua/plugins/devrun.lua` (plugin setup)
**Config File**: `.nvim/run-configurations.json` (project-local) or `~/.config/nvim/run-configurations.json` (global)
**Schema File**: `schemas/run-configurations.schema.json` (for IDE autocomplete)

**Dependencies**: telescope.nvim (for configuration picker)

**Module Structure**:
- `lua/devrun/init.lua` - Main module and commands
- `lua/devrun/parser.lua` - JSON parsing and type validation
- `lua/devrun/task-manager.lua` - Task execution orchestration
- `lua/devrun/log-ui.lua` - Log console UI and output handling
- `lua/devrun/executors/` - Type-specific executors (gradle, tomcat, command)

### Supported Types

**Type System**:
- `gradle` - Gradle task executor with VM args auto-injection
- `tomcat` - Apache Tomcat server deployment and management
- `command` - Generic shell command executor

### JSON Configuration Format

Create `.nvim/run-configurations.json` in your project root:

```json
{
  "$schema": "./run-configurations.schema.json",
  "configurations": [
    {
      "name": "Clean",
      "type": "gradle",
      "command": "./gradlew clean"
    },
    {
      "name": "Build WAR",
      "type": "gradle",
      "command": "./gradlew war",
      "beforeRun": "Clean"
    },
    {
      "name": "Spring Boot Dev",
      "type": "gradle",
      "command": "./gradlew bootRun",
      "vmArgs": ["-Dspring.profiles.active=dev", "-Xmx2G"],
      "env": { "SPRING_PROFILES_ACTIVE": "dev" }
    },
    {
      "name": "Tomcat 9 Dev",
      "type": "tomcat",
      "beforeRun": "Build WAR",
      "tomcatHome": "/usr/local/tomcat9",
      "artifact": "${workspaceFolder}/build/libs/myapp-1.0.0.war",
      "httpPort": 8080,
      "debugPort": 5005,
      "contextPath": "myapp",
      "vmArgs": ["-Xmx1G"],
      "cleanDeploy": true
    },
    {
      "name": "Deploy Script",
      "type": "command",
      "command": "./deploy.sh production"
    }
  ]
}
```

### Common Configuration Fields

All types support these common fields:

| Field | Required | Description | Default |
|-------|----------|-------------|---------|
| `name` | Yes | Unique configuration name | - |
| `type` | No | Executor type (gradle/tomcat/command) | `"gradle"` |
| `beforeRun` | No | Name of config to run before this one | - |
| `cwd` | No | Working directory | `"${workspaceFolder}"` |
| `env` | No | Environment variables | `{}` |

### Type-Specific Fields

#### Gradle Type (`type: "gradle"`)

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `command` | Yes | Gradle command to execute | `"./gradlew bootRun"` |
| `vmArgs` | No | JVM arguments (auto-injected into command) | `["-Xmx2G", "-Dspring.profiles.active=dev"]` |

#### Tomcat Type (`type: "tomcat"`)

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `tomcatHome` | Yes | Path to Tomcat installation | `"/usr/local/tomcat9"` |
| `artifact` | Yes | Path to WAR file to deploy | `"${workspaceFolder}/build/libs/app.war"` |
| `httpPort` | No | Tomcat HTTP port | `8080` |
| `debugPort` | No | JPDA debug port (enables remote debugging) | `5005` |
| `contextPath` | No | Web app context path | WAR filename |
| `vmArgs` | No | JVM arguments for Tomcat | `["-Xmx1G"]` |
| `cleanDeploy` | No | Remove previous deployment first | `false` |

#### Command Type (`type: "command"`)

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `command` | Yes | Shell command to execute | `"./deploy.sh"` |

### Variable Substitution

DevRun supports **30+ variables** for portable, dynamic configurations using VSCode-compatible syntax: `${variableName}`.

#### Variable Categories

**Path Variables** (11 variables):
- `${workspaceFolder}` - Current workspace directory (e.g., `/Users/username/projects/myapp`)
- `${workspaceFolderBasename}` - Workspace folder name (e.g., `myapp`)
- `${userHome}` - User home directory (e.g., `/Users/username`)
- `${file}` - Currently open file absolute path
- `${fileBasename}` - File name with extension (e.g., `Main.java`)
- `${fileBasenameNoExtension}` - File name without extension (e.g., `Main`)
- `${fileDirname}` - Directory containing current file
- `${fileExtname}` - File extension (e.g., `java`)
- `${relativeFile}` - File path relative to workspace (e.g., `src/Main.java`)
- `${relativeFileDirname}` - File directory relative to workspace (e.g., `src`)

**Project Variables** (3 variables):
- `${projectName}` - Project name from workspace folder name
- `${buildDir}` - Build output directory (`build`)
- `${targetDir}` - Target directory for Maven/Gradle (`build`)

**Date/Time Variables** (3 variables):
- `${date}` - Current date in `YYYY-MM-DD` format (e.g., `2025-10-15`)
- `${time}` - Current time in `HH:MM:SS` format (e.g., `14:30:45`)
- `${timestamp}` - Unix timestamp in seconds (e.g., `1697385045`)

**Environment Variables**:
- `${env:VARIABLE_NAME}` - Access any environment variable (e.g., `${env:JAVA_HOME}`, `${env:TOMCAT_HOME}`)

**Config References**:
- `${config:fieldName}` - Reference other fields in same configuration (e.g., `${config:httpPort}`)

**Special Variables**:
- `${random}` - Random 6-digit number (e.g., `482561`)

**Deprecated** (still supported with warning):
- `${workspacePath}` - Use `${workspaceFolder}` instead

#### Variable Usage Examples

**Example 1: Portable Paths**
```json
{
  "artifact": "${workspaceFolder}/build/libs/${projectName}.war",
  "tomcatHome": "${userHome}/tomcat9"
}
```

**Example 2: Environment-Based Paths**
```json
{
  "tomcatHome": "${env:TOMCAT_HOME}",
  "env": {
    "JAVA_HOME": "${env:JAVA_HOME}"
  }
}
```

**Example 3: Dynamic Log Files**
```json
{
  "command": "./run.sh > ${workspaceFolder}/logs/app-${date}.log 2>&1"
}
```

**Example 4: Config Field References**
```json
{
  "httpPort": 8080,
  "env": {
    "SERVER_URL": "http://localhost:${config:httpPort}"
  }
}
```

#### View All Variables

Run `:DevRunVariables` to see all available variables and their **current resolved values** in your environment.

**Documentation**: For complete variable documentation with examples and best practices, see `lua/devrun/VARIABLES.md`.

### Features

**Core Features**:
- ✅ **Type system with JSON schema**: Gradle, Tomcat, and command executors with IDE autocomplete
- ✅ **JSON-based configuration**: Define tasks in project-local or global JSON files
- ✅ **Before-run task chaining**: Automatically run build/clean tasks before main task
- ✅ **Background task management**: Run multiple tasks simultaneously
- ✅ **Real-time log streaming**: Live output in dedicated log console
- ✅ **30+ variable substitution**: VSCode-compatible variables (paths, env, dates, config refs) for portable configs
- ✅ **Interactive configuration builder**: Add configurations via Telescope prompts (`:DevRunAddRunConfiguration`)
- ✅ **Telescope integration**: Quick picker showing task types
- ✅ **Exploded WAR support**: Deploy both packed and exploded WAR directories to Tomcat

**Gradle-Specific**:
- ✅ **VM arguments auto-injection**: Automatically injects VM args into Gradle commands
- ✅ **Profile support**: Easy Spring Boot profile switching

**Tomcat-Specific**:
- ✅ **WAR deployment**: Automatic deployment to Tomcat webapps directory
- ✅ **Remote debugging**: JPDA debugging support with configurable debug port
- ✅ **Graceful shutdown**: Proper Tomcat stop via catalina.sh
- ✅ **Clean deployment**: Option to remove previous deployment before deploying
- ✅ **Context path management**: Configurable web application context
- ✅ **Multi-version support**: Support different Tomcat versions (8, 9, 10)

### Commands

All commands are prefixed with `DevRun`:

| Command | Description |
|---------|-------------|
| `:DevRun` | Open Telescope picker to select and run a configuration |
| `:DevRunConfig <name>` | Run specific configuration by name |
| `:DevRunTasks` | List all running tasks with status and duration |
| `:DevRunLogs [name]` | Show log console for specific task (default: latest) |
| `:DevRunToggleLogs` | Toggle log console window visibility |
| `:DevRunStop [name]` | Stop running task (opens picker if no name) |
| `:DevRunStopAll` | Stop all running background tasks |
| `:DevRunReload` | Reload configurations from JSON file |
| `:DevRunInit` | Create example `run-configurations.json` in project |
| `:DevRunAddRunConfiguration [type]` | Add new configuration interactively (gradle/tomcat/command) |
| `:DevRunVariables` | Show all available variables and their current values |

### Keybindings

All keybindings use `<leader>R` prefix (Run):

| Key | Command | Description | Mode |
|-----|---------|-------------|------|
| `<leader>Rr` | `:DevRun` | DevRun configurations picker | Normal |
| `<leader>Rt` | `:DevRunTasks` | Show active tasks | Normal |
| `<leader>Rl` | `:DevRunToggleLogs` | Toggle logs console | Normal |
| `<leader>Rs` | `:DevRunStop` | Stop task (picker) | Normal |
| `<leader>RR` | `:DevRunReload` | Reload config file | Normal |
| `<leader>RI` | `:DevRunInit` | Init example config | Normal |
| `<leader>RA` | `:DevRunAddRunConfiguration` | Add configuration interactively | Normal |

### Log Console Keybindings

When in the log console window:

| Key | Description |
|-----|-------------|
| `q` | Close log console |
| `c` | Clear current task's log |
| `a` | Toggle auto-scroll on/off |

### Usage Tutorial

#### 1. Create Configuration File

**First time setup**:
```vim
:DevRunInit
```

This creates `.nvim/run-configurations.json` with example configurations.

#### 2. Customize Configurations

Edit `.nvim/run-configurations.json` to add your Spring Boot/Gradle tasks:

```json
{
  "configurations": [
    {
      "name": "Spring Boot with Profile",
      "command": "./gradlew bootRun",
      "vmArgs": [
        "-Dspring.profiles.active=local",
        "-Xmx2G",
        "-Dserver.port=8080"
      ],
      "beforeRun": "clean-build",
      "env": {
        "DATABASE_URL": "jdbc:postgresql://localhost:5432/mydb"
      }
    },
    {
      "name": "clean-build",
      "command": "./gradlew clean build -x test"
    }
  ]
}
```

#### 3. Run a Configuration

**Option A: Using Picker** (Recommended)
```vim
:DevRun
" Or press: <leader>Rr
```
- Telescope picker opens
- Select configuration with `<CR>`
- Task starts and log console opens automatically

**Option B: Direct Command**
```vim
:DevRunConfig Spring Boot with Profile
```

#### 4. View Running Tasks

```vim
:DevRunTasks
" Or press: <leader>Rt
```

Shows:
- Task ID, name, status
- Duration since start
- Command and working directory

#### 5. View Logs

```vim
:DevRunLogs
" Or press: <leader>Rl
```

**In log console**:
- Real-time output streaming
- Auto-scroll to bottom (toggle with `a`)
- Clear log with `c`
- Close with `q`

#### 6. Stop Tasks

```vim
:DevRunStop Spring Boot with Profile
" Or press: <leader>Rs (opens picker)
```

### How It Works

#### VM Arguments Injection

VM args are automatically injected into Gradle commands:

```json
{
  "command": "./gradlew clean bootRun",
  "vmArgs": ["-Xmx2G", "-Dspring.profiles.active=dev"]
}
```

**Becomes**: `./gradlew -Xmx2G -Dspring.profiles.active=dev clean bootRun`

#### Before-Run Tasks

Configurations can depend on other configurations:

```json
{
  "name": "Spring Boot Prod",
  "command": "./gradlew bootRun",
  "beforeRun": "gradle-clean"
}
```

When you run "Spring Boot Prod":
1. Runs "gradle-clean" first
2. Waits for it to complete
3. Then runs "Spring Boot Prod"

#### Background Execution

All tasks run in the background using `vim.system()`:
- Non-blocking: Continue editing while tasks run
- Multiple tasks: Run several tasks simultaneously
- Live output: Real-time streaming to log console

### Example Workflow

**Scenario**: Starting Spring Boot app in development mode

1. Press `<leader>Rr` to open configurations
2. Select "Spring Boot Dev" from picker
3. Before-run task "gradle-clean" executes automatically
4. Log console opens showing build output
5. Spring Boot starts with dev profile and VM args
6. Continue coding while app runs in background
7. Press `<leader>Rl` to toggle log console visibility
8. Check running tasks with `<leader>Rt`
9. Stop with `<leader>Rs` when done

### Tomcat Server Workflow

#### Deploying Web Applications to Tomcat

**Scenario**: Deploy a Gradle-built WAR file to Tomcat 9 in development mode with remote debugging.

1. **Create Build Configuration**:
```json
{
  "name": "Build WAR",
  "type": "gradle",
  "command": "./gradlew clean war"
}
```

2. **Create Tomcat Configuration**:
```json
{
  "name": "Tomcat 9 Dev",
  "type": "tomcat",
  "beforeRun": "Build WAR",
  "tomcatHome": "/usr/local/tomcat9",
  "artifact": "${workspaceFolder}/build/libs/myapp-1.0.0.war",
  "httpPort": 8080,
  "debugPort": 5005,
  "contextPath": "myapp",
  "vmArgs": ["-Xmx1G", "-Dspring.profiles.active=dev"],
  "cleanDeploy": true
}
```

3. **Run Tomcat** (`<leader>Rr` → select "Tomcat 9 Dev"):
   - Builds WAR file (beforeRun task)
   - Cleans previous deployment (cleanDeploy: true)
   - Deploys WAR to `/usr/local/tomcat9/webapps/myapp.war`
   - Starts Tomcat with JDA debugging on port 5005
   - Logs catalina.out in real-time
   - Web app available at `http://localhost:8080/myapp`

4. **Attach Remote Debugger**:
   - Set breakpoints in your Java code
   - IntelliJ/VSCode: Create "Remote JVM Debug" config pointing to `localhost:5005`
   - DevRun log console shows server startup and application logs

5. **Stop Tomcat** (`<leader>Rs`):
   - Graceful shutdown via `catalina.sh stop`
   - Waits for app to terminate cleanly

#### Tomcat Multi-Environment Setup

Create separate Tomcat configs for different environments:

```json
{
  "configurations": [
    {
      "name": "Build WAR",
      "type": "gradle",
      "command": "./gradlew war"
    },
    {
      "name": "Tomcat Dev",
      "type": "tomcat",
      "beforeRun": "Build WAR",
      "tomcatHome": "/usr/local/tomcat9",
      "artifact": "${workspaceFolder}/build/libs/myapp.war",
      "httpPort": 8080,
      "debugPort": 5005,
      "contextPath": "myapp",
      "vmArgs": ["-Xmx512M"],
      "cleanDeploy": true
    },
    {
      "name": "Tomcat Staging",
      "type": "tomcat",
      "beforeRun": "Build WAR",
      "tomcatHome": "/opt/tomcat10",
      "artifact": "${workspaceFolder}/build/libs/myapp.war",
      "httpPort": 8443,
      "contextPath": "myapp-staging",
      "vmArgs": ["-Xmx2G"],
      "env": {
        "CATALINA_OPTS": "-Denv=staging"
      }
    }
  ]
}
```

### Tips & Tricks

**General**:
1. **Project-Local Configs**: Always use `.nvim/run-configurations.json` for project-specific tasks
2. **Global Configs**: Use `~/.config/nvim/run-configurations.json` for common tasks across projects
3. **Variable Substitution**: Use 30+ variables for portable configs:
   - Paths: `${workspaceFolder}`, `${userHome}`, `${file}`
   - Project: `${projectName}`, `${buildDir}`
   - Environment: `${env:JAVA_HOME}`, `${env:TOMCAT_HOME}`
   - Date/Time: `${date}`, `${time}`, `${timestamp}`
   - Config refs: `${config:httpPort}`
   - Run `:DevRunVariables` to see all available variables
4. **Type Indication**: Telescope picker shows `[gradle]`, `[tomcat]`, `[command]` prefixes
5. **Schema Validation**: Use `"$schema": "./run-configurations.schema.json"` for IDE autocomplete

**Gradle-Specific**:
6. **VM Args Best Practice**: Keep VM args in JSON, not in gradle.properties
7. **Before-Run Chains**: Create "clean", "build", "test" configs and chain them
8. **Multiple Profiles**: Create separate configs for each Spring profile (dev, staging, prod)

**Tomcat-Specific**:
9. **Clean Deployment**: Use `cleanDeploy: true` to avoid stale deployment issues
10. **Debug Port**: Set `debugPort` for remote debugging; attach with your IDE's remote debugger
11. **Context Path**: Omit `contextPath` to use WAR filename as context
12. **Multi-Version**: Point different configs to Tomcat 8, 9, or 10 installations
13. **Log Monitoring**: Tomcat logs stream to DevRun console; use `<leader>Rl` to toggle visibility

**Log Management**:
14. **Clear Logs**: Use `c` in log console to clear output and reduce clutter
15. **Auto-Scroll**: Disable auto-scroll (`a` key) when reviewing earlier logs

### Debugging with DevRun + nvim-dap

You can debug processes started with DevRun using nvim-dap's remote attach feature.

#### The Pattern: Start with Debug Port → Attach with DAP

**Step 1: Configure DevRun with Debug Port**

For **Gradle/Spring Boot** applications, add JVM debug arguments:

```json
{
  "type": "gradle",
  "name": "Spring Boot (Debug Mode)",
  "command": "./gradlew bootRun",
  "vmArgs": [
    "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
  ],
  "cwd": "${workspaceFolder}"
}
```

For **Tomcat** deployments, use the `debugPort` field:

```json
{
  "type": "tomcat",
  "name": "Tomcat Dev (Debug)",
  "artifact": "${workspaceFolder}/build/libs/app.war",
  "tomcatHome": "${env:TOMCAT_HOME}",
  "httpPort": 8080,
  "debugPort": 5005,
  "contextPath": "myapp"
}
```

**Step 2: Start Application with DevRun**

```vim
:DevRun
" Select your debug configuration
```

Or directly:
```vim
:DevRunConfig Spring Boot (Debug Mode)
```

**Step 3: Set Breakpoints**

Navigate to your Java code and set breakpoints:
```vim
<leader>dt
```

**Step 4: Attach Debugger**

Start DAP and connect to the debug port:
```vim
<leader>dc
```

DAP will connect to `127.0.0.1:5005` (configured in `lua/config/jdtls.lua:386-394`)

**Step 5: Debug**

Your breakpoints will now hit! Use debug keymaps:
- `<leader>dc` - Continue
- `<leader>dso` - Step over
- `<leader>dsi` - Step into
- `<leader>dsu` - Step out
- `<leader>dx` - Close debug UI

#### Suspend Options

- `suspend=n` - App starts immediately, attach debugger when ready
- `suspend=y` - App waits for debugger before starting (useful for debugging startup code)

#### Multiple Debug Ports

If running multiple services with debugging:

```json
{
  "configurations": [
    {
      "name": "Service A (Debug)",
      "type": "gradle",
      "command": "./gradlew :serviceA:bootRun",
      "vmArgs": ["-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"]
    },
    {
      "name": "Service B (Debug)",
      "type": "gradle",
      "command": "./gradlew :serviceB:bootRun",
      "vmArgs": ["-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5006"]
    }
  ]
}
```

You'd need to add corresponding DAP configurations for different ports in `lua/config/jdtls.lua`.

#### Complete Workflow Example

**Scenario**: Debug Spring Boot app running via DevRun

1. Open `run-configurations.json` and add debug config with `suspend=n`
2. Press `<leader>Rr` → select "Spring Boot (Debug Mode)"
3. App starts, DevRun log console shows output
4. Open your Java file and set breakpoints: `<leader>dt`
5. Attach debugger: `<leader>dc`
6. Trigger the code path (e.g., HTTP request to endpoint)
7. Debugger hits breakpoint, DAP UI opens
8. Step through code with `<leader>dso`, inspect variables
9. Continue with `<leader>dc` or close with `<leader>dx`

**Note**: Your JDTLS config already has remote attach configured for port 5005 at `lua/config/jdtls.lua:386-394`.

---

### Troubleshooting

**Configuration not found**:
```vim
:DevRunInit
```
Creates a new config file with examples.

**Config changes not reflected**:
```vim
:DevRunReload
```
Reloads JSON file without restarting Neovim.

**Task won't stop**:
```vim
:DevRunStopAll
```
Forcefully stops all running tasks.

**No output in log console**:
- Check task is running: `:DevRunTasks`
- Verify command is correct in JSON
- Check working directory (cwd) is valid

**Debugger won't attach**:
- Verify app is running: `:DevRunTasks`
- Check debug port in config matches DAP config (default: 5005)
- Ensure app started with debug agent: check DevRun logs for JDWP output
- Verify firewall isn't blocking localhost:5005

### Architecture

**Modules**:
- `lua/devrun/parser.lua` - JSON parsing and validation
- `lua/devrun/task-manager.lua` - Task execution and process management
- `lua/devrun/log-ui.lua` - Log console UI and output handling
- `lua/devrun/init.lua` - Main module and commands
- `lua/plugins/devrun.lua` - Plugin setup and keybindings

**Design Philosophy**:
- **Simple**: JSON-based configuration, no complex DSL
- **Focused**: Designed for Spring Boot/Gradle workflows
- **Integrated**: Works with existing Telescope and which-key setup
- **Independent**: No external plugin dependencies (except Telescope)
- **Transparent**: Pure Lua implementation, easy to customize

---

## Comments

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>/` | Toggle line comment | Normal |
| `<leader>/` | Toggle comment for selection | Visual |

---

## Search & Replace

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>S` | Toggle Spectre (search/replace) | Normal |

**Spectre** is a powerful find-and-replace tool with regex support and preview.

---

## Undo Tree

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>u` | Toggle undo tree | Normal |

---

## Claude Code (AI Assistant)

All Claude Code keymaps use `<leader>A` prefix (AI):

| Key | Description | Mode |
|-----|-------------|------|
| `<C-,>` | Toggle Claude Code window | Normal, Terminal |
| `<leader>Ac` | Toggle Claude Code | Normal |
| `<leader>AC` | Continue last conversation | Normal |
| `<leader>Af` | Focus Claude Code terminal | Normal |
| `<leader>Ar` | Resume last session | Normal |
| `<leader>Am` | Select Claude model | Normal |
| `<leader>Ab` | Add current buffer to context | Normal |
| `<leader>As` | Send selection to Claude | Visual |

---

## Treesitter (Syntax Highlighting)

**Plugin**: `nvim-treesitter/nvim-treesitter`
**Purpose**: Advanced syntax highlighting and code understanding using tree-sitter parsers

### Configuration

**Location**: `lua/plugins/treesitter.lua`

**Installed Parsers**:
- vim, lua, vimdoc
- java, dart
- javascript, typescript, tsx
- html, css, json
- markdown, markdown_inline
- gitignore

### Features Enabled

1. **Syntax Highlighting**: Enhanced, context-aware syntax highlighting
2. **Incremental Selection**: Expand selection based on syntax tree
3. **Indentation**: Smart indentation based on syntax
4. **Code Folding**: Fold code blocks intelligently

### Auto-tag Plugin

**Plugin**: `windwp/nvim-ts-autotag`
**Purpose**: Automatically close and rename HTML/XML tags

**Configuration**: Separate setup (breaking change from older versions)
- Auto-closes tags in HTML, JSX, TSX, XML files
- Renames closing tag when you rename opening tag

### No Keybindings

Treesitter works automatically in the background - no keybindings needed!

---

## Formatting & Linting (none-ls)

**Plugin**: `nvimtools/none-ls.nvim`
**Purpose**: Code formatting and linting using external tools

### Configuration

**Location**: `lua/plugins/none-ls.lua`

**Formatters**:
- `stylua` - Lua code formatter
- `prettier` - JavaScript/TypeScript/JSON/HTML/CSS/Markdown formatter

**Linters**:
- `eslint_d` - Fast JavaScript/TypeScript linter

### Features

- **Async Formatting**: Formatting runs asynchronously to prevent editor freezing
- **Format on Save**: Auto-format JSON files on save
- **Integration**: Works with LSP system seamlessly

### Keybinding

| Key | Description | Mode |
|-----|-------------|------|
| `<leader>cf` | Format code (async) | Normal, Visual |

### Supported File Types

- **Lua**: stylua formatting
- **JavaScript/TypeScript**: prettier formatting + eslint linting
- **JSON**: prettier formatting (**auto-format on save**)
- **HTML/CSS**: prettier formatting
- **Markdown**: prettier formatting
- **Java**: Google Java Style (via JDTLS, not none-ls)
- **Dart**: dartfmt (via flutter-tools, not none-ls)

### JSON Auto-Format

JSON files (including `.nvim/run-configurations.json`) are automatically formatted on save using prettier.

**Manual format**:
```vim
<leader>cf
" Or in command mode:
:lua vim.lsp.buf.format()
```

---

## LspLogLens (LSP Log Viewing & AI Analysis)

**Plugin**: LspLogLens (custom local plugin)
**Purpose**: Advanced LSP log viewing and AI-powered error analysis using Ollama

### Overview

A comprehensive plugin for viewing, analyzing, and understanding LSP log files. Provides formatted log viewing, real-time tailing, error filtering, and AI-powered explanations of JDTLS errors using local Ollama LLM.

### Configuration

**Location**: `lua/plugins/lsploglens.lua` (plugin setup)

**Module Structure**:
- `lua/lsploglens/init.lua` - Main module and command setup
- `lua/lsploglens/viewer.lua` - Log viewing and formatting
- `lua/lsploglens/analyzer.lua` - AI-powered error analysis
- `lua/lsploglens/utils.lua` - Shared utility functions

**AI Model Used**: `qwen2.5-coder:7b-instruct` (fast, code-optimized)

**Requirements**:
- Ollama installed at `/opt/homebrew/bin/ollama` (for AI features)
- Model downloaded: `qwen2.5-coder:7b-instruct`

### Commands

All commands are prefixed with `LspLogLens`:

#### Log Viewing Commands

| Command | Description |
|---------|-------------|
| `:LspLogLensOpen` | Open raw LSP log file in editor |
| `:LspLogLensTail` | Tail LSP log in terminal split (live updates) |
| `:LspLogLensErrors [N]` | Show last N errors/warnings (default: 50) |
| `:LspLogLensFormatted` | Open formatted LSP log with timestamps and separators |
| `:LspLogLensJdtls` | Show last 100 JDTLS-specific log entries |
| `:LspLogLensClear` | Clear LSP log file |
| `:LspLogLensInfo` | Show log file info (size, location, line count) |

#### AI Analysis Commands

| Command | Description |
|---------|-------------|
| `:LspLogLensExplain [N]` | Analyze last N errors from LSP log with AI (default: 10) |
| `:LspLogLensAnalyze` | Analyze current buffer's diagnostics with AI |

### Keybindings

All keybindings use `<leader>L` prefix (LSP Log):

| Key | Command | Description | Mode |
|-----|---------|-------------|------|
| `<leader>Ll` | `:LspLogLensOpen` | Open LSP log | Normal |
| `<leader>Lt` | `:LspLogLensTail` | Tail LSP log | Normal |
| `<leader>Lf` | `:LspLogLensFormatted` | Formatted log view | Normal |
| `<leader>Le` | `:LspLogLensErrors` | Show errors/warnings | Normal |
| `<leader>Lj` | `:LspLogLensJdtls` | JDTLS-specific logs | Normal |
| `<leader>Lx` | `:LspLogLensExplain` | AI explain errors | Normal |
| `<leader>La` | `:LspLogLensAnalyze` | AI analyze buffer | Normal |
| `<leader>Lc` | `:LspLogLensClear` | Clear log file | Normal |
| `<leader>Li` | `:LspLogLensInfo` | Log file info | Normal |

### Features

#### Log Viewing

- **Raw Log Access**: Open full LSP log file for manual inspection
- **Live Tailing**: Real-time log monitoring with `tail -f` in terminal split
- **Error Filtering**: Extract only ERROR/WARN entries from logs
- **Formatted View**: Pretty-printed log with entry separators and timestamps
- **JDTLS Filtering**: Show only Java Language Server related entries
- **Log Management**: Clear log file, view size and line count

#### AI Analysis

- **Error Explanation**: AI-powered explanations of LSP errors in plain English
- **Context-Aware**: Understands JDTLS, Java, and LSP terminology
- **Buffer Diagnostics**: Analyze current file's diagnostics
- **Actionable Fixes**: Provides specific code examples and next steps
- **Severity Prioritization**: Analyzes errors before warnings
- **Offline Processing**: Runs completely locally using Ollama

### Usage Tutorial

#### 1. View LSP Logs

**Open raw log**:
```vim
:LspLogLensOpen
" Or press: <leader>Ll
```

**Tail log in real-time** (live updates):
```vim
:LspLogLensTail
" Or press: <leader>Lt
```

**View formatted log** (pretty-printed):
```vim
:LspLogLensFormatted
" Or press: <leader>Lf
```
- Organized by timestamps
- Entry separators for readability
- Press 'q' to close, 'r' to refresh

**Show only errors/warnings**:
```vim
:LspLogLensErrors      " Last 50 errors
:LspLogLensErrors 100  " Last 100 errors
" Or press: <leader>Le
```

**Filter JDTLS entries**:
```vim
:LspLogLensJdtls
" Or press: <leader>Lj
```

#### 2. Get Log Information

```vim
:LspLogLensInfo
" Or press: <leader>Li
```

Shows:
- Log file path
- File size in MB
- Total line count

#### 3. AI-Powered Error Analysis

**Analyze LSP log errors**:
```vim
:LspLogLensExplain       " Analyze last 10 errors
:LspLogLensExplain 20    " Analyze last 20 errors
" Or press: <leader>Lx
```

**Analyze current buffer diagnostics**:
```vim
:LspLogLensAnalyze
" Or press: <leader>La
```

**What the AI does**:
1. Extracts ERROR/WARN entries from LSP log or current buffer
2. Sends to Ollama with JDTLS/Java/LSP context
3. Explains each error in simple terms
4. Identifies root causes
5. Provides specific fixes and code examples
6. Displays results in markdown buffer (press 'q' to close)

#### 4. Clear Log File

```vim
:LspLogLensClear
" Or press: <leader>Lc
```

Useful when log file grows too large or contains stale entries.

### Example Workflows

#### Workflow 1: Debugging JDTLS Issues

1. JDTLS isn't working correctly
2. Press `<leader>Lt` to tail the log
3. Trigger the issue (e.g., open Java file)
4. Watch log output in real-time
5. Press `<Esc><Esc>` to exit terminal mode
6. Press `<leader>Lx` to get AI explanation of errors
7. Follow AI suggestions to fix the issue

#### Workflow 2: Understanding Compilation Errors

1. Java file has red squiggly lines (diagnostics)
2. Press `<leader>La` to analyze buffer diagnostics
3. AI explains each error in plain English
4. Get actionable code fixes
5. Apply suggestions
6. Press 'q' to close explanation window

#### Workflow 3: Log File Maintenance

1. Check log file size: `<leader>Li`
2. If too large (e.g., > 50 MB):
   - Review important errors: `<leader>Le`
   - Save analysis: `:LspLogLensExplain 100`
   - Clear log: `<leader>Lc`
3. Continue development with fresh log

### Formatted Log View Features

The `:LspLogLensFormatted` command provides:

- **Timestamp Headers**: Each log entry shows `[LEVEL] DATE TIME`
- **Entry Separators**: Visual separators between log entries
- **Syntax Highlighting**: Log filetype for better readability
- **Read-only Buffer**: Prevents accidental modifications
- **Keymaps**:
  - `q` - Close window
  - `r` - Refresh log (reload from disk)

### AI Analysis Features

- **Model**: Uses `qwen2.5-coder:7b-instruct` (7 billion parameters)
- **Fast**: Optimized for quick responses on code-related queries
- **Contextual**: Prompts include LSP/JDTLS/Java context
- **Markdown Output**: Results displayed in formatted markdown buffer
- **Error Handling**: Gracefully handles Ollama unavailability
- **Offline**: No internet required, runs locally

### Tips & Tricks

1. **Regular Cleanup**: Run `:LspLogLensInfo` periodically to check log size
2. **Live Debugging**: Use `:LspLogLensTail` when troubleshooting JDTLS startup
3. **AI Analysis Limit**: Start with 10 errors, increase if needed for more context
4. **Formatted View**: Use `:LspLogLensFormatted` for easier reading than raw log
5. **JDTLS Filter**: Use `:LspLogLensJdtls` when debugging Java-specific issues
6. **Buffer Diagnostics**: `:LspLogLensAnalyze` is faster than log analysis for current file
7. **Save AI Results**: Copy explanation buffer content before closing with 'q'

### Troubleshooting

**Ollama not available**:
```
Error: Ollama is not available. Please install Ollama first.
```
- Install Ollama: `brew install ollama`
- Download model: `ollama pull qwen2.5-coder:7b-instruct`
- Start Ollama: `ollama serve` (runs in background)

**No errors found**:
```
Error: No errors or warnings found in LSP log
```
- LSP may not have logged errors yet
- Try analyzing buffer diagnostics instead: `:LspLogLensAnalyze`
- Check log file exists: `:LspLogLensInfo`

**AI analysis takes too long**:
- Reduce number of errors: `:LspLogLensExplain 5`
- Ensure Ollama is running in background
- Check system resources (model uses ~4GB RAM)

### Java Build Cleanup

| Command | Description |
|---------|-------------|
| `:CleanBuildFiles` | Remove Java build artifacts (.project, .settings, bin/, build/) |

**Configuration**: `lua/commands/clean-build-files.lua`

Useful for cleaning up Java project metadata when switching between IDEs or fixing project configuration issues.

---

## Telescope Internal Navigation

These keymaps work **inside Telescope** picker windows (Insert mode):

| Key | Description | Mode |
|-----|-------------|------|
| `<C-n>` | Cycle history next | Insert |
| `<C-p>` | Cycle history previous | Insert |
| `<C-j>` | Move selection next (preview) | Insert |
| `<C-k>` | Move selection previous (preview) | Insert |
| `<C-a>` | Send all to quickfix list | Insert |
| `<C-q>` | Send selected to quickfix list | Insert |

---

## Quick Reference Card

### Most Used Keymaps

```
Essential Navigation:
  <leader>ff     Find files
  <leader>fg     Live grep
  <leader>ee     Toggle file explorer
  <leader>a      Add to Harpoon
  <Shift-Tab>    Harpoon menu

LSP:
  <leader>cd     Go to definition
  <leader>ca     Code actions
  <leader>cR     Rename symbol
  <leader>cf     Format code

Git:
  <leader>gs     Git status
  <leader>gl     LazyGit

Debug:
  <leader>dt     Toggle breakpoint
  <leader>dc     Start/continue debug

Database:
  <leader>Dt     Toggle database UI
  <leader>De     Execute query

DevRun:
  <leader>Rr     DevRun picker
  <leader>Rl     Toggle logs console
  <leader>Rt     Show active tasks

LspLogLens:
  <leader>Ll     Open LSP log
  <leader>Lf     Formatted log view
  <leader>Lx     AI explain errors
  <leader>La     AI analyze buffer

AI:
  <C-,>          Toggle Claude Code
  <leader>Ac     Toggle Claude Code
  <leader>AC     Continue conversation
```

---

## Tips & Tricks

1. **Leader Key**: All leader keymaps start with `<Space>`. The which-key plugin will show available options after pressing `<Space>`.

2. **Window Navigation**: Use `<C-h/j/k/l>` for quick window switching (works like Vim motions).

3. **Telescope**: After opening any Telescope picker, use `<C-j/k>` to navigate and `<CR>` to select.

4. **Completion**: In insert mode, `<C-Space>` manually triggers completion if it doesn't auto-appear.

5. **Java & Flutter**: Language-specific keymaps only work in their respective file types.

6. **Harpoon Workflow**: Mark frequently used files with `<leader>a`, then quickly access them via `<Shift-Tab>`.

7. **Claude Code Toggle**: `<C-,>` works in both normal and terminal mode for quick AI assistance.

---

## Which-Key Groups

Press `<Space>` and wait to see all available key groups:

- `<leader>a` - Harpoon
- `<leader>A` - AI/Claude Code
- `<leader>/` - Comments
- `<leader>J` - Java (with subgroups: Js, Jr)
- `<leader>F` - Flutter
- `<leader>t` - Tests
- `<leader>c` - Code/LSP
- `<leader>d` - Debug (with subgroup: ds)
- `<leader>D` - Database
- `<leader>L` - Lsp Log Lens
- `<leader>R` - Run Configurations
- `<leader>e` - Explorer
- `<leader>f` - Find/Telescope
- `<leader>g` - Git
- `<leader>w` - Window
- `<leader>u` - Undo
- `<leader>W` - Workspace

---

## Getting Help

- **Which-Key**: Press `<Space>` and wait 1 second to see available keymaps
- **Telescope Help**: `:Telescope keymaps` to search all keymaps
- **Check LSP**: `:LspInfo` to see active language servers
- **Mason Packages**: `:Mason` to manage LSP servers and tools

---

**Generated from**: Neovim configuration at `~/.config/nvim`
