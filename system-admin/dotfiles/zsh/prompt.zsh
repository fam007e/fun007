# prompt.zsh : startup banner, prompt, conda, installer-added lines. Load LAST.

if [ -f /usr/bin/fastfetch ]; then
    fastfetch
fi
# oh-my-posh theme: OMP_CONFIG wins, else the one in the fun007 repo, else oh-my-posh's default theme
if (( $+commands[oh-my-posh] )); then
    _omp_cfg="${OMP_CONFIG:-${FUN007_DIR:-$HOME/Github/fun007}/system-admin/dotfiles/illusi0n_mod.omp.json}"
    if [[ -r $_omp_cfg ]]; then
        eval "$(oh-my-posh init zsh --config "$_omp_cfg")"
    else
        print -u2 "prompt: oh-my-posh theme not found: $_omp_cfg (set FUN007_DIR or OMP_CONFIG in local.zsh)"
        eval "$(oh-my-posh init zsh)"
    fi
    unset _omp_cfg
else
    print -u2 "prompt: oh-my-posh not found in PATH"
fi
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"
