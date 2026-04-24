# ZSH Two-Line Prompt Configuration

This is a custom two-line prompt configuration for ZSH. It intelligently displays:
- **Exit code status** (only appears if the last command failed)
- **Current working directory**
- **Git branch and action state** (via `vcs_info`)
- **Active Python Virtual Environment**
- **SSH host information** (only displays when connected via SSH)

## Installation

Run the following block in your terminal. It will safely append the configuration to the end of your `~/.zshrc` and source it immediately.

```zsh
cat >> ~/.zshrc <<'EOF'

# Two-line prompt with Git branch
autoload -Uz add-zsh-hook vcs_info
setopt prompt_subst
zstyle ":vcs_info:*" enable git
zstyle ":vcs_info:git:*" formats " %F{yellow}git:%b%f"
zstyle ":vcs_info:git:*" actionformats " %F{yellow}git:%b|%a%f"

_prompt_update_context() {
  vcs_info
  if [[ -n "$VIRTUAL_ENV" ]]; then
    _prompt_env=" %F{magenta}venv:${VIRTUAL_ENV:t}%f"
  else
    _prompt_env=""
  fi
  if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" ]]; then
    _prompt_host=" %F{green}%n@%m%f"
  else
    _prompt_host=""
  fi
}
add-zsh-hook -d precmd _prompt_update_context 2>/dev/null
add-zsh-hook precmd _prompt_update_context

PROMPT="%(?..%F{red}exit:%?%f )%F{cyan}%2~%f\${vcs_info_msg_0_}\${_prompt_env}\${_prompt_host}
%# "
EOF

source ~/.zshrc
```
