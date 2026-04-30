# IDE Settings Conventions (VS Code-Based Editors)

This document covers configuration standards for VS Code-based editors used in this ecosystem. **AntiGravity** is the primary editor, but these conventions apply to any fork of VS Code (Cursor, Windsurf, etc.) because they share the same settings schema and config directory structure.

## Config File Locations

| Editor | Settings Path |
| :--- | :--- |
| **AntiGravity** | `~/Library/Application Support/Antigravity/User/` |
| VS Code | `~/Library/Application Support/Code/User/` |
| Windsurf | `~/Library/Application Support/Windsurf/User/` |

Each `User/` directory contains:
- `settings.json` — editor behavior, theme, associations
- `keybindings.json` — custom keyboard shortcuts

## Markdown Files: Default to Preview Mode

Markdown files must open directly in rendered preview mode, not as raw source. This prevents agents and developers from reading unrendered markup and mistaking formatting syntax for content.

Add this to `settings.json`:

```json
"workbench.editorAssociations": {
    "*.md": "vscode.markdown.preview.editor"
}
```

This association is engine-level — it applies in AntiGravity, VS Code, and any VS Code fork without modification because the `vscode.markdown.preview.editor` command is built into the VS Code base.

## Zen Mode Shortcut

Zen Mode removes all UI chrome (sidebars, tabs, status bar) for distraction-free reading or writing. Bind it to `Cmd+Shift+Z` in `keybindings.json`:

```json
[
    {
        "key": "cmd+shift+z",
        "command": "workbench.action.toggleZenMode"
    }
]
```

> [!NOTE]
> The combination of Zen Mode + markdown preview association means opening any `.md` file and pressing `Cmd+Shift+Z` produces a clean, full-screen rendered document view — no raw syntax visible.

## Baseline `settings.json` for AntiGravity

```json
{
    "workbench.colorTheme": "Monokai",
    "extensions.ignoreRecommendations": true,
    "window.confirmSaveUntitledWorkspace": false,
    "explorer.confirmDelete": false,
    "files.associations": {
        "*.inc": "php"
    },
    "workbench.editorAssociations": {
        "*.md": "vscode.markdown.preview.editor"
    }
}
```

## Key Rules for AI Agents

- **Do NOT edit source markdown via the editor UI** — the editor will open it in preview, not edit mode. Use file-system tools (e.g., Claude Code's `Edit`/`Write` tools) to modify `.md` files directly.
- **Do NOT assume VS Code settings paths apply to AntiGravity.** Always use the AntiGravity-specific path when reading or writing config files.
- **Always read before writing.** Both `settings.json` and `keybindings.json` may contain existing entries. Merge additions rather than overwriting.
