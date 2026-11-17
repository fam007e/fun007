# options.zsh : history, completion styling, shell integrations, keybindings

# History
HISTSIZE=5000
HISTFILE=$HOME/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt interactive_comments   # treat "# ..." as a comment at the prompt, like bash

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# Common Keybindings
bindkey "^[[H" beginning-of-line # Home key
bindkey "^[[F" end-of-line # End key
bindkey "^[[P" delete-char # Del key
bindkey "^[[A" history-beginning-search-backward # Up Arrow
bindkey "^[[B" history-beginning-search-forward # Down Arrow
bindkey "^[[1;5C" forward-word # Control + Right Arrow
bindkey "^[[1;5D" backward-word # Control + Left Arrow
bindkey "^H" backward-kill-word # Control + Backspace
bindkey "^[[M" kill-word # Control + Delete
bindkey "^[[7~" beginning-of-line # Home key
bindkey "^[[8~" end-of-line # End key
bindkey "^[[3~" delete-char # Del key
bindkey "^[Oc" forward-word # Control + Right Arrow
bindkey "^[Od" backward-word # Control + Left Arrow
bindkey "^[[3^" kill-word # Control + Delete

# Additional Keybindings
bindkey "^R" history-incremental-pattern-search-backward
bindkey "^S" history-incremental-pattern-search-forward
