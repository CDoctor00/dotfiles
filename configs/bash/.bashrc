######################################################################
#
#
#           ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗
#           ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔════╝
#           ██████╔╝███████║███████╗███████║██████╔╝██║     
#           ██╔══██╗██╔══██║╚════██║██╔══██║██╔══██╗██║     
#           ██████╔╝██║  ██║███████║██║  ██║██║  ██║╚██████╗
#           ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
#
#
######################################################################


# If not running interactively, don't do anything
[[ $- != *i* ]] && return


# ─────────────────────────────────────────
#  XDG BASE DIRECTORY SPECIFICATION
# ─────────────────────────────────────────
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:=$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:=$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:=$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:=$HOME/.local/state}"


# ─────────────────────────────────────────
#  HISTORY
# ─────────────────────────────────────────
# Root user: separate history file to avoid permission issues
if [[ ${EUID} == 0 ]] ; then
    export HISTFILE="/root/.bash_history"
    [[ ! -d "/root" ]] && mkdir -p "/root"
else
    export HISTFILE="$XDG_DATA_HOME/bash/history"
    [[ ! -d "$XDG_DATA_HOME/bash" ]] && mkdir -p "$XDG_DATA_HOME/bash"
fi

export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups   # don't put duplicate lines

shopt -s histappend
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'


# ─────────────────────────────────────────
#  PROMPT — Nord Palette
# ─────────────────────────────────────────
# Colors from docs/theming.md:
# - Background: #2E3440 (46, 52, 64)
# - Surface: #3B4252 (59, 66, 82)
# - Overlay: #4C566A (76, 86, 106)
# - Text: #D8DEE9 (216, 222, 233)
# - Frost 2 (highlight): #88C0D0 (136, 192, 208)
# - Frost 3: #81A1C1 (129, 161, 193)
# - Aurora Red: #BF616A (191, 97, 106)

# ROOT prompt: red accent for root user
if [[ ${EUID} == 0 ]] ; then
    PS1='\[\033[48;2;191;97;106;38;2;255;255;255m\] \$ \[\033[48;2;46;52;64;38;2;191;97;106m\]\[\033[48;2;46;52;64;38;2;216;222;233m\] \h \[\033[48;2;76;86;106;38;2;46;52;64m\]\[\033[48;2;76;86;106;38;2;216;222;233m\] \w \[\033[49;38;2;76;86;106m\]\[\033[00m\] '
# USER prompt: blue accent with high-contrast username
else
    PS1='\[\033[48;2;129;161;193;38;2;255;255;255m\] \$ \[\033[48;2;46;52;64;38;2;129;161;193m\]\[\033[48;2;46;52;64;38;2;136;192;208m\] \u@\h \[\033[48;2;76;86;106;38;2;46;52;64m\]\[\033[48;2;76;86;106;38;2;216;222;233m\] \w \[\033[49;38;2;76;86;106m\]\[\033[00m\] '
fi


# ─────────────────────────────────────────
#  AUTOCOMPLETE
# ─────────────────────────────────────────
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'


# ─────────────────────────────────────────
#  COLORS
# ─────────────────────────────────────────
if [ -x /opt/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


# ─────────────────────────────────────────
#  ALIAS
# ─────────────────────────────────────────
alias ls='eza --icons=always --group-directories-first'
alias ll='eza -la --icons=always --group-directories-first --git --header'
alias lsd='eza -D --icons=always'
alias tree='eza --tree --icons=always --level=2'

alias cat='bat'
alias grep='rg'
alias find='fd'

alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias fix-dropbox="sudo chown -R $USER:$USER ~/Dropbox ~/.dropbox && sudo chmod -R u+rwX ~/Dropbox ~/.dropbox"


# ─────────────────────────────────────────
#  GIT ALIAS
# ─────────────────────────────────────────
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gb='git checkout -b'
alias gd='git diff'


# # ─────────────────────────────────────────
# #  FZF
# # ─────────────────────────────────────────
# source /usr/share/fzf/key-bindings.bash
# source /usr/share/fzf/completion.bash

# export FZF_DEFAULT_OPTS="
#   --color=bg+:#3B4252,bg:#2E3440,spinner:#88C0D0,hl:#81A1C1
#   --color=fg:#D8DEE9,header:#81A1C1,info:#88C0D0,pointer:#88C0D0
#   --color=marker:#88C0D0,fg+:#ECEFF4,prompt:#81A1C1,hl+:#81A1C1
#   --border rounded --height 40%"
