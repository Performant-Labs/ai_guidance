import os
import subprocess

from rich.console import Console
from rich.panel import Panel

console = Console()

def get_subtree_prefix():
    try:
        result = subprocess.run(
            ["git", "log", "--grep=git-subtree-dir:", "-1", "--format=%B"],
            capture_output=True, text=True, check=True
        )
        for line in result.stdout.splitlines():
            if line.startswith("git-subtree-dir:"):
                return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return "docs/ai_guidance" if os.path.isdir("docs/ai_guidance") else "docs"

PREFIX = get_subtree_prefix()
REMOTE = "git@github.com:Performant-Labs/ai_guidance.git"
BRANCH = "main"

def load_config():
    """Load configuration from guidance-align.env if it exists."""
    env_path = os.path.join(os.path.dirname(__file__), "guidance-align.env")
    if not os.path.exists(env_path):
        return
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                try:
                    key, val = line.split('=', 1)
                    val = val.strip(' \'"')
                    # Expand $HOME natively
                    os.environ[key] = os.path.expandvars(val)
                except ValueError:
                    pass

def run(cmd, live_output=False):
    if live_output:
        result = subprocess.run(cmd, shell=True)
    else:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result


def ask_gemini(prompt, model=None):
    # Model priority: CLI arg > GEMINI_MODEL env var > gemini default
    model = model or os.environ.get("GEMINI_MODEL", "gemini-3-pro-preview")
    cmd = ["gemini", "-p", prompt]
    if model:
        cmd += ["-m", model]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0 and result.stdout.strip():
        return result.stdout.strip()
    if "Not logged in" in result.stdout or "authentication" in result.stdout.lower():
        console.print("\n[yellow]⚠ Gemini CLI is not logged in. Run [bold]gemini login[/bold] to enable AI advice.[/yellow]")
    return None

def run_gemini_agent(prompt, model=None):
    model = model or os.environ.get("GEMINI_MODEL", "gemini-3-pro-preview")
    cmd = ["gemini", "--approval-mode", "yolo", "-p", prompt]
    if model:
        cmd += ["-m", model]
    subprocess.run(cmd)

def run_preflight_checks():
    import shutil
    import sys
    if not shutil.which("gemini"):
        console.print("\n[bold red]🚨 Error: 'gemini' CLI is not installed.[/bold red]")
        console.print("[yellow]Setup Instructions: brew install geminicli && gemini login[/yellow]\n")
        sys.exit(1)

def print_header(operation, model=None):
    import shutil
    
    # Get gemini version
    version_str = "Unknown"
    if shutil.which("gemini"):
        res = subprocess.run(["gemini", "--version"], capture_output=True, text=True)
        if res.returncode == 0:
            version_str = res.stdout.strip()

    model = model or os.environ.get("GEMINI_MODEL", "gemini-3-pro-preview")

    console.print(f"\n[bold cyan]◆ ai:{operation}[/bold cyan]")
    console.print(f"  [dim]Subtree :[/dim] {PREFIX}")
    console.print(f"  [dim]Remote  :[/dim] {REMOTE}")
    console.print(f"  [dim]Branch  :[/dim] {BRANCH}")
    console.print(f"  [dim]Engine  :[/dim] [green]{version_str}[/green]")
    console.print(f"  [dim]Model   :[/dim] [yellow]{model}[/yellow]")
    console.print()


def check_dirty_tree(operation, model=None):
    """Returns True if tree is clean, False (and prints advice) if dirty."""
    dirty = (
        run("git diff --quiet").returncode != 0 or
        run("git diff --cached --quiet").returncode != 0
    )
    if not dirty:
        return True

    status = run("git status --short").stdout.strip()
    console.print("[bold red]✖ Cannot proceed — working tree is dirty.[/bold red]")
    console.print("  Resolve these files first:\n")
    for line in status.splitlines():
        console.print(f"    [yellow]{line}[/yellow]")

    console.print("\n[dim]Asking Gemini for advice…[/dim]")
    advice = ask_gemini(
        f"I'm trying to {operation} a remote git subtree but my working tree is dirty. "
        f"Here is the output of git status --short:\n\n{status}\n\n"
        f"Give me bullet points (not prose) with specific git commands to resolve this so I can proceed.",
        model=model,
    )
    if advice:
        console.print(Panel(advice, title="[bold]Gemini's advice[/bold]", border_style="yellow"))

    console.print()
    return False


def parse_args(description):
    import argparse
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--model", default=None, help="Gemini model to use (e.g. gemini-3-pro-preview, gemini-2.5-flash)")
    return parser.parse_args()
