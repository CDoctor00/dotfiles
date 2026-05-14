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
#  HISTORY
# ─────────────────────────────────────────
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups   # don't put duplicate lines
shopt -s histappend
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'


# ─────────────────────────────────────────
#  PROMPT 
# ─────────────────────────────────────────
if [[ ${EUID} == 0 ]] ; then
    PS1='\[\033[48;2;221;75;57;38;2;255;255;255m\] \$ \[\033[48;2;0;135;175;38;2;221;75;57m\]\[\033[48;2;0;135;175;38;2;255;255;255m\] \h \[\033[48;2;83;85;85;38;2;0;135;175m\]\[\033[48;2;83;85;85;38;2;255;255;255m\] \w \[\033[49;38;2;83;85;85m\]\[\033[00m\] '
else
    PS1='\[\033[48;2;25;25;45;38;2;140;175;210m\] \$ \[\033[48;2;45;50;55;38;2;25;25;45m\]\[\033[48;2;45;50;55;38;2;140;175;210m\] \u@\h \[\033[48;2;60;80;100;38;2;45;50;55m\]\[\033[48;2;60;80;100;38;2;140;175;210m\] \w \[\033[49;38;2;60;80;100m\]\[\033[00m\] '
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

