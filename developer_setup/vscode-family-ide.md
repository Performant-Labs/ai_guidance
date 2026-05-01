# IDE Editors in the VSCode Family

Configuration recipes for VSCode-family editors: VS Code, Cursor, Windsurf, Antigravity, and any other fork that reads the same `settings.json` / `keybindings.json` files.

Settings files live at:

| OS | Path |
|---|---|
| macOS | `~/Library/Application Support/<EditorName>/User/settings.json` |
| Linux | `~/.config/<EditorName>/User/settings.json` |
| Windows | `%APPDATA%\<EditorName>\User\settings.json` |

Replace `<EditorName>` with `Code`, `Cursor`, `Windsurf`, `Antigravity`, etc.

---

## Markdown Preview by Default

Open `.md` files as a rendered preview instead of raw source. Useful when browsing documentation, planning docs, or audit reports — you see the formatted output immediately.

### settings.json

```jsonc
{
    "workbench.editorAssociations": {
        "*.md": "vscode.markdown.preview.editor"
    }
}
```

> **Tip:** To temporarily edit the raw markdown, right-click the tab → "Reopen Editor With…" → "Text Editor". Or use the pencil icon in the preview toolbar.

---

## Zen Mode Without Full-Screen

Zen Mode hides the sidebar, panel, tabs, and activity bar — maximizing the editor area for focused reading or writing. By default it also goes full-screen, which is disorienting on macOS (creates a new desktop space). Disable the full-screen behavior:

### settings.json

```jsonc
{
    "zenMode.fullScreen": false
}
```

### keybindings.json

Map `Cmd+Shift+Z` (or any preferred combo) to toggle Zen Mode:

```jsonc
[
    {
        "key": "cmd+shift+z",
        "command": "workbench.action.toggleZenMode"
    }
]
```

**Usage:** `Cmd+Shift+Z` to enter. `Escape Escape` (press Escape twice) to exit.

---

## Combined Example (Antigravity)

A complete `settings.json` merge showing both features alongside typical existing settings:

```jsonc
{
    // ... existing settings ...
    "workbench.editorAssociations": {
        "*.html": "default",
        "*.md": "vscode.markdown.preview.editor"   // ← added
    },
    "zenMode.fullScreen": false                      // ← added
}
```

And a `keybindings.json`:

```jsonc
[
    {
        "key": "cmd+shift+z",
        "command": "workbench.action.toggleZenMode"
    }
]
```

### Merge instructions

If `settings.json` already exists:

1. Check existing content: `cat "<path>/settings.json"`
2. If `workbench.editorAssociations` already has entries, add `"*.md": "vscode.markdown.preview.editor"` inside the existing block — don't replace it.
3. Add `"zenMode.fullScreen": false` at the top level.
4. If `keybindings.json` already exists, append the new binding into the existing array.

### Quick-apply (macOS, Antigravity)

```bash
# Check existing settings first
cat "$HOME/Library/Application Support/Antigravity/User/settings.json"

# If the file doesn't exist, create it:
cat > "$HOME/Library/Application Support/Antigravity/User/settings.json" << 'SETTINGS'
{
    "workbench.editorAssociations": {
        "*.md": "vscode.markdown.preview.editor"
    },
    "zenMode.fullScreen": false
}
SETTINGS

# Keybindings
cat > "$HOME/Library/Application Support/Antigravity/User/keybindings.json" << 'KEYS'
[
    {
        "key": "cmd+shift+z",
        "command": "workbench.action.toggleZenMode"
    }
]
KEYS
```

> **Important:** If the settings file already exists, merge the keys into the existing JSON rather than overwriting. The heredoc above is for fresh installs only.
