# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Neovim configuration focused on Java/Spring Boot and Flutter/Dart development with modern LSP, debugging, and testing capabilities. The configuration uses lazy.nvim for plugin management and is structured with clear separation of concerns.

**Last Updated**: October 2025 - JDTLS ftplugin Configuration:
- **JDTLS setup via ftplugin/java.lua** - Neovim's standard approach for filetype-specific config
- **Added Flutter/Dart development** - Full Flutter SDK integration via flutter-tools.nvim
- Manual JDTLS setup via `lua/config/jdtls.lua` (auto-loaded by `ftplugin/java.lua`)
- Spring Boot support via `JavaHello/spring-boot.nvim` plugin
- Google Java Style formatter with comprehensive Java settings
- Updated to Neovim 0.11+ LSP API (`vim.lsp.config`)
- Removed deprecated plugins (auto-session, nvim-ts-context-commentstring, Copilot, neotest)
- Added Claude Code integration, lazydev.nvim, and mini.icons enhancements

## Architecture

### Configuration Structure

- `init.lua` - Entry point that loads all configuration modules
- `ftplugin/` - Filetype-specific configurations (auto-loaded by Neovim):
  - `java.lua` - Java-specific setup (auto-loads JDTLS when opening .java files)
- `lua/config/` - Core configuration files:
  - `options.lua` - Vim options (line numbers, tabs, clipboard, etc.)
  - `keymaps.lua` - Global keybindings (window navigation, splits)
  - `autocmds.lua` - Autocommands (custom autocommands as needed)
  - `jdtls.lua` - JDTLS configuration (called by ftplugin/java.lua)
  - `eclipse-java-google-style.xml` - Google Java Style formatter configuration
  - `lsp-servers.lua` - LSP server configurations using modern vim.lsp.config API
  - `lazy.lua` - Lazy.nvim plugin manager bootstrap and configuration
  - `backup/` - Backup directory with old configuration files
- `lua/plugins/` - Plugin specifications (one file per plugin/feature)
- `lua/commands/` - Custom commands (e.g., clean-build-files.lua)
- `neoconf.json` - JDTLS configuration overrides for Java development

### Plugin Management

Uses lazy.nvim with:
- Auto-loading from `lua/plugins/` directory
- **Fallback enabled**: Falls back to normal installation if dev path doesn't exist
- Change detection disabled for notifications
- Auto-update checking enabled

### Leader Key

Leader key is `<Space>` (defined in both `lua/config/keymaps.lua` and `lua/config/lazy.lua`)

## Java Development Setup

### Manual JDTLS Configuration (Current - October 2025)

**Current Setup**: Using manual `nvim-jdtls` configuration via ftplugin

**Why ftplugin?**
- ftplugin is Neovim's standard approach for filetype-specific configuration
- `ftplugin/java.lua` automatically loads when opening .java files **after** plugins are ready
- More reliable than FileType autocmds for plugin-dependent setups
- Cleaner separation of concerns (Java config in dedicated ftplugin directory)

**Primary Configuration**: `lua/config/jdtls.lua` (called by ftplugin/java.lua)
- Comprehensive JDTLS setup with error handling and validation
- Java 21.0.4-zulu runtime path: `~/.sdkman/candidates/java/21.0.4-zulu`
- Google Java Style formatter: `lua/config/eclipse-java-google-style.xml`
- Lombok support via javaagent
- Spring Boot extensions via `JavaHello/spring-boot.nvim` plugin (with graceful fallback)
- Cross-platform support (detects mac/linux/win)
- **Performance-optimized settings** (October 2025):
  - Code lens disabled by default for better performance
  - Reduced logging level (WARNING instead of ALL)
  - Interactive build updates (not automatic)
  - Source downloads disabled (download manually if needed)
  - Optimized memory allocation (2G max, 1G initial)
  - setup_dap_main_class_configs() disabled for faster startup

**ftplugin Trigger**: `ftplugin/java.lua`
- Automatically loaded by Neovim when opening .java files
- Calls `require("config.jdtls").setup_jdtls()` directly
- Loads after lazy.nvim completes plugin initialization

**Plugin Configuration**: `lua/plugins/java-lsp.lua`
- Loads `mfussenegger/nvim-jdtls` for Java files only (ft = "java")
- DAP (Debug Adapter Protocol) dependency included

**Mason Package Management**: `lua/config/lsp-servers.lua`
- Ensures `jdtls`, `java-debug-adapter`, `java-test` are installed via Mason
- Packages available before ftplugin loads

**Root markers for project detection**:
- `gradlew`, `mvnw`
- `.git`
- `pom.xml`
- `build.gradle`, `settings.gradle`

**Features enabled**:
- Java debugging via DAP (hotcodereplace: auto)
- Java test support (JUnit, TestNG)
- Code lens (references, implementations) - **disabled by default** for performance
- Refactoring tools (extract variable/constant/method)
- Spring Boot LSP commands (when available)
- Organize imports with custom thresholds (starThreshold: 9999)

**Mason Integration**:
- JDTLS installed via Mason (`jdtls` package)
- Java Debug Adapter (`java-debug-adapter` package)
- Java Test (`java-test` package)
- Automatic bundle loading for debug and test JARs

**JDTLS Settings**:
- Memory allocation: 2GB max heap (`-Xmx2G`), 1GB initial (`-Xms1G`)
- G1GC garbage collector with string deduplication
- Logging level: WARNING (reduced from ALL for performance)
- Build configuration: interactive mode (not automatic)
- Source downloads: disabled (download manually via LSP commands if needed)
- Import order: java, jakarta, javax, com, org
- Favorite static members: Hamcrest, JUnit, AssertJ, Mockito
- Filtered types: com.sun.*, jdk.*, sun.*, java.awt.*, io.micrometer.shaded.*
- Code generation: toString templates, useBlocks enabled
- Inlay hints: parameter names enabled for all
- Auto-organize imports on save
- Fernflower decompiler for sources

### Spring Boot Support

**JavaHello/spring-boot.nvim** (enabled October 2025):
- Plugin: `lua/plugins/springboot.lua`
- Provides Spring Boot-specific JDTLS extensions
- Automatically loads Spring Boot bundles via `spring_boot.java_extensions()`
- Initializes Spring Boot LSP commands via `spring_boot.init_lsp_commands()`
- Requires fzf-lua dependency for Spring Boot-specific commands

### Testing

**JDTLS native testing** (via nvim-jdtls):
- Integrated with JDTLS via java-test bundles
- Supports JUnit, TestNG frameworks
- DAP integration for debugging tests
- Test methods: `<leader>tt` (test nearest method), `<leader>tc` (test class)
- Test generation: `<leader>tg` (generate tests), `<leader>to` (open test class)
- Tests run via JDTLS commands (`require('jdtls').test_nearest_method()`, etc.)

**Neotest REMOVED**: The neotest-gradle plugin was removed (January 2025):
- Had local path dependency issues
- JDTLS provides native test support via java-test bundles

### Debugging

DAP (Debug Adapter Protocol) configured in `lua/plugins/nvim-dap.lua` and `lua/config/jdtls.lua`:
- `<leader>dt` - Toggle breakpoint
- `<leader>dc` - Debug continue/start
- `<leader>dx` - Close debug UI
- DAP UI auto-opens on debug launch
- Hotcode replace enabled (`hotcodereplace: "auto"`)
- Remote attach configuration on 127.0.0.1:5005
- Main class configs: `setup_dap_main_class_configs()` **disabled by default** for faster startup

### Java-Specific Keymaps

All Java keymaps are defined in `lua/config/jdtls.lua` and loaded via `ftplugin/java.lua` (buffer-local, only active in Java files):

**Source Actions** (`<leader>Js` prefix):
- `<leader>Jsi` - Organize imports

**Refactor Actions** (`<leader>Jr` prefix):
- `<leader>Jrv` - Extract variable (normal and visual mode)
- `<leader>Jrc` - Extract constant (normal and visual mode)
- `<leader>Jrm` - Extract method (visual mode)

**Test Actions** (`<leader>t` prefix):
- `<leader>tt` - Run test method (normal and visual mode)
- `<leader>tc` - Run test class
- `<leader>tg` - Generate tests for current class
- `<leader>to` - Open test class (go to test/subject)

**Build Actions** (`<leader>J` prefix):
- `<leader>JU` - Update all project configurations
- `<leader>JB` - Build all projects

## Flutter/Dart Development Setup

### Flutter Tools Integration (Current - October 2025)

**Current Setup**: Using `akinsho/flutter-tools.nvim` for simple Flutter development

**Primary Configuration**: `lua/plugins/flutter.lua` (simplified, minimal configuration)
- Flutter SDK integration via flutter-tools.nvim
- Dart LSP (dartls) managed by flutter-tools
- Hot reload/restart functionality
- Device/emulator management
- Flutter DevTools integration
- Log output in bottom split window

**Configuration Philosophy**:
- **Keep it simple**: Minimal customization, using flutter-tools.nvim defaults
- **No DAP auto-open**: `debugger.enabled = false` prevents DAP from opening on Flutter run
- **Essential features only**: No custom commands, no over-configured LSP settings
- **Standard flutter-tools commands**: Only official flutter-tools.nvim commands via keymaps

**Platform Support**:
- **iOS**: Requires Xcode and iOS Simulator
- **Android**: Requires Android SDK and Android Emulator
- **Device commands**: `:FlutterDevices` lists all connected devices
- **Emulator commands**: `:FlutterEmulators` lists and launches emulators

### Flutter Debugging

**Configuration**: DAP disabled by default (`debugger.enabled = false` in `lua/plugins/flutter.lua`)

To debug Flutter apps:
- Enable DAP manually when needed: `:lua require('flutter-tools').setup({ debugger = { enabled = true } })`
- Or use standard Flutter debugging tools outside Neovim
- Keeps Flutter run workflow simple and fast without DAP overhead

### Flutter-Specific Keymaps

All Flutter keymaps use `<leader>F` prefix (defined in `lua/plugins/flutter.lua`):

**Run and Reload** (`<leader>F` prefix):
- `<leader>Fr` - Run Flutter app
- `<leader>Fq` - Quit Flutter app
- `<leader>FR` - Restart Flutter app (full restart)
- `<leader>Fh` - Hot reload (preserves app state)

**Devices and Emulators**:
- `<leader>Fd` - List Flutter devices
- `<leader>Fe` - List/launch Flutter emulators

**DevTools**:
- `<leader>FT` - Open Flutter DevTools

**UI and Logs**:
- `<leader>Fo` - Toggle Flutter outline (widget tree)
- `<leader>FL` - Toggle Flutter log window (open/close)
- `<leader>Fl` - Clear Flutter logs

**Pub Commands**:
- `<leader>Fp` - Run `flutter pub get`
- `<leader>FP` - Run `flutter pub upgrade`

**Utilities**:
- `<leader>Fc` - Copy profiler URL
- `<leader>Fs` - Restart Dart LSP
- `<leader>Fn` - Rename (creates both .dart and test file)

### Dart-Specific Settings

Dart file settings (configured via FileType autocmd in `lua/plugins/flutter.lua`):
- Tab size: 2 spaces
- Shift width: 2 spaces
- Expand tabs: true
- Color column: 80 characters (Dart style guide)

### Treesitter Support

**Configuration**: `lua/plugins/treesitter.lua`

Dart parser installed for:
- Syntax highlighting
- Code folding
- Indentation
- Text objects

## DevRun Task Runner

DevRun is a custom development task runner for executing Gradle, Tomcat, and shell commands with VSCode-compatible variable substitution.

### Overview

**Location**: `lua/devrun/`

DevRun provides IntelliJ/VSCode-style run configurations with:
- JSON-based configuration files (`run-configurations.json`)
- Support for Gradle, Tomcat servers, and generic shell commands
- 30+ variables for portable, environment-aware configurations
- Background task execution with real-time log streaming
- Telescope-based UI for interactive configuration management
- Before-run task dependencies
- Hot reload support for exploded WARs (Tomcat)

### File Structure

- `lua/devrun/init.lua` - Main module with commands and task orchestration
- `lua/devrun/variables.lua` - Variable resolution system (30+ variables)
- `lua/devrun/parser.lua` - JSON configuration parser
- `lua/devrun/task-manager.lua` - Background task execution and lifecycle management
- `lua/devrun/log-ui.lua` - Log console window with real-time output
- `lua/devrun/config-builder.lua` - Interactive Telescope-based config creation
- `lua/devrun/executors/` - Task type executors:
  - `gradle.lua` - Gradle task execution with VM args
  - `tomcat.lua` - Tomcat deployment (packed/exploded WARs)
  - `command.lua` - Generic shell command execution
  - `init.lua` - Executor registry
- `lua/devrun/VARIABLES.md` - Complete variable documentation (350+ lines)

### Supported Task Types

#### 1. Gradle Tasks
Execute Gradle build tasks with VM arguments:
```json
{
  "type": "gradle",
  "name": "Build Application",
  "command": "./gradlew bootRun",
  "vmArgs": ["-Xmx2G", "-Dspring.profiles.active=dev"],
  "cwd": "${workspaceFolder}",
  "env": {
    "JAVA_HOME": "${env:JAVA_HOME}"
  }
}
```

#### 2. Tomcat Server
Deploy and run Tomcat with packed or exploded WARs:
```json
{
  "type": "tomcat",
  "name": "Deploy to Tomcat",
  "artifact": "${workspaceFolder}/build/libs/${projectName}.war",
  "tomcatHome": "${env:TOMCAT_HOME}",
  "httpPort": 8080,
  "debugPort": 5005,
  "contextPath": "myapp",
  "vmArgs": ["-Xmx1G"],
  "cleanDeploy": true
}
```

**Exploded WAR Support** (New):
- Supports both packed `.war` files and exploded WAR directories
- Automatic detection based on artifact type (file vs directory)
- Uses `rsync` for fast incremental deployment (falls back to `cp -r`)
- Faster development cycles - no need to repackage for every change
- Hot reload support for JSP/static resources

#### 3. Generic Commands
Execute any shell command:
```json
{
  "type": "command",
  "name": "Custom Script",
  "command": "./deploy.sh > ${workspaceFolder}/logs/deploy-${date}.log",
  "cwd": "${workspaceFolder}"
}
```

### Variable System (30+ Variables)

DevRun supports VSCode-compatible variable substitution with 5 categories:

#### Path Variables (10)
- `${workspaceFolder}` - Current workspace directory
- `${workspaceFolderBasename}` - Workspace folder name
- `${userHome}` - User home directory
- `${file}` - Currently open file (absolute path)
- `${fileBasename}` - File name with extension
- `${fileBasenameNoExtension}` - File name without extension
- `${fileDirname}` - Directory containing file
- `${fileExtname}` - File extension
- `${relativeFile}` - File path relative to workspace
- `${relativeFileDirname}` - File directory relative to workspace

#### Project Variables (3)
- `${projectName}` - Project name (from workspace folder)
- `${buildDir}` - Build output directory (default: "build")
- `${targetDir}` - Target directory (default: "build")

#### Date/Time Variables (3)
- `${date}` - Current date (YYYY-MM-DD)
- `${time}` - Current time (HH:MM:SS)
- `${timestamp}` - Unix timestamp

#### Environment Variables (∞)
- `${env:VARIABLE_NAME}` - Access any environment variable
- Examples: `${env:JAVA_HOME}`, `${env:TOMCAT_HOME}`

#### Config References (∞)
- `${config:field}` - Reference other config fields
- Example: `${config:httpPort}` avoids value duplication

#### Special Variables (1)
- `${random}` - Random 6-digit number (useful for ports)

**Documentation**: See `lua/devrun/VARIABLES.md` for complete reference with examples

### DevRun Commands

All commands use the `DevRun` prefix:

- `:DevRun` - Show Telescope picker for all configurations
- `:DevRunConfig <name>` - Run specific configuration by name (with tab completion)
- `:DevRunTasks` - Show all active background tasks
- `:DevRunLogs [task_name]` - Show log console (default: latest task)
- `:DevRunToggleLogs` - Toggle log console window
- `:DevRunStop [task_name]` - Stop running task (with picker if no name)
- `:DevRunStopAll` - Stop all running tasks
- `:DevRunReload` - Reload configurations from JSON file
- `:DevRunInit` - Create example `run-configurations.json` file
- `:DevRunAddRunConfiguration [type]` - Interactive config creation (type: gradle/tomcat/command)
- `:DevRunVariables` - Show all available variables and their current values

### DevRun Keymaps

All under `<leader>R` prefix (Run):

- `<leader>Rr` - Open DevRun picker (Telescope)
- `<leader>Rt` - Show active tasks
- `<leader>Rl` - Toggle logs console
- `<leader>Rs` - Stop task (with picker)
- `<leader>RR` - Reload configurations
- `<leader>RI` - Initialize example config
- `<leader>RA` - Add new configuration interactively

### Log Console Features

The DevRun log console (`lua/devrun/log-ui.lua`) provides:
- Real-time output streaming (stdout/stderr with `[ERROR]` prefix)
- Task switching (view logs for different tasks)
- Auto-scroll (toggle with `a` key)
- Log clearing (press `c` to clear current task logs)
- Persistent logs (survive task completion)
- Bottom split window (15 lines)

**Keymaps in log console**:
- `q` - Close log window
- `c` - Clear current task's logs
- `a` - Toggle auto-scroll on/off

### Configuration File

**Location**: `run-configurations.json` in workspace root

**Format**:
```json
{
  "configurations": [
    {
      "type": "gradle",
      "name": "Build",
      "command": "./gradlew build",
      "beforeRun": "Clean Build"
    },
    {
      "type": "tomcat",
      "name": "Deploy",
      "artifact": "${workspaceFolder}/build/libs/app.war",
      "tomcatHome": "${env:TOMCAT_HOME}",
      "httpPort": 8080
    }
  ]
}
```

### Before-Run Dependencies

Tasks can specify dependencies via `beforeRun` field:
```json
{
  "name": "Deploy App",
  "type": "tomcat",
  "beforeRun": "Build WAR",
  "artifact": "${workspaceFolder}/build/libs/app.war"
}
```

The before-run task executes first, then the main task runs after a 1-second delay.

### Interactive Configuration Builder

**Command**: `:DevRunAddRunConfiguration [type]`

Features:
- Telescope-based UI for all selections (yes/no, type selection, beforeRun selection)
- Synchronous `vim.fn.input()` for text fields (with file completion for paths)
- Step-by-step prompts with progress indicators (e.g., "Step 3/12")
- Field validation (ports, paths, context names)
- Multi-value support (VM args, environment variables)
- Configuration summary before saving
- Automatically appends to `run-configurations.json`

### Task Management

**Background Execution**:
- Tasks run via `vim.system()` in background
- Real-time output streaming to log console
- Task registry tracks: ID, name, status, command, cwd, duration
- Exit code handling with notifications
- Graceful shutdown (SIGTERM for Gradle/Command, `catalina.sh stop` for Tomcat)

**Task States**:
- `starting` - Task initialization
- `running` - Executing
- `completed` - Finished successfully (exit code 0)
- `failed` - Finished with error (non-zero exit code)
- `stopped` - Manually stopped by user

### Fast Event Context Handling

DevRun properly handles Neovim's fast event context restrictions:
- `vim.system()` callbacks wrapped in `vim.schedule()`
- UI operations (vim.notify, buffer updates) deferred to safe context
- No `E5560` errors during task execution

### Troubleshooting DevRun

1. **Configuration not found**: Run `:DevRunInit` to create example config
2. **Variables not resolving**: Use `:DevRunVariables` to see current values
3. **Task not starting**: Check `:DevRunTasks` for status, view logs with `:DevRunLogs`
4. **Tomcat deployment fails**: Verify `${env:TOMCAT_HOME}` is set, check artifact path
5. **Gradle task fails**: Verify `./gradlew` exists, check Java version
6. **Logs not updating**: Check auto-scroll is enabled (press `a` in log console)

### Variable Usage Examples

**Portable paths**:
```json
"artifact": "${workspaceFolder}/build/libs/${projectName}.war"
```

**Environment-specific**:
```json
"tomcatHome": "${env:TOMCAT_HOME}",
"env": { "JAVA_HOME": "${env:JAVA_HOME}" }
```

**Dynamic log files**:
```json
"command": "./run.sh > ${workspaceFolder}/logs/app-${date}.log"
```

**Config references** (avoid duplication):
```json
"httpPort": 8080,
"env": { "SERVER_URL": "http://localhost:${config:httpPort}" }
```

## LSP Configuration

### Modern Neovim 0.11+ API

**Configuration**: `lua/config/lsp-servers.lua`

Uses the **modern `vim.lsp.config` API** (replaces deprecated `require('lspconfig')`):
- LSP servers defined via `vim.lsp.config.server_name = { ... }`
- Servers enabled via FileType autocmd: `vim.lsp.enable(server)`
- **mason-lspconfig.nvim removed** - it uses deprecated lspconfig API
- Mason still handles server installation via direct mason-registry API
- No more deprecated lspconfig framework warnings
- Centralized LSP configuration in `lua/config/lsp-servers.lua`

### Mason-Managed LSP Servers

- `lua_ls` - Lua Language Server (with lazydev.nvim integration)
- `ts_ls` - TypeScript/JavaScript (with inlay hints enabled)
- `jdtls` - Java (manually configured via lua/config/jdtls.lua, triggered by ftplugin/java.lua)
- `dartls` - Dart/Flutter (configured via flutter-tools.nvim)
- `jsonls` - JSON (with SchemaStore integration)
- `docker_compose_language_service` - Docker Compose
- `dockerls` - Dockerfile

Debug adapters:
- Java: Manually configured via lua/config/jdtls.lua (loaded by ftplugin/java.lua)
  - `java-debug-adapter` - Java debugging support
  - `java-test` - Java test framework support
- Dart/Flutter: Configured via flutter-tools.nvim
  - `dart-debug-adapter` - Dart/Flutter debugging support (auto-installed)
- Other languages: Use mason-nvim-dap as needed

### LSP Keymaps

All under `<leader>c` prefix (defined in lsp-config.lua):
- `<leader>ce` - Line diagnostics (open float)
- `<leader>ch` - Hover documentation
- `<leader>cs` - Show signature
- `<leader>cd` - Goto definition
- `<leader>ca` - Code actions
- `<leader>cr` - Goto references (Telescope)
- `<leader>ci` - Goto implementations (Telescope)
- `<leader>cR` - Rename symbol
- `<leader>cD` - Goto declaration
- `<leader>cf` - Format code (async via none-ls)

## Completion (nvim-cmp)

**Configuration**: `lua/plugins/cmp.lua`

Enhanced with mini.icons integration:
- LSP completion with icons and kind indicators
- Source labels: `[LSP]`, `[Snippet]`, `[Buffer]`, `[Path]`
- LuaSnip snippet support
- Friendly-snippets for VSCode-like snippets

**Keymaps**:
- `<C-k>` - Previous suggestion
- `<C-j>` - Next suggestion
- `<C-Space>` - Show completions
- `<C-e>` - Close completion window
- `<CR>` - Confirm selection (only when explicitly selected)
- `<C-b>` / `<C-f>` - Scroll documentation

## Lua Development

**lazydev.nvim** (added January 2025):
- Provides autocomplete for Neovim APIs (`vim.*`, `vim.lsp.*`, etc.)
- Integrates with lua_ls for Neovim development
- Includes luvit-meta for `vim.uv` typings
- Automatically configured in lua_ls settings

**Configuration**: `lua/plugins/lazydev.lua`

## Formatting and Linting (none-ls)

**Configuration**: `lua/plugins/none-ls.lua`

Formatters and linters:
- `stylua` - Lua formatter
- `prettier` - JavaScript/TypeScript/JSON/etc formatter
- `eslint_d` - JavaScript/TypeScript linter

**Keymap**: `<leader>cf` - Format code (async to prevent editor freezing)

## Finding and Navigation

### Telescope Keymaps

File operations (`<leader>f` prefix):
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fd` - Diagnostics
- `<leader>fr` - Resume last search
- `<leader>f.` - Recent files
- `<leader>fb` - Buffers
- `<leader>fs` - Fuzzy find in current buffer
- `<leader>fq` - Quickfix list
- `<leader>fQ` - Quickfix history
- `<leader>fI` - LSP implementations
- `<leader>fR` - LSP references
- `<leader>fD` - LSP definitions
- `<leader>fT` - LSP type definitions
- `<leader>fS` - Document symbols

Git operations (`<leader>g` prefix):
- `<leader>gs` - Git status
- `<leader>gb` - Git branches

### Harpoon

**Configuration**: `lua/plugins/harpoon.lua` (harpoon2)

- `<leader>a` - Add file to Harpoon
- `<Shift-Tab>` - Toggle Harpoon menu (via Telescope)

### FZF

Additional fuzzy finding via `ibhagwan/fzf-lua` (configured in `lua/plugins/fzf.lua`)

## AI Assistants

### Claude Code (Current)

**Configuration**: `lua/plugins/claude-code.lua`

Official Claude Code integration (`coder/claudecode.nvim`):
- Terminal split on right side (30% width)
- Auto-start enabled
- Diff integration with vertical splits

**Keymaps** (`<leader>A` prefix for AI):
- `<C-,>` - Toggle Claude Code window (normal and terminal mode)
- `<leader>Ac` - Toggle Claude Code
- `<leader>AC` - Continue last conversation
- `<leader>Af` - Focus Claude Code terminal
- `<leader>Ar` - Resume last session
- `<leader>Am` - Select Claude model
- `<leader>Ab` - Add current buffer to context
- `<leader>As` - Send selection to Claude (visual mode)

### Avante (AI Assistant)

**Configuration**: `lua/plugins/ai.lua`

Multi-provider AI assistant (Copilot dependency removed):
- Supports Claude, OpenAI, and other providers
- Copilot.lua dependency removed (not using Copilot)

### Copilot REMOVED

All GitHub Copilot plugins removed (January 2025):
- `lua/plugins/github.copilot.lua` deleted (contained copilot.vim, CopilotChat.nvim)
- `zbirenbaum/copilot.lua` dependency removed from ai.lua
- Replaced with Claude Code integration

## Treesitter

**Configuration**: `lua/plugins/treesitter.lua`

Modern Treesitter setup with:
- Auto-installation of parsers for: vim, lua, java, dart, javascript, typescript, html, css, json, tsx, markdown, gitignore
- **nvim-ts-autotag**: Separate setup required (breaking change handled)
  - Configured via `require("nvim-ts-autotag").setup()`
  - No longer configured through treesitter setup
- Syntax highlighting enabled
- nvim-ts-context-commentstring REMOVED (Neovim 0.10+ has built-in support)

## File Explorer

**neo-tree** (sole file explorer):
- `<leader>ee` - Toggle file explorer
- `<leader>ef` - Focus file explorer
- `<leader>ec` - Close file explorer
- Git status integration
- Window width: 40
- Position: left side

**Window Behavior**:
- Positioned on left side with explicit `position = "left"` setting
- Files open in editor window on right side (prevents replacement of neo-tree)
- Focus automatically moves to opened file
- Neo-tree stays open when files are selected
- Directory opening controlled via `hijack_netrw_behavior = "open_default"`
- Use `<C-w>=` to equalize window sizes if layout gets misaligned

**Removed file explorers**:
- nvim-tree (removed - duplicate functionality)
- triptych (removed - duplicate functionality)

## UI and Utilities

### Statusline (lualine)

**Configuration**: `lua/plugins/lualine.lua`

- auto-session integration removed (plugin was causing errors)
- Standard mode, filename, location, diagnostics display

### Comment.nvim

**Configuration**: `lua/plugins/comment.lua`

- nvim-ts-context-commentstring dependency removed
- Uses Neovim 0.10+ built-in Treesitter commentstring support
- `<leader>/` - Toggle comment

### Other Key Plugins

- **Git**: Diffview, Git integration plugins (`lua/plugins/git.lua`, `lua/plugins/diffview.lua`)
- **UI**: which-key, dressing.nvim, mini.icons
- **Utilities**: auto-pairs, undotree, spectre (search/replace), illuminate

## Removed Plugins (January 2025)

### auto-session
- **Reason**: "Failed to run `config` for auto-session" error
- **Deleted**: `lua/plugins/autosession.lua`
- **Updated**: Removed reference from `lua/plugins/lualine.lua`

### nvim-ts-context-commentstring
- **Reason**: Deprecated - Neovim 0.10+ has built-in Treesitter commentstring support
- **Updated**: `lua/plugins/comment.lua` now uses built-in functionality

### GitHub Copilot (all variants)
- **Reason**: User preference - replaced with Claude Code
- **Deleted**: `lua/plugins/github.copilot.lua` (copilot.vim, CopilotChat.nvim)
- **Updated**: `lua/plugins/ai.lua` (removed copilot.lua dependency)

### neotest-gradle
- **Reason**: Local path dependency issues, redundant with nvim-java test support
- **Deleted**: `lua/plugins/neotest.lua`
- **Alternative**: Use nvim-java's built-in test commands

## Custom Commands

Custom commands are in `lua/commands/`:
- `clean-build-files.lua` - Cleans Java build artifacts (.project, .settings, bin, build directories)
  - Referenced in `init.lua` as `require("commands.clean-build-files")`

## Configuration Best Practices

When modifying this configuration:

1. **Plugin additions**: Add new plugin files to `lua/plugins/` - they're auto-loaded
2. **LSP servers**: Add LSP configurations to `lua/config/lsp-servers.lua` using `vim.lsp.config` API
3. **Java settings**: Modify `lua/config/jdtls.lua` for JDTLS-specific customizations
4. **Flutter settings**: Modify `lua/plugins/flutter.lua` for Flutter/Dart customizations
5. **Keymaps**: Use which-key group prefixes defined in `lua/plugins/whichkey.lua`
6. **Java development**: Uses Java 21.0.4-zulu at `~/.sdkman/candidates/java/21.0.4-zulu`
7. **Flutter development**: Flutter SDK auto-detected; ensure `flutter doctor` passes
8. **Testing**: JDTLS native test support via java-test bundles; keymaps in lua/config/jdtls.lua
9. **Local dev plugins**: Dev path falls back to normal installation if not found
10. **Java formatter**: Google Java Style configured via `lua/config/eclipse-java-google-style.xml`
11. **LSP configuration**: Use `vim.lsp.config` API (Neovim 0.11+) instead of deprecated lspconfig
12. **Formatting**: All formatting is async to prevent editor freezing
13. **Filetype-specific config**: Use ftplugin/ directory for filetype-specific setup (Neovim standard)

## Key Groups (Which-Key)

- `<leader>a` - Harpoon
- `<leader>A` - AI/Claude Code
- `<leader>/` - Comments
- `<leader>J` - Java (with subgroups: `Js` for Source, `Jr` for Refactor)
- `<leader>F` - Flutter (run, reload, devices, DevTools, pub commands)
- `<leader>R` - Run/DevRun (task runner for Gradle/Tomcat/commands)
- `<leader>t` - Tests (JDTLS native via nvim-jdtls)
- `<leader>c` - Code/LSP
- `<leader>d` - Debug (with subgroup: `ds` for Step)
- `<leader>e` - Explorer (neo-tree)
- `<leader>f` - Find/Telescope
- `<leader>g` - Git
- `<leader>w` - Window
- `<leader>u` - Undo
- `<leader>W` - Workspace

## Troubleshooting

### After Configuration Changes

Run `:Lazy sync` to:
- Install new plugins
- Remove deleted plugins
- Update existing plugins

### LSP Not Starting

1. Check Mason installations: `:Mason`
2. Verify LSP server is enabled: `:LspInfo`
3. For Java, ensure nvim-java is loaded: `:lua print(vim.inspect(require('java')))`

### Java Development Issues

If JDTLS isn't working:
1. Check Java version: `java -version` (should show 21.0.4-zulu)
2. Verify JDTLS installation: `:Mason` → check for jdtls, java-debug-adapter, java-test
3. Check JDTLS is running: `:LspInfo` (should show jdtls attached)
4. Verify Spring Boot plugin: `:lua print(vim.inspect(require('spring_boot')))`
5. Check ftplugin loaded: Open a .java file and verify keymaps work (e.g., `<leader>Jsi`)
6. Check Mason packages: `:lua print(vim.inspect(require('mason-registry').get_installed_packages()))`
7. View JDTLS logs: `:lua vim.cmd('e ' .. vim.lsp.get_log_path())`
8. Verify ftplugin exists: Check that `ftplugin/java.lua` file exists

### JDTLS Performance Issues (October 2025)

If JDTLS is slow, hangs, or causes terminal unresponsiveness:

**Performance Optimizations Applied:**
1. **Reduced logging** - Changed from `-Dlog.level=ALL` to `WARNING` (ftplugin/java.lua:246)
2. **Disabled code lens auto-refresh** - Removed BufWritePost autocmd (ftplugin/java.lua:413-422)
3. **Code lens disabled by default** - Set `referencesCodeLens.enabled = false` (ftplugin/java.lua:349)
4. **Interactive build mode** - Changed `updateBuildConfiguration` to `"interactive"` (ftplugin/java.lua:358)
5. **Disabled source downloads** - Set `downloadSources = false` for maven/eclipse (ftplugin/java.lua:294, 297)
6. **Optimized memory** - Reduced max heap from 4G to 2G (ftplugin/java.lua:247)
7. **Disabled main class scanning** - Commented out `setup_dap_main_class_configs()` (ftplugin/java.lua:402)

**Additional Performance Tips:**
- Clear workspace caches: `rm -rf ~/.cache/nvim/jdtls/workspaces/*`
- View workspace cache sizes: `du -sh ~/.cache/nvim/jdtls/workspaces/*`
- Check JDTLS memory usage: Monitor Java process with `top` or Activity Monitor
- For large projects, consider excluding directories in `.jdtls` file at project root
- Manual code lens refresh: `:lua vim.lsp.codelens.refresh()` (when needed)
- Manual source download: Use LSP commands when needed (not automatic)

### Completion Not Working

1. Verify nvim-cmp is loaded: `:lua print(vim.inspect(require('cmp')))`
2. Check completion sources: `:CmpStatus`
3. Ensure LSP is attached: `:LspInfo`

### Flutter Development Issues

If Flutter/Dart LSP isn't working:
1. Check Flutter SDK installation: `flutter doctor`
2. Verify Dart LSP is running: `:LspInfo` (should show dartls attached)
3. Check flutter-tools is loaded: `:lua print(vim.inspect(require('flutter-tools')))`
4. Verify Treesitter Dart parser: `:TSInstallInfo` (dart should be installed)
5. Check available devices: `:FlutterDevices`
6. For iOS: Ensure Xcode is installed and simulators are available
7. For Android: Ensure Android SDK is installed and emulators are configured
8. Mason packages: `:Mason` → check for `dart-debug-adapter`

Common Flutter commands:
- `:FlutterRun` - Run Flutter app on selected device
- `:FlutterDevices` - List all available devices/simulators
- `:FlutterEmulators` - List and launch emulators
- `:FlutterReload` - Hot reload (preserves state)
- `:FlutterRestart` - Hot restart (resets state)
- `:FlutterQuit` - Stop running Flutter app
- `:FlutterOutlineToggle` - Show/hide widget outline

## Recent Changes

### October 2025 - JDTLS ftplugin Configuration

1. **Switched JDTLS to ftplugin approach** - Using Neovim's standard filetype configuration:
   - Created `ftplugin/java.lua` for Java-specific setup
   - Removed FileType autocmd from `lua/config/autocmds.lua`
   - ftplugin auto-loads when opening .java files after plugins are ready
   - Cleaner separation of concerns with dedicated ftplugin directory
   - More reliable than autocmd approach for filetype-specific setup
2. **Rewrote lua/config/jdtls.lua** - Clean, well-documented JDTLS configuration:
   - Updated Java path to 21.0.4-zulu with validation
   - Cross-platform OS detection (mac/linux/win)
   - Better error handling with clear notifications
   - Spring Boot integration with graceful fallback
   - Code lens auto-refresh on save
   - Comprehensive JDTLS settings (import order, filtered types, favorite static members, inlay hints)
   - Google Java Style formatter with fallback handling
   - All Java-specific keymaps properly configured
3. **Updated lua/config/lsp-servers.lua** - Removed manual jdtls config:
   - Removed `vim.lsp.config` and `vim.lsp.enable` for jdtls (handled by autocmd now)
   - Mason package installation still ensures jdtls, java-debug-adapter, java-test are available
   - Clear documentation explaining JDTLS is configured via autocmd
4. **Added Flutter/Dart development** - Simple, minimal Flutter SDK integration:
   - New file: `lua/plugins/flutter.lua` - simplified flutter-tools.nvim configuration
   - Dart LSP via flutter-tools with hot reload, device management, DevTools
   - DAP disabled by default (`debugger.enabled = false`) - no auto-open on Flutter run
   - Standard flutter-tools commands only (no custom commands)
   - Flutter-specific keymaps under `<leader>F` prefix
   - Treesitter Dart parser for syntax highlighting
   - Log output in bottom split window (not new tab)
5. **Simplified Flutter configuration** - Removed over-customization per user requirements:
   - Removed custom Dart commands (DartAnalyze, DartFix, DartFormat, DartRun)
   - Removed custom Flutter helper commands (FlutterRunWithDevice, FlutterRunClean)
   - Removed `<leader>D` which-key group for Dart
   - Removed extra LSP settings (code lens auto-refresh, custom on_attach)
   - Minimal LSP config: only nvim-cmp integration
   - Following official flutter-tools.nvim documentation
6. **Updated documentation** - CLAUDE.md and KEYMAPS.md reflect simplified Flutter setup and autocmd-based JDTLS configuration
7. **Migrated to official Claude Code plugin** - Switched from `greggh/claude-code.nvim` to `coder/claudecode.nvim`:
   - Updated `lua/plugins/claude-code.lua` with official plugin configuration
   - Changed keymaps to `<leader>A` prefix (AI) to avoid conflicts with LSP `<leader>c` prefix
   - Added `<leader>A` which-key group for AI/Claude Code commands
   - New keymaps: `<leader>Ac` (toggle), `<leader>AC` (continue), `<leader>Af` (focus), `<leader>Ar` (resume), `<leader>Am` (select model), `<leader>Ab` (add buffer), `<leader>As` (send selection)
   - Kept `<C-,>` toggle for quick access in both normal and terminal modes
   - Terminal split on right side (30% width) with auto-start enabled
8. **Fixed neo-tree window management issues** - Improved window behavior and positioning:
   - Added explicit `position = "left"` to anchor neo-tree on left side
   - Added `open_files_do_not_replace_types` to prevent files from opening in neo-tree window
   - Changed `file_opened` event handler to move focus instead of closing neo-tree
   - Added `hijack_netrw_behavior = "open_default"` for proper directory opening
   - Neo-tree now stays open when files are selected, with focus automatically moving to editor window
   - Files always open in proper editor window on right side
   - Added `<C-w>=` tip for equalizing window sizes if layout gets misaligned
9. **Added Flutter log toggle shortcut** - Improved Flutter log management:
   - Added `<leader>FL` (capital L) keymap for toggling Flutter log window open/close
   - Complements existing `<leader>Fl` (lowercase l) for clearing logs
   - Provides intuitive pairing: capital for structural change (toggle), lowercase for content change (clear)

### January 2025 - Previous Updates

1. **Updated to vim.lsp.config API** - Neovim 0.11+ compatibility, no deprecation warnings
2. **Removed mason-lspconfig.nvim** - Eliminated deprecated lspconfig API dependency
3. **Removed auto-session** - Fixed "Failed to run config" error
4. **Enhanced completion** - Added mini.icons integration with source indicators
5. **Added lazydev.nvim** - Better Lua/Neovim API autocomplete
6. **Replaced Copilot with Claude Code** - User preference for Claude integration
7. **Fixed Treesitter autotag** - Handled breaking change requiring separate setup
8. **Removed neotest-gradle** - Simplified to JDTLS native test support
9. **Enabled lazy.nvim fallback** - Prevents config breakage if dev path missing
10. **Made formatting async** - Prevents editor freezing on large files
