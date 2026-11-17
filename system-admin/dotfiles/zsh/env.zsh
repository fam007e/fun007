# env.zsh : environment variables and PATH

typeset -U path PATH

# --- Personal locations: defaults, override any of them in local.zsh ---
: ${FUN007_DIR:=$HOME/Github/fun007}                   # repo with passwd_gen.py + oh-my-posh theme
: ${ISO_DIR:=$HOME/Downloads/ISO}                      # dwn_iso download dir
: ${FASTFETCH_SRC:=$HOME/fastfetch}                    # fastfetch git checkout (ff-upd)
: ${OPWTTR_SCRIPT:=$HOME/DWM/scripts/OpWeatherinfo}    # opwttr alias target
: ${ZSH_ALIASES_DOC:=$HOME/zshrc_aliases.md}           # hlp alias target

export IDAPYTHON_VENV_EXECUTABLE="$HOME/.idapro/venv/bin/python"
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
# highest build-tools version, zsh-native (no sort/tail forks); (N) = no error if SDK absent
typeset -a _bt; _bt=( $ANDROID_HOME/build-tools/*(N/) )
export ANDROID_BUILD_TOOLS=${${(On)_bt}[1]}
unset _bt
export JAVA_TOOL_OPTIONS="--enable-native-access=ALL-UNNAMED"
(( $+commands[go] )) && export GOBIN=$(go env GOPATH)/bin
export GPG_TTY=$TTY

# Add user-specific bins to path array (ensures precedence and uniqueness)
path=(
  "$HOME/.local/bin"
  "$HOME/.wakatime"
  "$GOBIN"
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_BUILD_TOOLS"
  "/opt/android-sdk/cmdline-tools/latest/bin"
  "$path[@]"
)

# Add .cargo/bin only if it exists
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" "$path[@]")

# Drop empty entries (an empty PATH element means "current directory")
path=(${path:#})

export PATH

export EDITOR=nvim
export VISUAL=nvim

# MihonQT Tracker API Client IDs
export ANILIST_CLIENT_ID="57104"
export MAL_CLIENT_ID="926a6ef9fccfc893c8870ff8a667681d"

