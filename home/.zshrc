# 1. Powerlevel10k Instant Prompt (Mantendo a performance no load)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 2. Plugins do Sistema
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# 3. Histórico
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory hist_ignore_dups

# 4. Powerlevel10k Theme
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme 2>/dev/null

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 5. Scripts Personalizados (zshrc.d)
source ~/.config/zshrc.d/shortcuts.zsh
source ~/.config/zshrc.d/auto-Hypr.sh

# 6. Exports e Variáveis de Ambiente
export EDITOR='nano' #
export VISUAL='code'
export HYPRLAND_INSTANCE_SIGNATURE="$(ls -1 /run/user/1000/hypr 2>/dev/null | head -n1)" #

# 7. Aliases úteis para o Fedora
alias dnfi='sudo dnf install'
alias dnfr='sudo dnf remove'
alias dnfu='sudo dnf upgrade'
alias ls='eza --icons --git-ignore --group-directories-first'
alias grep='grep --color=auto'
