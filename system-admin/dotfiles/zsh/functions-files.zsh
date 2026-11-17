# functions-files.zsh : file, archive, text and directory helpers

# egrep error escape logic
egrep() {
  grep -E --colour=auto "$@" 2>/dev/null
}

# Extracts any archive(s) (if unp isn't installed)
extract() {
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case $archive in
            *.tar.bz2) tar xvjf $archive ;;
            *.tar.gz) tar xvzf $archive ;;
            *.tar.xz) tar xvJf $archive ;;
            *.bz2) bunzip2 $archive ;;
            *.rar) unrar x $archive ;;
            *.gz) gunzip $archive ;;
            *.tar) tar xvf $archive ;;
            *.tbz2) tar xvjf $archive ;;
            *.tgz) tar xvzf $archive ;;
            *.zip) unzip $archive ;;
            *.cbz) unzip $archive ;;
            *.Z) uncompress $archive ;;
            *.7z) 7z x $archive ;;
            *.xz) unxz $archive ;;
            *) printf "don't know how to extract '%s'...\n" "$archive" ;;
            esac
        else
            printf "'%s' is not a valid file!\n" "$archive"
        fi
    done
}

# Automated encryption and decryption on file/folders
mkcryptgz() {
    if [[ -d "$1" ]]; then
        tarball="${1}.tar.gz"
        tar -czf "$tarball" "$1" && gpg --output "${tarball}.gpg" --symmetric "$tarball" && rm "$tarball"
        if [[ $? -eq 0 ]]; then
            printf "Directory '%s' compressed, encrypted, and original archive removed.\n" "$1"
        else
            printf "Error during compression or encryption.\n"
        fi
    else
        printf "'%s' is not a valid directory!\n" "$1"
    fi
}

ungpgextract() {
    if [[ -f "$1" ]]; then
        output_file="${1%.gpg}"
        gpg --output "$output_file" --decrypt "$1"

        if [[ $? -eq 0 ]]; then
            extract "$output_file"
            if [[ $? -eq 0 ]]; then
                rm "$output_file"
                printf "Decrypted, extracted, and removed: %s\n" "$output_file"
            else
                printf "Extraction failed.\n"
            fi
        else
            printf "Decryption failed.\n"
        fi
    else
        printf "'%s' is not a valid file!\n" "$1"
    fi
}

# Searches for text in all files in the current folder
ftext() {
    # -i case-insensitive
    # -I ignore binary files
    # -H causes filename to be printed
    # -r recursive search
    # -n causes line number to be printed
    # optional: -F treat search term as a literal, not a regular expression
    # optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
    grep -iIHrn --color=always "$1" . | less -r
}

# QP var chooser
filter_papers() {
  local file=$1
  local keep_qp=$2

  awk '!/"$keep_qp"'[1-9]/ "$file" > filtered_results.dat
}

# Copy file with a progress bar
cpp() {
    set -e
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
        awk '{
    count += $NF
    if (count % 10 == 0) {
        percent = count / total_size * 100
        printf "%3d%% [", percent
        for (i=0;i<=percent;i++)
            printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
                printf "]\r"
            }
        }
    END { printf "\n" }' total_size="$(stat -c '%s' "${1}")" count=0
}

# Copy and go to the directory
cpg() {
    if [ -d "$2" ]; then
        cp "$1" "$2" && cd "$2"
    else
        cp "$1" "$2"
    fi
}

# Move and go to the directory
mvg() {
    if [ -d "$2" ]; then
        mv "$1" "$2" && cd "$2"
    else
        mv "$1" "$2"
    fi
}

# Create and go to the directory
mkdirg() {
    mkdir -p "$1"
    cd "$1"
}

# Goes up a specified number of directories  (i.e. up 4)
up() {
    local d=""
    limit=$1
    for ((i = 1; i <= limit; i++)); do
        d=$d/..
    done
    d=$(printf "%s" "$d" | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd $d
}

# Returns the last 2 fields of the working directory
pwdtail() {
    pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Trim leading and trailing spaces (for scripts)
trim() {
    local var=$*
    var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
    printf "%s" "$var"
}
