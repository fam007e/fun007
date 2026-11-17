# aliases.zsh : all aliases (functions live in functions-*.zsh)

# --- Core / shell ---
alias reboot='sudo reboot +0'
alias shutdown='sudo shutdown +0'
alias h="cat $HOME/.zsh_history | grep "
alias ezrc='nano $HOME/.zshrc'
alias hlp='cat "$ZSH_ALIASES_DOC"'
alias vi='nvim'
alias svi='sudoedit'
alias vis='nvim "+set si"'
alias vim='nvim'
alias c='clear'
alias x='exit'
alias da='date "+%Y-%m-%d %A %T %Z"'
alias checkcommand="type -t"

# --- File operations ---
alias cp='cp -iv --reflink=auto'
alias rcp='rsync -v --progress'
alias rmv='rsync -v --progress --remove-source-files'
alias mv='mv -iv'
alias less='less -R'
alias ln='ln -v'
alias chmod='chmod -c'
alias chown='chown -c'
alias mkdir='mkdir -v'
alias grep='grep --colour=auto'
# alias egrep='grep -E --colour=auto'
alias rm='rm -f'
alias rmd='rm -rf'
alias ls='eza'
alias ll='eza -alh'
alias tree='eza --tree'
alias treed='tree -CAFd'
alias multitail='multitail --no-repeat -c'

# --- Clipboard ---
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias clickpaste='sleep 3; xdotool type "$(xclip -o -selection clipboard)"'

# --- Arch / package management ---
alias clear-pacman-cache='sudo pacman -Sc'
alias clear-cache='sudo find /var/cache/pacman/pkg/ -maxdepth 1 -type d -name "download-*" -exec rm -r {} + && yay -Sc'
alias genSRCINFO='makepkg --printsrcinfo > .SRCINFO'
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"
alias freshclam='sudo freshclam'

# --- Misc tools ---
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && printf terminal || printf error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias kc='khal calendar'
alias ff='fastfetch'
alias sha1='openssl sha1'

# --- Terminals ---
alias gtc="ghostty +new-window --working-directory=$PWD || ghostty --working-directory=$PWD"
alias gtt="ghostty +new-window || ghostty"
alias ala="alacritty msg create-window || alacritty"

# --- Directory navigation ---
alias home='cd $HOME'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# --- chmod shortcuts ---
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# --- Conditional replacements ---
if command -v bat > /dev/null; then
     alias cat="bat"
elif command -v batcat > /dev/null; then
     alias cat="batcat"
fi

if command -v colordiff > /dev/null 2>&1; then
    alias diff="colordiff -Nuar"
else
    alias diff="diff -Nuar"
fi

# --- Archives ---
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'
alias mk7z='7z a -t7z'
alias mkzip='zip -r'

# --- Network ---
alias ping='ping -c 10'
alias openports='netstat -nape --inet'
alias whatismyip="whatsmyip"
# Show all established connections and their resolved names
alias show_connections='sudo netstat -tupn | grep "ESTABLISHED" | awk '\''{print $5}'\'' | cut -d: -f1 | sort | uniq | xargs -I {} sh -c '\''printf "%s: " "{}"; nslookup {}'\'' | grep "name ="'
# Show the external NAT'ed IP
alias external_ip='IP=$(curl -s https://api.ipify.org) && printf "This is your External IP address %s.\n" "$IP"'

# --- System info ---
alias last_reboot='FQDN=$(uname -n); hostname=$(printf "%s" "$FQDN" | cut -d. -f1); last_reboot=$(date -d @$(( $(date +%s) - $(awk '\''{print int($1)}'\'' /proc/uptime) ))); printf "The %s system was last rebooted on %s.\n" "$hostname" "$last_reboot"'
alias opwttr='"$OPWTTR_SCRIPT"'
alias random_color_script='COLOR_SCRIPT_REPO=https://api.github.com/repos/stark/Color-Scripts/contents/color-scripts; wget -q -O - $(curl -s $COLOR_SCRIPT_REPO | jq ".[] | \"\(.path) \(.download_url)\"" -r | shuf -n1 | cut -d " " -f2) | bash'
alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs sudo tail -f"

# --- Process / file search ---
alias p="ps aux | grep "
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"
alias f="find . | grep "
alias countfiles="for t in files links directories; do printf \"%s %s\n\" \"\$(find . -type \${t:0:1} | wc -l)\" \"\$t\"; done 2> /dev/null"

# --- Disk space ---
alias diskspace="du -S | sort -n -r |more"
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias mountedinfo='df -hT'
