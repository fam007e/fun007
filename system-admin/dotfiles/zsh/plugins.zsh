# plugins.zsh : zinit bootstrap, plugins, OMZ snippets, compinit

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Oh-my-posh
zinit ice depth=1; zinit light jandedobbeleer/oh-my-posh

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Tmux plugin auto-start options
export ZSH_TMUX_AUTOSTART=false
export ZSH_TMUX_AUTOCONNECT=true
export ZSH_TMUX_FIXTERM=false

# Add in snippets
zinit snippet OMZP::fzf
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found
zinit snippet OMZP::dotenv
zinit snippet OMZP::rake
zinit snippet OMZP::rbenv
zinit snippet OMZP::ruby
#zinit snippet OMZP::adb
zinit snippet OMZP::python
zinit snippet OMZP::rust
zinit snippet OMZP::rvm
zinit snippet OMZP::ssh
zinit snippet OMZP::svn
zinit snippet OMZP::thefuck
zinit snippet OMZP::tmux
zinit snippet OMZP::tldr
zinit snippet OMZP::sdk
zinit snippet OMZP::zoxide
#zinit snippet OMZP::zsh-navigation-tools
#zinit snippet OMZP::ufw

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q
