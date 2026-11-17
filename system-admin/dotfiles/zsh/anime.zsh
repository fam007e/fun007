# anime.zsh : FZF-based anime torrent manager. Run: anime
#
# Return-code convention for the interface helpers:
#   0 = exit the tool entirely, non-zero = go back to main menu.
#
# NOTE ON qbittorrent-nox: the CLI flags below (--confirm-legal-notice
# --skip-dialog=true --save-path=...) are verified against the GUI `qbittorrent`
# binary. If qbittorrent-nox doesn't pick up torrents, compare
# `qbittorrent-nox --help`.

: ${ANIME_DOWNLOAD_DIR:=$HOME/Videos}
: ${ANIME_CACHE_DIR:=/tmp/anime_torrents}
: ${ANIME_HISTORY_FILE:=$HOME/.cache/anime_manager_history}
: ${ANIME_RSS_CACHE_TTL:=60}  # seconds

# URL-encode a string for safe use in a query parameter. `${term// /+}` alone
# only handles spaces — anything with &, :, ', !, or non-ASCII characters
# (common in anime titles) needs real percent-encoding or it corrupts the
# query string (an unescaped & truncates it outright).
_url_encode() {
    local input="$1"
    if command -v python3 &> /dev/null; then
        python3 -c "import urllib.parse,sys; print(urllib.parse.quote_plus(sys.argv[1]))" "$input"
    elif command -v perl &> /dev/null; then
        perl -MURI::Escape -e 'my $s = uri_escape($ARGV[0]); $s =~ s/%20/+/g; print $s;' "$input"
    else
        # Crude fallback if neither is available: spaces only.
        echo "${input// /+}"
    fi
}

# HTTP request helper function. Sends a browser User-Agent instead of curl's
# default "curl/x.y.z" — nyaa.si sits behind Cloudflare, and a bare curl UA
# is a commonly-targeted bot signature, especially for repeated identical
# requests (exactly the "works once, fails on repeat" pattern seen here).
_ANIME_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

fetch_url() {
    local url="$1"
    if command -v curl &> /dev/null; then
        curl -sfL -A "$_ANIME_UA" "$url"
    elif command -v wget &> /dev/null; then
        wget -q -U "$_ANIME_UA" -O - "$url"
    else
        echo "Error: curl or wget is required but not installed."
        return 1
    fi
}

# Download a .torrent file with retries. Unlike fetch_url, this:
#   - sends a Referer (nyaa's /download/ endpoint is rate-limited/guarded more
#     aggressively than its HTML pages),
#   - retries with backoff (429/5xx/Cloudflare challenges are usually transient),
#   - validates the payload is really bencoded data (starts with 'd') instead of
#     trusting HTTP 200 — a Cloudflare challenge page is HTML, not a torrent.
# Set ANIME_DEBUG=1 to print the HTTP status of each attempt.
_anime_fetch_torrent() {
    local id="$1" dest="$2"
    local url="https://nyaa.si/download/${id}.torrent"
    local attempt code

    for attempt in 1 2 3; do
        if command -v curl &> /dev/null; then
            code=$(curl -sL -A "$_ANIME_UA" -e "https://nyaa.si/view/${id}" \
                   -o "$dest" -w '%{http_code}' "$url" 2>/dev/null)
        else
            wget -q -U "$_ANIME_UA" --referer="https://nyaa.si/view/${id}" -O "$dest" "$url" 2>/dev/null \
                && code=200 || code=000
        fi
        [[ -n "$ANIME_DEBUG" ]] && echo "   [debug] attempt $attempt: HTTP $code" >&2

        # Valid torrent = HTTP 200 and first byte is 'd' (bencoded dict)
        if [[ "$code" == "200" && -s "$dest" && "$(head -c1 "$dest")" == "d" ]]; then
            return 0
        fi
        rm -f "$dest"
        sleep $((attempt * 2))
    done
    return 1
}

# Build a magnet URI from an info hash + title. Needs no request to nyaa's
# download endpoint at all, so it works even when that endpoint is blocking us.
_anime_build_magnet() {
    local hash="$1" title="$2"
    local magnet="magnet:?xt=urn:btih:${hash}&dn=$(_url_encode "$title")"
    local tr
    for tr in \
        "http://nyaa.tracker.wf:7777/announce" \
        "udp://open.stealth.si:80/announce" \
        "udp://tracker.opentrackr.org:1337/announce" \
        "udp://exodus.desync.com:6969/announce" \
        "udp://tracker.torrent.eu.org:451/announce"; do
        magnet+="&tr=$(_url_encode "$tr")"
    done
    echo "$magnet"
}

# Prune stale files from the cache dir so it doesn't grow forever. RSS cache
# entries past their TTL are dead weight (they get overwritten on next use of
# that exact query anyway, so keeping them serves no purpose); stray .torrent
# files are a safety net in case a prior session was killed before cleanup.
_anime_prune_cache() {
    [[ -d "$ANIME_CACHE_DIR" ]] || return 0
    find "$ANIME_CACHE_DIR" -name 'rss_*.xml' -mmin +$((ANIME_RSS_CACHE_TTL / 60 + 1)) -delete 2>/dev/null
    find "$ANIME_CACHE_DIR" -name '*.torrent' -mmin +60 -delete 2>/dev/null
}

# Fetch RSS with a short-lived local cache to avoid redundant network hits
_anime_fetch_rss_cached() {
    local url="$1"
    mkdir -p "$ANIME_CACHE_DIR"
    local hash=$(echo -n "$url" | cksum | awk '{print $1}')
    local cache_file="$ANIME_CACHE_DIR/rss_${hash}.xml"

    if [[ -f "$cache_file" ]]; then
        # date -r behaves identically on GNU and BSD, unlike `stat`, whose -f
        # flag means completely different things on each platform.
        local mtime=$(date -r "$cache_file" +%s 2>/dev/null)
        local now=$(date +%s)
        if [[ -n "$mtime" && $((now - mtime)) -lt $ANIME_RSS_CACHE_TTL ]]; then
            cat "$cache_file"
            return 0
        fi
    fi

    local body=$(fetch_url "$url")
    if echo "$body" | grep -q "<item>"; then
        # Only persist responses that actually contain entries — caching an
        # empty/failed fetch would make every retry of the same search term
        # replay that empty result for the rest of the TTL window.
        echo "$body" > "$cache_file"
    else
        rm -f "$cache_file"
    fi
    echo "$body"
}

# Function to calculate dynamic FZF height based on item count
_calculate_fzf_height() {
    local item_count="$1"
    local min_height=10
    local max_height=25
    local padding=4

    local calculated_height=$((item_count + padding))

    if [[ $calculated_height -lt $min_height ]]; then
        echo "${min_height}"
    elif [[ $calculated_height -gt $max_height ]]; then
        echo "${max_height}"
    else
        echo "${calculated_height}"
    fi
}

# Generic fzf single-select helper. Returns 1 (and prints nothing usable) if
# the user cancels (ESC / empty selection), 0 with the selection on stdout
# otherwise.
_anime_select_from_list() {
    local prompt="$1"
    local border_label="$2"
    local options="$3"

    local count=$(echo -e "$options" | wc -l)
    local height=$(_calculate_fzf_height $count)

    local sel=$(echo -e "$options" | fzf \
        --prompt="${prompt} › " \
        --height="${height}" \
        --border=rounded \
        --border-label=" ${border_label} " \
        --border-label-pos=2 \
        --cycle)

    [[ -z "$sel" ]] && return 1
    echo "$sel"
    return 0
}

# Quality picker. include_any=1 adds "Any Quality" (mapped to empty string).
_anime_select_quality() {
    local border_label="$1"
    local include_any="${2:-1}"
    local options="1080p\n720p\n480p"
    [[ "$include_any" == "1" ]] && options="${options}\nAny Quality"

    local sel
    sel=$(_anime_select_from_list "📺 Quality" "$border_label" "$options") || return 1
    [[ "$sel" == "Any Quality" ]] && sel=""
    echo "$sel"
}

# Fansub picker. include_all=1 adds "All Fansubs" (mapped to empty string).
# list="short" uses the reduced 3-entry list (used by RSS setup originally).
_anime_select_fansub() {
    local border_label="$1"
    local include_all="${2:-1}"
    local list="${3:-full}"
    local options

    if [[ "$list" == "short" ]]; then
        options="SubsPlease\nErai-raws\nDameDesuYo"
    else
        options="SubsPlease\nErai-raws\nDameDesuYo\nHorribleSubs\nCommie\nAniplex"
    fi
    [[ "$include_all" == "1" ]] && options="All Fansubs\n${options}"

    local sel
    sel=$(_anime_select_from_list "👥 Fansub" "$border_label" "$options") || return 1
    [[ "$sel" == "All Fansubs" ]] && sel=""
    echo "$sel"
}

# Search term entry with recent-history picker via fzf.
_anime_get_search_term() {
    mkdir -p "$(dirname "$ANIME_HISTORY_FILE")"
    touch "$ANIME_HISTORY_FILE"

    local history
    if command -v tac &> /dev/null; then
        history=$(tac "$ANIME_HISTORY_FILE" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | awk '!seen[$0]++')
    else
        history=$(tail -r "$ANIME_HISTORY_FILE" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | awk '!seen[$0]++')
    fi

    local fzf_output
    fzf_output=$(echo "$history" | fzf \
        --prompt="🔍 Search (pick recent or type new) › " \
        --print-query \
        --height=15 \
        --border=rounded \
        --border-label=" Recent Searches " \
        --border-label-pos=2 \
        --cycle)
    local fzf_status=$?

    # fzf exit codes: 0 = normal accept (item selected), 1 = no match (typed
    # query accepted via Enter anyway — this is the whole point of
    # --print-query, and happens on every brand-new search term), 130 =
    # interrupted (ESC/Ctrl-C). Only 130 means "actually cancelled."
    if [[ $fzf_status -eq 130 ]]; then
        return 1
    fi

    local result
    result=$(echo "$fzf_output" | tail -1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    if [[ -n "$result" ]]; then
        if [[ "$(tail -1 "$ANIME_HISTORY_FILE" 2>/dev/null)" != "$result" ]]; then
            echo "$result" >> "$ANIME_HISTORY_FILE"
        fi
    fi
    echo "$result"
}

# Main FZF anime interface
anime() {
    if ! command -v fzf &> /dev/null; then
        echo "Error: fzf is required but not installed."
        echo "Install it with: brew install fzf (macOS) or apt install fzf (Ubuntu)"
        return 1
    fi

    _anime_prune_cache

    while true; do
        local options="🔍 Search Anime\n📺 Latest Releases\n🌸 Seasonal Anime\n⚙️ Browse by Fansub\n🔄 Setup RSS\n🧹 Manage History\n❌ Exit"
        local option_count=$(echo -e "$options" | wc -l)
        local height=$(_calculate_fzf_height $option_count)

        local choice=$(echo -e "$options" | fzf \
            --prompt="🎌 Anime Manager › " \
            --height="${height}" \
            --border=rounded \
            --border-label=" Main Menu " \
            --border-label-pos=2 \
            --ansi \
            --cycle \
            --info=inline)

        case "$choice" in
            *"Search Anime"*)
                _anime_search_interface
                [[ $? -eq 0 ]] && break
                ;;
            *"Latest Releases"*)
                _anime_latest_interface
                [[ $? -eq 0 ]] && break
                ;;
            *"Seasonal Anime"*)
                _anime_seasonal_interface
                [[ $? -eq 0 ]] && break
                ;;
            *"Browse by Fansub"*)
                _anime_fansub_interface
                [[ $? -eq 0 ]] && break
                ;;
            *"Setup RSS"*)
                _anime_rss_interface
                ;;
            *"Manage History"*)
                _anime_history_interface
                ;;
            *"Exit"*|"")
                break
                ;;
        esac
    done

    clear
}

# Search interface with multiple selections
_anime_search_interface() {
    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "                    🔍 SEARCH ANIME                             "
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    local search_term
    search_term=$(_anime_get_search_term)

    if [[ -z "$search_term" ]]; then
        echo "⚠️  No search term provided."
        sleep 1
        return 1
    fi

    local quality
    quality=$(_anime_select_quality "Select Quality" "1") || { clear; return 1; }

    local fansub
    fansub=$(_anime_select_fansub "Select Fansub Group" "1" "full") || { clear; return 1; }

    _anime_browse_and_download "$search_term" "$quality" "$fansub"
    return $?
}

# Latest releases interface
_anime_latest_interface() {
    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "                    📺 LATEST RELEASES                          "
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    _anime_browse_and_download "" "1080p" ""
    return $?
}

# Seasonal anime interface
_anime_seasonal_interface() {
    echo "🌸 Fetching seasonal anime..."

    local current_month=$(date +%m)
    local season=""

    if [[ $current_month -ge 1 && $current_month -le 3 ]]; then
        season="WINTER"
    elif [[ $current_month -ge 4 && $current_month -le 6 ]]; then
        season="SPRING"
    elif [[ $current_month -ge 7 && $current_month -le 9 ]]; then
        season="SUMMER"
    else
        season="FALL"
    fi

    echo "📅 Current season: $season $(date +%Y)"
    _anime_browse_and_download "" "1080p" "SubsPlease"
    return $?
}

# Fansub-specific interface
_anime_fansub_interface() {
    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "                    ⚙️ BROWSE BY FANSUB                        "
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    local fansub
    fansub=$(_anime_select_fansub "Select Fansub Group" "0" "full") || { clear; return 1; }

    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "                    👥 $fansub                                  "
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo -n "Enter anime name (or leave empty for all): "
    read -r search_term

    local quality
    quality=$(_anime_select_quality "Select Quality" "1") || { clear; return 1; }

    _anime_browse_and_download "$search_term" "$quality" "$fansub"
    return $?
}

# Search history management: clear selected entries, or clear everything.
# Always returns 1 (back to main menu).
_anime_history_interface() {
    mkdir -p "$(dirname "$ANIME_HISTORY_FILE")"
    touch "$ANIME_HISTORY_FILE"

    while true; do
        local total=$(grep -c . "$ANIME_HISTORY_FILE" 2>/dev/null)
        total=${total:-0}

        local choice
        choice=$(_anime_select_from_list "🧹 History ($total)" "Manage Search History" \
            "Clear selected entries\nClear ALL history\nBack") || { clear; return 1; }

        case "$choice" in
            "Clear selected entries")
                if [[ "$total" -eq 0 ]]; then
                    echo "ℹ️  History is already empty."
                    sleep 1
                    continue
                fi

                local entries
                if command -v tac &> /dev/null; then
                    entries=$(tac "$ANIME_HISTORY_FILE" | grep . | awk '!seen[$0]++')
                else
                    entries=$(tail -r "$ANIME_HISTORY_FILE" | grep . | awk '!seen[$0]++')
                fi

                local marked
                marked=$(echo "$entries" | fzf \
                    --multi \
                    --prompt="🗑️  Mark for deletion › " \
                    --height=20 \
                    --border=rounded \
                    --border-label=" TAB: mark, Ctrl-A: mark all, Enter: delete marked, ESC: cancel " \
                    --border-label-pos=2 \
                    --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
                    --cycle)

                [[ -z "$marked" ]] && continue

                # Exact whole-line, fixed-string match so "one" doesn't also
                # delete "one piece". grep exits 1 when nothing is left; that's fine.
                local tmp=$(mktemp)
                grep -vxF -f <(printf '%s\n' "$marked") "$ANIME_HISTORY_FILE" > "$tmp"
                mv "$tmp" "$ANIME_HISTORY_FILE"

                local removed=$(echo "$marked" | wc -l | tr -d ' ')
                echo "✅ Removed $removed entr$([[ $removed -eq 1 ]] && echo y || echo ies)."
                sleep 1
                ;;
            "Clear ALL history")
                if [[ "$total" -eq 0 ]]; then
                    echo "ℹ️  History is already empty."
                    sleep 1
                    continue
                fi
                read -q "REPLY?⚠️  Delete all $total history entries? (y/n): "
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    : > "$ANIME_HISTORY_FILE"
                    echo "✅ History cleared."
                else
                    echo "Cancelled."
                fi
                sleep 1
                ;;
            *)
                clear
                return 1
                ;;
        esac
    done
}

# RSS setup interface
_anime_rss_interface() {
    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "                    🔄 RSS SETUP                                "
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo -n "Enter anime name for RSS setup: "
    read -r anime_name

    if [[ -z "$anime_name" ]]; then
        echo "⚠️  No anime name provided."
        sleep 1
        return 1
    fi

    local quality
    quality=$(_anime_select_quality "RSS Quality" "0") || { clear; return 1; }

    local fansub
    fansub=$(_anime_select_fansub "RSS Fansub Group" "0" "short") || { clear; return 1; }

    _setup_rss_feed "$anime_name" "$quality" "$fansub"
    return 1
}

# Core function to fetch, display, and handle anime selection.
# Return codes: 0 = user wants to exit the tool entirely.
#               1 = go back to main menu (no results, cancelled, or "continue browsing").
_anime_browse_and_download() {
    local search_term="$1"
    local quality="$2"
    local fansub="$3"
    local max_results=50

    # Build RSS URL
    local rss_url="https://nyaa.si/?page=rss&c=1_2&f=0"
    [[ -n "$search_term" ]] && rss_url="https://nyaa.si/?page=rss&q=$(_url_encode "$search_term")&c=1_2&f=0"

    # Try SubsPlease RSS if conditions match
    if [[ "$fansub" == "SubsPlease" && -z "$search_term" && "$quality" == "1080p" ]]; then
        local subsplease_url="https://subsplease.org/rss/?t&r=1080"
        if fetch_url "$subsplease_url" | grep -q "<item>"; then
            rss_url="$subsplease_url"
        fi
    fi

    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "                    🔍 FETCHING TORRENTS                        "
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "⏳ Loading anime torrents..."
    echo ""

    local temp_file=$(mktemp)
    local display_file=$(mktemp)

    # RSS parsing. ID extraction uses plain sub()/gsub() (POSIX-portable) —
    # the original used gawk's 3-arg match(), which fails on BSD awk/mawk.
    _anime_fetch_rss_cached "$rss_url" | awk -v fansub="$fansub" -v quality="$quality" -v max_results="$max_results" '
    BEGIN {
        RS = "<item>";
        FS = "\n";
        count = 0;
    }
    NR > 1 {
        title = ""; pubDate = ""; id = ""; link = ""; hash = "";

        for (i=1; i<=NF; i++) {
            if ($i ~ /<nyaa:infoHash>/) {
                h = $i;
                gsub(/<nyaa:infoHash>|<\/nyaa:infoHash>/, "", h);
                gsub(/^[ \t\r]+|[ \t\r]+$/, "", h);
                hash = h;
            }
            if ($i ~ /<title>/) {
                gsub(/<title>|<\/title>/, "", $i);
                gsub(/&amp;/, "\\&", $i);
                gsub(/&lt;/, "<", $i);
                gsub(/&gt;/, ">", $i);
                gsub(/&quot;/, "\"", $i);
                gsub(/&#39;/, "'"'"'", $i);
                gsub(/^\s+|\s+$/, "", $i);
                title = $i;
            }
            else if ($i ~ /<pubDate>/) {
                gsub(/<pubDate>|<\/pubDate>/, "", $i);
                pubDate = $i;
            }
            else if ($i ~ /<link>/) {
                gsub(/<link>|<\/link>/, "", $i);
                gsub(/^\s+|\s+$/, "", $i);
                link = $i;
                # Extract ID from download link: https://nyaa.si/download/2042890.torrent
                if (link ~ /\/download\/[0-9]+\.torrent/) {
                    id = link;
                    sub(/.*\/download\//, "", id);
                    sub(/\.torrent.*/, "", id);
                }
            }
        }

        if (title != "" && pubDate != "" && id != "" && length(id) >= 6) {
            matches = 1;

            if (fansub != "" && index(tolower(title), tolower(fansub)) == 0) {
                matches = 0;
            }
            if (quality != "" && index(tolower(title), tolower(quality)) == 0) {
                matches = 0;
            }

            if (matches) {
                count++;
                if (count <= max_results) {
                    printf("%s|%s|%s|%s\n", pubDate, title, id, hash);
                }
            }
        }
    }' > "$temp_file"

    if [[ ! -s "$temp_file" ]]; then
        clear
        echo "════════════════════════════════════════════════════════════════"
        echo "                    ⚠️  NO RESULTS FOUND                       "
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "Search term : ${search_term:-<none>}"
        echo "Quality     : ${quality:-Any}"
        echo "Fansub      : ${fansub:-All}"
        echo ""
        echo "No anime torrents found matching your criteria."
        echo ""
        echo "Try:"
        echo "  • Different search terms"
        echo "  • Different quality settings"
        echo "  • Different fansub groups"
        echo ""
        rm -f "$temp_file" "$display_file"
        sleep 2
        return 1
    fi

    local result_count=$(wc -l < "$temp_file")
    local display_height=$(_calculate_fzf_height $result_count)

    # Fields: date | title... | id | hash. Titles can themselves contain "|"
    # (e.g. "Trix ... | The Apothecary Diaries"), so id/hash are read from the
    # END of the line and the title is rebuilt from everything in between.
    awk -F'|' '{
        title = $2;
        for (k = 3; k <= NF - 2; k++) title = title "/" $k;
        gsub(/^\s+|\s+$/, "", title);

        date_str = $1;
        gsub(/^[A-Za-z]+,\s*/, "", date_str);
        split(date_str, date_parts, " ");

        if (length(date_parts) >= 2) {
            day = date_parts[1];
            month = substr(date_parts[2], 1, 3);
            if (length(day) == 1) day = "0" day;
            short_date = day " " month;
        } else {
            short_date = substr(date_str, 1, 6);
        }

        id = $(NF - 1);
        hash = $NF;
        gsub(/[ \t\r]/, "", hash);
        if (length(id) < 6) {
            id = "N/A";
        }
        if (hash == "") hash = "-";

        printf("%s | %s | %s | %s\n", short_date, id, hash, title);
    }' "$temp_file" > "$display_file"

    local selections=$(cat "$display_file" | fzf \
        --multi \
        --prompt="🎯 Select › " \
        --height="${display_height}" \
        --border=rounded \
        --border-label=" Anime Torrents (TAB: multi-select, ESC: cancel) " \
        --border-label-pos=2 \
        --delimiter=' [|] ' \
        --with-nth='1,2,4..' \
        --preview='echo "📅 Date: {1}"; echo "ID: {2}"; echo ""; echo "📺 Title: {4..}" | fold -s -w 70' \
        --preview-window=up:8:wrap \
        --bind='ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all' \
        --cycle \
        --no-info \
        --ansi)

    if [[ -z "$selections" ]]; then
        rm -f "$temp_file" "$display_file"
        clear
        return 1
    fi

    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "                    🔽 FETCHING TORRENT FILES                   "
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    mkdir -p "$ANIME_CACHE_DIR"

    # Sources handed to qBittorrent: either .torrent file paths or magnet URIs.
    local -a torrent_files
    local counter=1
    local total=$(echo "$selections" | wc -l)

    while IFS= read -r line; do
        # Line format: date | id | hash | title   (title may itself contain " | ")
        local r1="${line#* | }"
        local torrent_id="${r1%% | *}"
        local r2="${r1#* | }"
        local info_hash="${r2%% | *}"
        local title="${r2#* | }"

        echo "[$counter/$total] 📺 $title"

        if [[ -z "$torrent_id" || "$torrent_id" == "N/A" ]]; then
            echo "   ⚠️  Skipped: invalid torrent ID"
            counter=$((counter + 1))
            continue
        fi

        local torrent_file="$ANIME_CACHE_DIR/$torrent_id.torrent"
        if _anime_fetch_torrent "$torrent_id" "$torrent_file"; then
            torrent_files+=("$torrent_file")
            echo "   ✅ Fetched"
        elif [[ -n "$info_hash" && "$info_hash" != "-" ]]; then
            torrent_files+=("$(_anime_build_magnet "$info_hash" "$title")")
            echo "   🧲 .torrent download blocked, using magnet link instead"
        else
            echo "   ❌ Failed to fetch torrent file (and no info hash for magnet fallback)"
        fi
        counter=$((counter + 1))
    done < <(echo "$selections")

    echo ""
    echo "════════════════════════════════════════════════════════════════"

    if [[ ${#torrent_files[@]} -eq 0 ]]; then
        echo "⚠️  Nothing could be fetched (torrent download and magnet fallback both failed)."
    else
        echo "📤 Sending ${#torrent_files[@]} torrent(s) to qBittorrent..."
        if command -v qbittorrent &> /dev/null; then
            qbittorrent --confirm-legal-notice --skip-dialog=true \
                --save-path="$ANIME_DOWNLOAD_DIR" "${torrent_files[@]}" &> /dev/null &
            disown
            sleep 1
            echo "✅ Sent to qBittorrent"
        elif command -v qbittorrent-nox &> /dev/null; then
            qbittorrent-nox --confirm-legal-notice --skip-dialog=true \
                --save-path="$ANIME_DOWNLOAD_DIR" "${torrent_files[@]}" &> /dev/null &
            disown
            sleep 1
            echo "✅ Sent to qBittorrent-nox"
        else
            echo "⚠️  qBittorrent not found. Torrent files kept at: $ANIME_CACHE_DIR"
        fi
        # Not deleted here: no confirmation the client has actually read the
        # file yet (cold-start boot time is unbounded). The prune sweep in
        # _anime_prune_cache clears .torrent files older than 60 minutes on
        # the next anime() launch instead — safe because that's long past
        # any plausible add-time, whether the client was already running or
        # not.
    fi

    echo "════════════════════════════════════════════════════════════════"
    echo ""

    rm -f "$temp_file" "$display_file"

    read -q "REPLY?🔄 Continue browsing? (y/n): "
    echo ""
    clear
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 1   # back to main menu (anime()'s while loop iterates again)
    else
        echo "👋 Exiting anime manager."
        return 0   # signal full exit
    fi
}

# RSS setup function
_setup_rss_feed() {
    local anime_name="$1"
    local quality="$2"
    local fansub="$3"

    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "                    🔄 RSS SETUP INSTRUCTIONS                   "
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "📺 Anime: $anime_name"
    echo "🎬 Quality: $quality"
    echo "👥 Fansub: $fansub"
    echo ""
    echo "Steps to set up in qBittorrent:"
    echo "────────────────────────────────────────────────────────────────"
    echo "1. Open qBittorrent"
    echo "2. Go to View > RSS Reader"
    echo "3. Click 'New subscription' and add:"
    echo "   https://nyaa.si/?page=rss&c=1_2&f=0"
    echo ""
    echo "4. Click 'RSS Downloader' button"
    echo "5. Create a new rule named: $anime_name"
    echo "6. In 'Must contain', add: $fansub $anime_name $quality"
    echo "7. Set download folder to: $ANIME_DOWNLOAD_DIR"
    echo ""

    if [[ "$fansub" == "SubsPlease" ]]; then
        echo "💡 For SubsPlease, you can also use this direct RSS URL:"
        echo "   https://subsplease.org/rss/?t&r=${quality/p/}"
        echo ""
    fi

    echo "════════════════════════════════════════════════════════════════"
    echo ""

    read -q "REPLY?🚀 Launch qBittorrent now? (y/n): "
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v qbittorrent &> /dev/null; then
            qbittorrent --confirm-legal-notice &> /dev/null &
            disown
            echo "✅ qBittorrent launched"
        elif command -v qbittorrent-nox &> /dev/null; then
            qbittorrent-nox --confirm-legal-notice &> /dev/null &
            disown
            echo "✅ qBittorrent-nox launched"
        else
            echo "⚠️  Error: qBittorrent not found in PATH."
        fi
    fi
}

# Help function
anime_help() {
    clear
    cat << 'EOF'
════════════════════════════════════════════════════════════════
    🎮 FZF ANIME TORRENT MANAGER - HELP
════════════════════════════════════════════════════════════════

Main Command:
  anime                         Launch interactive FZF interface

Features:
  🔍 Search Anime              Search by title, pick from recent
                                searches or type a new one
  📺 Latest Releases          Browse newest anime releases
  🌸 Seasonal Anime           Current season from SubsPlease
  ⚙️ Browse by Fansub         Browse specific fansub releases
  🔄 Setup RSS                Configure automatic downloads
  🧹 Manage History           Clear selected or all search history

Navigation:
  TAB                          Select multiple torrents
  Ctrl+A                       Select all torrents
  Ctrl+D                       Deselect all torrents
  Ctrl+T                       Toggle all selections
  Enter                        Confirm selection
  ESC                          Cancel/go back
  Answering "n" to "Continue browsing?" exits back to the shell.

Tips:
  • Use multi-select (TAB) to batch download episodes
  • All downloads go to: $ANIME_DOWNLOAD_DIR
  • Search history is stored in: $ANIME_HISTORY_FILE
  • RSS responses are cached for 60s to cut down on repeat requests

Requirements:
  • fzf (fuzzy finder)
  • qBittorrent or qBittorrent-nox
  • curl or wget

════════════════════════════════════════════════════════════════
EOF
}
