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

# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoredups

# Using color promt
if [[ ${EUID} == 0 ]] ; then
    PS1='\[\033[48;2;221;75;57;38;2;255;255;255m\] \$ \[\033[48;2;0;135;175;38;2;221;75;57m\]\[\033[48;2;0;135;175;38;2;255;255;255m\] \h \[\033[48;2;83;85;85;38;2;0;135;175m\]\[\033[48;2;83;85;85;38;2;255;255;255m\] \w \[\033[49;38;2;83;85;85m\]\[\033[00m\] '
else
    PS1='\[\033[48;2;25;25;45;38;2;140;175;210m\] \$ \[\033[48;2;45;50;55;38;2;25;25;45m\]\[\033[48;2;45;50;55;38;2;140;175;210m\] \u@\h \[\033[48;2;60;80;100;38;2;45;50;55m\]\[\033[48;2;60;80;100;38;2;140;175;210m\] \w \[\033[49;38;2;60;80;100m\]\[\033[00m\] '
fi

# Enable color support of ls and also add handy aliases
if [ -x /opt/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

####################
#    GIT ALIAS     #
####################

alias gs='git status'           # View Git status.
alias ga='git add'              # Add a file to Git.
alias gaa='git add --all'       # Add all files to Git.
alias gc='git commit'           # Commit changes to the code.
alias gp='git push'             # Push the commits to the remote branch.
alias gl='git log --oneline'    # View the Git log.
alias gb='git checkout -b'      # Create a new Git branch and move to the new branch at the same time. 
alias gd='git diff'             # View the difference.
