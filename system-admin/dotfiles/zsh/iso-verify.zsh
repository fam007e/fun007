# iso-verify.zsh : interactive ISO integrity check (SHA-256 / BLAKE2 / GPG signature)
# Usage: iso_verify <iso-file>      (called automatically by dwn_iso)
# zsh function: no subprocess, no `exit` (uses return), non-zero return code on any failure.

# Pinned signing-key fingerprints. The GPG check only passes if the signature
# was made by this exact key, so it does not matter where the key was fetched from.
# Verify these against the projects' own sites before relying on them:
#   Arch:  https://archlinux.org/download/   (Pierre Schmitz)
#   Tails: https://tails.net/doc/about/openpgp_keys/
typeset -gr _ISOV_ARCH_FPR=3E80CA1A8B89F69CBA57D98A76A5EF9054449A5C
typeset -gr _ISOV_TAILS_FPR=A490D0F4D311A4153E2BB7CADBB802B258ACD84F

# _isov_path <dir> <input> : bare names are resolved relative to <dir>
_isov_path() {
    if [[ $2 != /* && $2 != ./* ]]; then
        print -r -- "$1/$2"
    else
        print -r -- "$2"
    fi
}

_isov_need_file() {
    [[ -f $1 ]] || { print -u2 "File $1 does not exist."; return 1 }
}

# _isov_checksum <tool> <label> <default-file> <iso>
_isov_checksum() {
    local tool=$1 label=$2 default=$3 iso=$4
    local dir=${4:h} input file
    (( $+commands[$tool] )) || { print -u2 "$tool not found in PATH."; return 1 }
    read -r "input?Enter the $label checksum file [default: $default]: "
    [[ -z $input ]] && input=$default
    file=$(_isov_path "$dir" "$input")
    _isov_need_file "$file" || return 1
    file=${file:A}
    # subshell + builtin cd: leaves the caller's directory alone and bypasses any `cd` wrapper
    ( builtin cd "$dir" && $tool -c "$file" --ignore-missing )
}

# _isov_signature <iso>
_isov_signature() {
    local iso=$1 dir=${1:h} base=${1:t} input sig expected="" status_out gpg_rc
    read -r "input?Enter the signature file [default: ${base}.sig]: "
    [[ -z $input ]] && input=${base}.sig
    sig=$(_isov_path "$dir" "$input")
    _isov_need_file "$sig" || return 1

    if [[ $base == *tails* ]]; then
        expected=$_ISOV_TAILS_FPR
        if ! gpg --list-keys "$expected" &>/dev/null; then
            print "Tails ISO detected - importing signing key..."
            [[ -f $dir/tails-signing.key ]] && gpg --import "$dir/tails-signing.key"
        fi
    elif [[ $base == *archlinux* ]]; then
        expected=$_ISOV_ARCH_FPR
    fi

    print "Verifying GPG signature..."
    # human-readable output goes to stderr (shown live); machine status lines are captured
    status_out=$(gpg --status-fd 1 --verify "$sig" "$iso")
    gpg_rc=$?
    (( gpg_rc )) && { print -u2 "gpg --verify failed (exit $gpg_rc)."; return 1 }

    if [[ -n $expected ]]; then
        if [[ $status_out == *GOODSIG*  && $status_out == *VALIDSIG*${expected}* ]]; then
            print "Signature is good AND made by pinned key ${expected}."
        else
            print -u2 "Signature is valid but NOT from the expected key ${expected}."
            return 1
        fi
    else
        print "Note: no pinned fingerprint for this ISO; only the signature itself was checked."
    fi
}

iso_verify() {
    if (( $# != 1 )); then
        print -u2 "Usage: iso_verify <iso-file>"
        return 1
    fi

    local iso=$1 base=${1:t} choice line rc=0 default=4
    local -a choices
    _isov_need_file "$iso" || return 1

    if [[ $base == *archlinux* ]]; then
        print "Detected Arch Linux ISO → Recommended: 4"
    elif [[ $base == *tails* ]]; then
        default=3
        print "Detected Tails ISO → Recommended: 3 (GPG only)"
    fi

    print "1. SHA-256   2. BLAKE2   3. GPG Signature   4. All"

    # discard keystrokes/newlines buffered while the download or gpg was running
    if [[ -t 0 ]]; then
        while read -t 0 -k 1 -s 2>/dev/null; do :; done
    fi

    read -r "line?Enter choices (space-separated) [default: $default]: "
    # keep only digits and spaces (drops stray \r etc.), then split on whitespace
    choices=( ${=${line//[^0-9 ]/}} )
    (( ${#choices} )) || choices=($default)

    for choice in "${choices[@]}"; do
        case $choice in
            1|2)
                if [[ $base == *tails* ]]; then
                    print "Tails publishes no checksum files; skipping option $choice."
                elif [[ $choice == 1 ]]; then
                    _isov_checksum sha256sum SHA-256 sha256sums.txt "$iso" || rc=1
                else
                    _isov_checksum b2sum BLAKE2 b2sums.txt "$iso" || rc=1
                fi
                ;;
            3) _isov_signature "$iso" || rc=1 ;;
            4)
                if [[ $base == *tails* ]]; then
                    _isov_signature "$iso" || rc=1
                else
                    _isov_checksum sha256sum SHA-256 sha256sums.txt "$iso" || rc=1
                    _isov_checksum b2sum BLAKE2 b2sums.txt "$iso" || rc=1
                    _isov_signature "$iso" || rc=1
                fi
                break
                ;;
            *) print -u2 "Invalid choice: '$choice'"; rc=1 ;;
        esac
    done

    if (( rc )); then
        print -u2 "Verification finished WITH ERRORS."
    else
        print "Verification completed!"
    fi
    return $rc
}

# tab-complete *.iso files
(( $+functions[compdef] )) && compdef '_files -g "*.iso"' iso_verify
