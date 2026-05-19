# SimpL VS Code Extension

Syntax highlighting for `.spl` files.

## Install

Copy this directory to your VS Code extensions folder:

**Windows (PowerShell):**
```powershell
Copy-Item -Recurse editors/vscode $env:USERPROFILE\.vscode\extensions\simpl
```

**macOS / Linux:**
```bash
cp -r editors/vscode ~/.vscode/extensions/simpl
```

Then reload VS Code (`Ctrl+Shift+P` → `Developer: Reload Window`).

## Features

- Syntax highlighting for keywords (`define`, `lambda`, `if`, `quote`, `begin`, `set!`)
- Built-in functions and operators
- Strings, numbers, booleans (`#t`, `#f`), `nil`
- Line comments (`; ...`)
- Bracket matching and auto-closing for `()` and `""`
