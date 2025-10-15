# DevRun Variables Documentation

DevRun supports VSCode-compatible variable substitution in run configurations. Variables are resolved dynamically when tasks execute, making configurations portable across different machines and environments.

## Syntax

Variables use the syntax `${variableName}` and can be used in any string field of your configuration.

```json
{
  "artifact": "${workspaceFolder}/build/libs/${projectName}.war",
  "tomcatHome": "${env:TOMCAT_HOME}",
  "cwd": "${workspaceFolder}"
}
```

## Available Variables

### Path Variables

These variables provide information about paths and directories.

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `${workspaceFolder}` | Current workspace directory (cwd) | `/Users/username/projects/myapp` |
| `${workspaceFolderBasename}` | Workspace folder name | `myapp` |
| `${userHome}` | User home directory | `/Users/username` |
| `${file}` | Currently open file (absolute path) | `/Users/username/projects/myapp/src/Main.java` |
| `${fileBasename}` | File name with extension | `Main.java` |
| `${fileBasenameNoExtension}` | File name without extension | `Main` |
| `${fileDirname}` | Directory containing current file | `/Users/username/projects/myapp/src` |
| `${fileExtname}` | File extension | `java` |
| `${relativeFile}` | File path relative to workspace | `src/Main.java` |
| `${relativeFileDirname}` | File directory relative to workspace | `src` |

**Note**: File variables are only available when a file is open in the editor. If no file is open, these variables resolve to empty strings or show warnings.

### Project Variables

These variables are derived from the project structure.

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `${projectName}` | Project name (from workspace folder name) | `myapp` |
| `${buildDir}` | Build output directory | `build` |
| `${targetDir}` | Target directory (Maven/Gradle) | `build` |

### Date/Time Variables

These variables provide dynamic date and time values.

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `${date}` | Current date (YYYY-MM-DD format) | `2025-10-15` |
| `${time}` | Current time (HH:MM:SS format) | `14:30:45` |
| `${timestamp}` | Unix timestamp (seconds since epoch) | `1697385045` |

### Environment Variables

Access any environment variable using `${env:VARIABLE_NAME}` syntax.

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `${env:JAVA_HOME}` | Java installation directory | `/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home` |
| `${env:TOMCAT_HOME}` | Tomcat installation directory | `/usr/local/tomcat9` |
| `${env:PATH}` | System PATH variable | `/usr/local/bin:/usr/bin:/bin` |
| `${env:USER}` | Current user name | `username` |

**Note**: If an environment variable is not set, the variable resolves to an empty string and a warning is displayed.

### Config References

Reference other fields in the same configuration using `${config:fieldName}` syntax.

| Variable | Description | Example |
|----------|-------------|---------|
| `${config:httpPort}` | Reference the `httpPort` field | If `httpPort: 8080`, resolves to `8080` |
| `${config:contextPath}` | Reference the `contextPath` field | If `contextPath: "myapp"`, resolves to `myapp` |

**Note**: Config references allow you to avoid duplicating values across different fields in your configuration.

### Special Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `${random}` | Random 6-digit number | `482561` |

Useful for generating random port numbers or unique identifiers.

## Usage Examples

### Example 1: Portable Artifact Path

```json
{
  "type": "tomcat",
  "name": "Deploy My App",
  "artifact": "${workspaceFolder}/build/libs/${projectName}.war",
  "tomcatHome": "${userHome}/tomcat9"
}
```

This configuration works across different machines without modification.

### Example 2: Environment-Based Configuration

```json
{
  "type": "gradle",
  "name": "Build with Custom Java",
  "command": "./gradlew bootRun",
  "env": {
    "JAVA_HOME": "${env:JAVA_HOME}",
    "GRADLE_HOME": "${env:GRADLE_HOME}"
  }
}
```

Automatically uses the Java and Gradle installations from environment variables.

### Example 3: Dynamic Log Files

```json
{
  "type": "command",
  "name": "Run with Logging",
  "command": "./run.sh > ${workspaceFolder}/logs/app-${date}.log 2>&1",
  "cwd": "${workspaceFolder}"
}
```

Creates a new log file each day with the current date in the filename.

### Example 4: Config Field References

```json
{
  "type": "tomcat",
  "name": "Deploy with Custom Port",
  "artifact": "${workspaceFolder}/build/libs/app.war",
  "tomcatHome": "${userHome}/tomcat9",
  "httpPort": 8080,
  "debugPort": 5005,
  "env": {
    "SERVER_URL": "http://localhost:${config:httpPort}",
    "DEBUG_URL": "http://localhost:${config:debugPort}"
  }
}
```

Avoids duplicating port numbers in environment variables.

### Example 5: Cross-Platform User Directories

```json
{
  "type": "gradle",
  "name": "Build to User Dir",
  "command": "./gradlew build -Doutput.dir=${userHome}/builds",
  "cwd": "${workspaceFolder}"
}
```

Works on any operating system, automatically resolving to the correct user directory.

### Example 6: Exploded WAR with Date Stamping

```json
{
  "type": "tomcat",
  "name": "Deploy Exploded WAR",
  "artifact": "${workspaceFolder}/build/exploded/${projectName}-${date}",
  "tomcatHome": "${env:TOMCAT_HOME}",
  "cleanDeploy": true
}
```

Deploys exploded WAR with date-stamped directory name.

## Command to View Variables

Run `:DevRunVariables` to see all available variables and their current values in your environment.

## Backward Compatibility

- `${workspacePath}` - Deprecated, use `${workspaceFolder}` instead. Still works but shows a warning.

## Variable Resolution Order

Variables are resolved in this order:
1. Path variables (`${workspaceFolder}`, `${userHome}`, etc.)
2. File variables (`${file}`, `${fileBasename}`, etc.)
3. Project variables (`${projectName}`, `${buildDir}`, etc.)
4. Date/time variables (`${date}`, `${time}`, `${timestamp}`)
5. Random variable (`${random}`)
6. Environment variables (`${env:NAME}`)
7. Config references (`${config:field}`)
8. Deprecated variables (`${workspacePath}`)

## Best Practices

1. **Use `${workspaceFolder}` for portability**: Always prefix project paths with `${workspaceFolder}` to make configs work across different machines.

2. **Use `${env:VAR}` for system dependencies**: Reference system-specific paths (like `JAVA_HOME`, `TOMCAT_HOME`) via environment variables.

3. **Use `${userHome}` for user-specific paths**: For directories in the user's home directory.

4. **Use `${config:field}` to avoid duplication**: Reference other config fields instead of repeating values.

5. **Use date variables for logs**: Rotate log files automatically using `${date}` or `${timestamp}`.

## Troubleshooting

- **Variable not resolving**: Check the variable name is spelled correctly and uses correct casing.
- **Environment variable empty**: Ensure the environment variable is set in your shell before starting Neovim.
- **File variables not working**: These require a file to be open in the editor. Open a file or use workspace variables instead.
- **Config reference not found**: Ensure the referenced field exists in the same configuration object.

## VSCode Compatibility

DevRun's variable system is designed to be compatible with VSCode's `launch.json` and `tasks.json` variable substitution, making it easy to migrate configurations or use similar syntax across different tools.

Supported VSCode variables:
- ✅ `${workspaceFolder}`
- ✅ `${workspaceFolderBasename}`
- ✅ `${file}`
- ✅ `${fileBasename}`
- ✅ `${fileBasenameNoExtension}`
- ✅ `${fileDirname}`
- ✅ `${fileExtname}`
- ✅ `${relativeFile}`
- ✅ `${relativeFileDirname}`
- ✅ `${userHome}`
- ✅ `${env:VARIABLE}`

Additional DevRun-specific variables:
- `${projectName}`
- `${buildDir}`
- `${targetDir}`
- `${date}`
- `${time}`
- `${timestamp}`
- `${config:field}`
- `${random}`
