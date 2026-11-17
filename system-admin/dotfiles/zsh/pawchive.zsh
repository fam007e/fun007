#!/usr/bin/env zsh
# pawchive.zsh - zsh client for the Pawchive API v1.0.0 (OAS3)
#
# Usage:
#   source pawchive.zsh      # gives you `pawchive` + tab completion
#   ./pawchive.zsh <cmd>     # or run it directly
#
# Requires: curl, jq (jq only for pretty-printing / --all pagination)
#
# Env vars:
#   PAWCHIVE_BASE       API base (default https://pawchive.pw/api/v1)
#   PAWCHIVE_COOKIE     Auth cookie for /account and /favorites, e.g. "session=abc123"
#   PAWCHIVE_ACCEPT    Accept header for API calls (default application/json; the Mihon
#                      extension sends text/css instead - try that if you get odd 4xx)
#   PAWCHIVE_SITE      Site root for HTML pages (default: PAWCHIVE_BASE minus /api/v1)
#   PAWCHIVE_FILE_BASE   Full-size file host  (default https://file.pawchive.pw/data)
#   PAWCHIVE_THUMB_BASE  Thumbnail host       (default https://img.pawchive.pw/thumbnail/data)
#   PAWCHIVE_CACHE_MIN   Minutes to cache the /creators list (default 30)
#   PAWCHIVE_USER_POSTS_SUFFIX  Appended to /{svc}/user/{id} for post listing. Spec says "",
#                      the Mihon extension calls "/posts". Set it if one form misbehaves.
#   PAWCHIVE_UA         User-Agent string
#   PAWCHIVE_DELAY      Seconds to sleep between pages with --all (default 0.5)
#   PAWCHIVE_MAX_PAGES  Safety cap for --all (default 200)
#   PAWCHIVE_YTDLP_ARGS Extra yt-dlp arguments for --embed downloads, e.g. "--cookies-from-browser firefox".
#                      If unset and only node (no deno) is installed, "--js-runtimes node" is added for you.
#   PAWCHIVE_BROWSE_DETAILS  Set to 1 to show likes and last-updated date in the creator list
#   PAWCHIVE_RETRY_WAIT Base seconds between retries of transient errors (default 3)

: ${PAWCHIVE_BASE:=https://pawchive.pw/api/v1}

# Aliases from your shell (cp='cp -v', mkdir='mkdir -v', grep, cat, ...) would be expanded
# inside the function bodies below and change their output - parse this file without them.
_PC_ALIASES_WERE=${options[aliases]:-on}
setopt no_aliases
: ${PAWCHIVE_ACCEPT:=application/json}
: ${PAWCHIVE_SITE:=${PAWCHIVE_BASE%/api/v1*}}
: ${PAWCHIVE_FILE_BASE:=https://file.pawchive.pw/data}
: ${PAWCHIVE_THUMB_BASE:=https://img.pawchive.pw/thumbnail/data}
: ${PAWCHIVE_IMG_ACCEPT:=image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8}
: ${PAWCHIVE_CACHE_MIN:=30}
: ${PAWCHIVE_USER_POSTS_SUFFIX:=}
: ${PAWCHIVE_COOKIE:=}
: ${PAWCHIVE_UA:=pawchive-zsh/1.0}
: ${PAWCHIVE_DELAY:=0.5}
: ${PAWCHIVE_RETRY_WAIT:=3}
: ${PAWCHIVE_MAX_PAGES:=200}

# ---------------------------------------------------------------- internals

_pc_err() { print -u2 -- "pawchive: $*"; }

# curl wrapper with a friendly error if it is missing
_pc_curl() {
  (( $+commands[curl] )) || { _pc_err "curl not found - install it (Arch: sudo pacman -S curl)"; return 127 }
  command curl "$@"
}

# _pc_req METHOD PATH [extra curl args...]  -> body on stdout, rc!=0 on failure
# rc 22 = final HTTP error (4xx: body still printed)
# rc 24 = server-side error that persisted after retries (HTTP 408/429/5xx - includes the
#         Cloudflare 52x "origin timed out" family, e.g. 524 on big post listings)
# Network-level failures (reset, truncated transfer, timeout) keep their curl exit code.
# Everything transient is retried up to 3 more times with growing waits (PAWCHIVE_RETRY_WAIT).
_pc_req() {
  local method=$1 apath=$2; shift 2
  local -a args=(-sS --stderr /dev/null --fail-with-body --connect-timeout 20 -X "$method" -A "$PAWCHIVE_UA"
                 -H "Accept: ${PAWCHIVE_ACCEPT}" -w $'\n%{http_code}')
  [[ -n $PAWCHIVE_COOKIE ]] && args+=(-H "Cookie: $PAWCHIVE_COOKIE")
  local out rc n code body why
  for n in 1 2 3 4; do
    out=$(_pc_curl "${args[@]}" "$@" "${PAWCHIVE_BASE}${apath}"); rc=$?
    code=${out##*$'\n'}; body=${out%$'\n'*}
    if [[ $code == <-> ]]; then code=$(( 10#$code )); else code=0; body=$out; fi
    (( rc == 0 || rc == 127 )) && break
    if (( rc == 22 )); then
      if (( code == 408 || code == 429 || code >= 500 )); then rc=24; why="server error HTTP $code"
      else break; fi
    else
      why="network error (curl exit $rc)"
    fi
    (( n < 4 )) && { _pc_err "$why - retrying ($n/3) in $(( n * PAWCHIVE_RETRY_WAIT ))s..."; sleep $(( n * PAWCHIVE_RETRY_WAIT )); }
  done
  (( rc == 24 )) && _pc_err "giving up: $why"
  (( rc != 0 && rc != 22 && rc != 24 && rc != 127 )) && _pc_err "giving up: $why"
  print -r -- "$body"
  return $rc
}

# Print a response: pretty JSON on a tty, raw when piped
_pc_print() {
  if [[ -t 1 ]] && (( $+commands[jq] )); then
    jq . 2>/dev/null <<<"$1" || print -r -- "$1"
  else
    print -r -- "$1"
  fi
}

# _pc_call METHOD PATH [curl args...]
_pc_call() {
  local out rc
  out=$(_pc_req "$@"); rc=$?
  _pc_print "$out"
  return $rc
}

# Validate path segments so we never build a weird URL
_pc_seg() {
  local label=$1 val=$2
  if [[ -z $val || $val == */* || $val == *\?* || $val == *' '* ]]; then
    _pc_err "invalid $label: '$val'"; return 1
  fi
}

# Offsets must be multiples of 50 (API returns 400 otherwise)
_pc_offset() {
  [[ -z $1 ]] && return 0
  if [[ $1 != <-> ]] || (( $1 % 50 != 0 )); then
    _pc_err "offset must be a non-negative multiple of 50 (got '$1')"; return 1
  fi
}

# _pc_paged PATH [-G curl query args...]
# Fetches offset 0,50,100.. and merges the arrays. Needs jq.
# Only an HTTP 4xx past the end counts as "end of list"; any other failure aborts - unless
# PAWCHIVE_ALLOW_PARTIAL is set, in which case the pages loaded so far are printed and the
# exit code is 3 (used by the browser so one flaky page doesn't lose everything).
_pc_paged() {
  local apath=$1; shift
  (( $+commands[jq] )) || { _pc_err "--all needs jq"; return 1 }
  local -a pages; local o=0 page n i=0 rc partial=0
  while (( i < PAWCHIVE_MAX_PAGES )); do
    [[ -t 2 ]] && print -u2 -- "  fetching posts $(( o + 1 ))-$(( o + 50 ))..."
    page=$(_pc_req GET "$apath" -G "$@" --data-urlencode "o=$o"); rc=$?
    # an HTTP 4xx past the end is normal termination once we already have data
    if (( rc == 22 && ${#pages} )); then break; fi
    if (( rc != 0 )); then
      if (( ${#pages} )) && [[ -n $PAWCHIVE_ALLOW_PARTIAL ]]; then
        _pc_err "offset $o failed (exit $rc) - keeping the ${#pages} page(s) loaded so far"
        partial=1; break
      fi
      (( rc == 22 )) && print -r -- "$page" >&2
      _pc_err "request failed at offset $o (exit $rc) - stopping so a partial list isn't mistaken for a full one"
      return $rc
    fi
    n=$(jq 'length' <<<"$page" 2>/dev/null) || { _pc_err "non-JSON response at offset $o"; return 1 }
    (( n == 0 )) && break
    pages+=("$page")
    (( n < 50 )) && break
    (( o += 50, i++ ))
    sleep "$PAWCHIVE_DELAY"
  done
  if (( ${#pages} )); then
    printf '%s\n' "${pages[@]}" | jq -s 'add' | { [[ -t 1 ]] && cat || jq -c .; }
  else
    print -r -- '[]'
  fi
  return $(( partial ? 3 : 0 ))
}

# ------------------------------------------------------------ API: posts

# Cached GET /creators (the list is huge; the Mihon extension caches it 30 min too)
_pc_creators_json() {
  local dir=${XDG_CACHE_HOME:-$HOME/.cache}/pawchive file
  file=$dir/creators.json
  mkdir -p "$dir"
  if [[ $1 != --refresh && -s $file && -z $(find "$file" -mmin +"$PAWCHIVE_CACHE_MIN" 2>/dev/null) ]]; then
    cat "$file"; return
  fi
  local out; out=$(_pc_req GET /creators) || { print -r -- "$out" >&2; return 1 }
  print -r -- "$out" >| "$file"
  print -r -- "$out"
}

# GET /creators  (large response! cached; --refresh to bypass cache)
pawchive_creators() {
  local out; out=$(_pc_creators_json "$@") || return
  _pc_print "$out"
}

# Client-side search over the cached creators list (the API has no search for this).
#   pawchive creators-search [name] [-s service] [--sort pop|new|lat|tit] [--limit N] [--refresh]
pawchive_creators_search() {
  (( $+commands[jq] )) || { _pc_err "needs jq"; return 1 }
  local -A o; zparseopts -D -E -F -A o -- s: -sort: -limit: -refresh || return 1
  local name=${1:-} sort=${o[--sort]:-pop} limit=${o[--limit]:-25} svc=${o[-s]:-}
  [[ $limit == <-> ]] || { _pc_err "--limit must be a number"; return 1 }
  local out; out=$(_pc_creators_json ${o[--refresh]:+--refresh}) || return
  out=$(jq --arg q "$name" --arg svc "$svc" --arg sort "$sort" --argjson limit "$limit" '
    # "updated" is sometimes a unix number, sometimes an ISO string
    def ts: if (.updated | type) == "string"
            then (try (.updated | sub("\\.[0-9]+"; "") | if endswith("Z") then . else . + "Z" end | fromdateiso8601) catch 0)
            else (.updated // 0) end;
    [ .[] | select(($q == "" or (.name | ascii_downcase | contains($q | ascii_downcase)))
                   and ($svc == "" or .service == $svc)) ]
    | (if   $sort == "pop" then sort_by(-(.favorited // 0))
       elif $sort == "tit" then sort_by(.name | ascii_downcase)
       elif $sort == "new" then sort_by(-(.id | tonumber? // 0))
       else sort_by(-ts) end)
    | .[:$limit]' <<<"$out") || return
  _pc_print "$out"
}

# GET /posts   [-q query] [-o offset] [--all]
pawchive_posts() {
  local -A o; zparseopts -D -E -F -A o -- q: o: -all || return 1
  _pc_offset "${o[-o]}" || return 1
  local -a qs=()
  [[ -n ${o[-q]} ]] && qs+=(--data-urlencode "q=${o[-q]}")
  if (( ${+o[--all]} )); then _pc_paged /posts "${qs[@]}"; return; fi
  [[ -n ${o[-o]} ]] && qs+=(--data-urlencode "o=${o[-o]}")
  _pc_call GET /posts -G "${qs[@]}"
}

# GET /{service}/user/{creator_id}   [-q query] [-t tag]... [-o offset] [--all]
pawchive_user_posts() {
  local -A o; local -a tags
  zparseopts -D -E -F -A o -- q: o: -all t+:=tags || return 1
  local service=$1 cid=$2
  _pc_seg service "$service" && _pc_seg creator_id "$cid" || return 1
  _pc_offset "${o[-o]}" || return 1
  local -a qs=() ; local i
  [[ -n ${o[-q]} ]] && qs+=(--data-urlencode "q=${o[-q]}")
  for (( i = 2; i <= ${#tags}; i += 2 )); do qs+=(--data-urlencode "tag=${tags[i]}"); done
  local apath="/${service}/user/${cid}${PAWCHIVE_USER_POSTS_SUFFIX}"
  if (( ${+o[--all]} )); then _pc_paged "$apath" "${qs[@]}"; return; fi
  [[ -n ${o[-o]} ]] && qs+=(--data-urlencode "o=${o[-o]}")
  _pc_call GET "$apath" -G "${qs[@]}"
}

# GET /{service}/user/{creator_id}/announcements
pawchive_announcements() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" || return 1
  _pc_call GET "/$1/user/$2/announcements"
}

# GET /{service}/user/{creator_id}/fancards   (fanbox only)
pawchive_fancards() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" || return 1
  _pc_call GET "/$1/user/$2/fancards"
}

# GET /{service}/user/{creator_id}/post/{post_id}
pawchive_post() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post_id "$3" || return 1
  _pc_call GET "/$1/user/$2/post/$3"
}

# GET /{service}/user/{creator_id}/post/{post_id}/revisions
pawchive_revisions() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post_id "$3" || return 1
  _pc_call GET "/$1/user/$2/post/$3/revisions"
}

# ---------------------------------------------------------- API: creators

# GET /{service}/user/{creator_id}/profile
pawchive_profile() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" || return 1
  _pc_call GET "/$1/user/$2/profile"
}

# GET /{service}/user/{creator_id}/links
pawchive_links() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" || return 1
  _pc_call GET "/$1/user/$2/links"
}

# GET /{service}/user/{creator_id}/tags
pawchive_tags() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" || return 1
  _pc_call GET "/$1/user/$2/tags"
}

# ---------------------------------------------------------- API: comments

# GET /{service}/user/{creator_id}/post/{post_id}/comments
pawchive_comments() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post_id "$3" || return 1
  _pc_call GET "/$1/user/$2/post/$3/comments"
}

# ------------------------------------------------------- API: post flagging

# POST /{service}/user/{creator_id}/post/{post}/flag
pawchive_flag() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post "$3" || return 1
  _pc_call POST "/$1/user/$2/post/$3/flag"
}

# GET /{service}/user/{creator_id}/post/{post}/flag
pawchive_flag_status() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post "$3" || return 1
  _pc_call GET "/$1/user/$2/post/$3/flag"
}

# ------------------------------------------------------------ API: favorites
# These need PAWCHIVE_COOKIE (401 "Unauthorized Access" otherwise).

# GET /account/favorites [artist|post]   (the userscript sends type=artist; the Mihon
# extension sends no type - so it is optional here)
pawchive_favorites() {
  local -a q=(); [[ -n $1 ]] && q=(--data-urlencode "type=$1")
  _pc_call GET /account/favorites -G "${q[@]}"
}

# GET /app_version  (undocumented in the OAS, used by the PawchiveAPI userscript)
pawchive_app_version() { _pc_call GET /app_version }

# POST|DELETE /favorites/post/{service}/{creator_id}/{post_id}
pawchive_fav_post() {
  local action=$1; shift
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post_id "$3" || return 1
  case $action in
    add)    _pc_call POST   "/favorites/post/$1/$2/$3" ;;
    rm|del) _pc_call DELETE "/favorites/post/$1/$2/$3" ;;
    *) _pc_err "fav-post: expected add|rm"; return 1 ;;
  esac
}

# POST|DELETE /favorites/creator/{service}/{creator_id}
pawchive_fav_creator() {
  local action=$1; shift
  _pc_seg service "$1" && _pc_seg creator_id "$2" || return 1
  case $action in
    add)    _pc_call POST   "/favorites/creator/$1/$2" ;;
    rm|del) _pc_call DELETE "/favorites/creator/$1/$2" ;;
    *) _pc_err "fav-creator: expected add|rm"; return 1 ;;
  esac
}

# ---------------------------------------------------------- API: file search

# GET /search_hash/{file_hash}
pawchive_hash() {
  [[ $1 == [0-9a-fA-F]## ]] || { _pc_err "hash must be hex"; return 1 }
  _pc_call GET "/search_hash/$1"
}

# ------------------------------------------------------------------ extras

# Download a file by its API path (the .file.path / .attachments[].path of a post).
#   pawchive download <path> [outfile] [--thumb]
# Tries the full-size host first, then falls back to the thumbnail host (like the
# Mihon extension does on a 404). --thumb goes straight to the thumbnail.
pawchive_download() {
  local -A o; zparseopts -D -E -F -A o -- -thumb || return 1
  local rpath=$1 out=${2:-}
  [[ $rpath == /* ]] || { _pc_err "path should start with / (use .file.path from a post)"; return 1 }
  [[ -z $out ]] && out=${rpath:t}
  local -a urls=("${PAWCHIVE_FILE_BASE}${rpath}" "${PAWCHIVE_THUMB_BASE}${rpath}")
  (( ${+o[--thumb]} )) && urls=("${PAWCHIVE_THUMB_BASE}${rpath}")
  local u
  for u in "${urls[@]}"; do
    if _pc_curl -fSL --retry 3 -sS -A "$PAWCHIVE_UA" \
         -H "Accept: $PAWCHIVE_IMG_ACCEPT" \
         -H 'Sec-Fetch-Dest: image' -H 'Sec-Fetch-Mode: no-cors' -H 'Sec-Fetch-Site: same-site' \
         -o "$out" "$u" 2>/dev/null; then
      print -- "saved $out"; return 0
    fi
  done
  rm -f -- "$out"; _pc_err "download failed: $rpath"; return 1
}

# Download the images of one post into ./<svc>_<id>_<post>/ in post order (001_, 002_, ...)
#   pawchive download-post <svc> <id> <post_id> [--thumb] [--all-files] [-d basedir]
# By default only png/jpg/jpeg/gif/webp are kept and duplicates are dropped
# (same filtering as the Mihon extension); --all-files grabs everything.
pawchive_download_post() {
  (( $+commands[jq] )) || { _pc_err "needs jq"; return 1 }
  local -A o; zparseopts -D -E -F -A o -- -thumb -all-files d: || return 1
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post_id "$3" || return 1
  local json; json=$(_pc_req GET "/$1/user/$2/post/$3") || { print -r -- "$json" >&2; return 1 }
  local dir="${o[-d]:-.}/${1}_${2}_${3}"; mkdir -p "$dir"
  local all=false; (( ${+o[--all-files]} )) && all=true
  local -a thumb=(); (( ${+o[--thumb]} )) && thumb=(--thumb)
  local rpath name i=0
  # handles both a bare post object and a {post: {...}} wrapper
  jq -r --argjson all "$all" '
    (.post // .) | [.file, (.attachments // [])[]]
    | map(select(. != null and (.path // "") != ""
                 and ($all or ((.preview_only | not) and (.path | test("\\.(png|jpe?g|gif|webp)$"; "i"))))))
    | reduce .[] as $f ([]; if any(.[]; .path == $f.path) then . else . + [$f] end)
    | .[] | "\(.path)\t\(.name // "")"' <<<"$json" |
  while IFS=$'\t' read -r rpath name; do
    (( i++ ))
    name=${name//\//_}
    pawchive_download "$rpath" "$dir/$(printf '%03d' $i)_${name:-${rpath:t}}" "${thumb[@]}"
    sleep "$PAWCHIVE_DELAY"
  done
}

# Download a post's non-video files (images, zips, ...) as <post_id>_<name>.
#   pawchive download-files <svc> <id> <post_id> [-d dir]
# Uses the API record: permanently stored files come from the file host, large ones from the
# short-lived signed links in attachments[].temp_download_url. Finished files are skipped,
# interrupted ones resume.
pawchive_download_files() {
  (( $+commands[jq] )) || { _pc_err "needs jq"; return 1 }
  local -A o; zparseopts -D -E -F -A o -- d: || return 1
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post_id "$3" || return 1
  local post=$3 dir=${o[-d]:-.} json list url name dest
  json=$(_pc_req GET "/$1/user/$2/post/$post") || { _pc_err "could not load post $post"; return 1 }
  list=$(jq -r --arg fb "$PAWCHIVE_FILE_BASE" '
    (.post // .) | [(.file // empty), (.attachments // [])[]]
    | map(select(type == "object" and ((.preview_only // false) | not)
                 and (((.path // "") != "") or ((.temp_download_url // "") != ""))
                 and (((.name // .path // "") | test("\\.(mp4|mkv|webm|mov|m4v)$"; "i")) | not)))
    | reduce .[] as $f ([]; if any(.[]; (.path // .temp_download_url) == ($f.path // $f.temp_download_url)) then . else . + [$f] end)
    | .[] | [ (if (.temp_download_url // "") != "" then .temp_download_url else $fb + .path end),
              (.name // (.path | split("/") | last)) ] | @tsv' <<<"$json")
  if [[ -z $list ]]; then
    # The API record has no file links (the archive lists some attachments by name only):
    # fall back to the links on the post's HTML page (thumbnails + "Download" links).
    local html hrc u n; html=$(_pc_html "$1" "$2" "$post"); hrc=$?
    if (( hrc == 0 )); then
      while read -r u; do
        [[ $u == /* ]] && u=${PAWCHIVE_SITE}$u
        n=${${u%%\?*}:t}
        if [[ $u == *[\?\&]f=* ]]; then n=${${u##*[?&]f=}%%&*}; n=${n//+/ }; n=$(printf '%b' "${n//\%/\\x}"); fi
        [[ ${(L)n} == *.(mp4|mkv|webm|mov|m4v) ]] && continue
        list+="${u}"$'\t'"${n}"$'\n'
      done < <(print -r -- "$html" | tr '\n' ' ' \
                 | grep -Eo 'class="(post__attachment-link|fileThumb)"[[:space:]]+href="[^"]+"' \
                 | sed -E 's/.*href="//; s/"$//; s/&amp;/\&/g' | awk '!seen[$0]++')
    fi
  fi
  [[ -z $list ]] && { _pc_err "post $post: no downloadable files (the archive may not have stored them)"; return 1 }
  mkdir -p "$dir"
  local rc=0
  while IFS=$'\t' read -r url name; do
    [[ -z $url ]] && continue
    name=${name//\//_}; dest="$dir/${post}_${name}"
    if [[ -s $dest ]]; then print -- "exists $dest"; continue; fi
    _pc_curl -fSL --retry 3 -C - -A "$PAWCHIVE_UA" -o "$dest.part" "$url" \
      && mv -- "$dest.part" "$dest" && print -- "saved $dest" || rc=1
  done <<<"$list"
  return $rc
}

# ---- videos / other relay-hosted media -------------------------------------
# Videos are NOT in the image paths the extension uses. The post's HTML page embeds
# short-lived *signed* URLs on t1.pawchive.pw (query has e=<expiry unix ts>&s=<signature>),
# so they must be scraped fresh from the page each time - they can't be built from a path.

_pc_html() {   # svc id post  (retries network failures; prints the page only on success)
  local out rc n
  for n in 1 2 3; do
    out=$(_pc_curl -sS --stderr /dev/null --fail-with-body --connect-timeout 20 -A "$PAWCHIVE_UA" \
            -H 'Accept: text/html' ${PAWCHIVE_COOKIE:+-H "Cookie: $PAWCHIVE_COOKIE"} \
            "${PAWCHIVE_SITE}/$1/user/$2/post/$3"); rc=$?
    (( rc == 0 || rc == 22 || rc == 127 )) && break
    (( n < 3 )) && { _pc_err "page fetch failed (curl exit $rc) - retrying ($n/2)..."; sleep $(( n * PAWCHIVE_RETRY_WAIT )); }
  done
  (( rc == 0 )) && print -r -- "$out"
  return $rc
}

# List signed media URLs of a post as "kind<TAB>url" (kind = file | hls).
#   pawchive media <svc> <id> <post_id>
# The API already returns them in attachments[].temp_download_url / .temp_url, so that is
# tried first (one small JSON call). If the API has none, the HTML page is scraped instead.
# The URLs are signed and short-lived (e=<expiry>) - always fetch them right before use.
pawchive_media() {
  _pc_seg service "$1" && _pc_seg creator_id "$2" && _pc_seg post_id "$3" || return 1
  local json out
  if (( $+commands[jq] )) && json=$(_pc_req GET "/$1/user/$2/post/$3" 2>/dev/null); then
    out=$(jq -r '(.post // .) | (.attachments // [])[]
                 | select((.temp_url // "") != "" or ((.name // "") | test("\\.(mp4|mkv|webm|mov|m4v)$"; "i")))
                 | (select(.temp_download_url) | "file\t" + .temp_download_url),
                   (select(.temp_url)          | "hls\t"  + .temp_url)' <<<"$json" 2>/dev/null)
    [[ -n $out ]] && { print -r -- "$out"; return 0 }
    # nothing archived, but the post embeds something (YouTube...): the HTML page has nothing
    # more to offer, so skip that big, flaky page and let the --embed handling take over
    [[ -n $(jq -r '(.post // .) | .embed.url // empty' <<<"$json" 2>/dev/null) ]] && return 0
  fi
  local html hrc; html=$(_pc_html "$1" "$2" "$3"); hrc=$?
  (( hrc == 0 )) || { _pc_err "could not load the page of post $3 (exit $hrc)"; return 1 }
  {
    print -r -- "$html" | grep -Eo 'class="post__attachment-link" href="[^"]+"' \
      | sed -E 's/.*href="//; s/"$//' | awk -v s="$PAWCHIVE_SITE" '{u=$0; if (u ~ /^\//) u=s u; print "file\t" u}'
    print -r -- "$html" | grep -Eo '<source src="[^"]+"' \
      | sed -E 's/<source src="//; s/"$//' | awk -v s="$PAWCHIVE_SITE" '{u=$0; if (u ~ /^\//) u=s u; print "hls\t" u}'
  } | sed 's/&amp;/\&/g'
}

# The embed URL (e.g. a YouTube link) the API reports for a post, if any
_pc_embed_url() {   # svc id post
  (( $+commands[jq] )) || return 1
  _pc_req GET "/$1/user/$2/post/$3" 2>/dev/null | jq -r '(.post // .) | .embed.url // empty' 2>/dev/null
}

# Download the video/attachment links of a post.
#   pawchive download-media <svc> <id> <post_id> [-d dir] [--hls]
# Default grabs the direct "Download" files (e.g. .mp4) as <post_id>_<name>.
# Safe to re-run: finished files are skipped, interrupted ones resume from <name>.part.
# --hls instead records the m3u8 stream to <post_id>.mp4 with ffmpeg (needs ffmpeg).
# Many posts have no archived video but embed a YouTube link (shown in the API's
# .embed.url); --embed falls back to yt-dlp for those (needs yt-dlp).
pawchive_download_media() {
  local -A o; zparseopts -D -E -F -A o -- -hls -embed d: || return 1
  local dir=${o[-d]:-.} want=file post=$3; mkdir -p "$dir"
  (( ${+o[--hls]} )) && want=hls
  local list; list=$(pawchive_media "$@") || return 1
  if [[ -z $list ]]; then
    local eurl; eurl=$(_pc_embed_url "$@")
    if [[ -n $eurl ]]; then
      if (( ${+o[--embed]} )); then
        (( $+commands[yt-dlp] )) || { _pc_err "--embed needs yt-dlp (Arch: sudo pacman -S yt-dlp)"; return 1 }
        local -a ytargs=(${(z)PAWCHIVE_YTDLP_ARGS})
        # yt-dlp enables only the 'deno' JS runtime by default (needed for YouTube's JS challenge);
        # if deno is missing but node is installed, switch node on
        (( ${#ytargs} == 0 && ! $+commands[deno] && $+commands[node] )) && ytargs=(--js-runtimes node)
        yt-dlp "${ytargs[@]}" --no-playlist -P "$dir" -o "${post}_%(title).150B [%(id)s].%(ext)s" "$eurl" && return 0
        _pc_err "yt-dlp failed. For 'HTTP Error 403': keep yt-dlp current and make sure a JS runtime it uses is available (it enables only deno by default; for node use PAWCHIVE_YTDLP_ARGS='--js-runtimes node'). Other options (cookies, -v) can go in PAWCHIVE_YTDLP_ARGS."
        return 1
      fi
      _pc_err "post $post: no archived video, but it embeds $eurl (re-run with --embed to fetch it via yt-dlp)"
      return 1
    fi
    _pc_err "post $post: no media links found (no video, not imported/blocked, or different markup)"
    return 1
  fi
  local kind url name dest legacy found=0
  while IFS=$'\t' read -r kind url; do
    [[ $kind == $want ]] || continue
    found=1
    if [[ $kind == file ]]; then
      name=${${url%%\?*}:t}; legacy="$dir/$name"   # older versions saved relay files unprefixed
      if [[ $url == *[\?\&]f=* ]]; then          # permanent files carry the real name in ?f=
        name=${${url##*[?&]f=}%%&*}; name=${name//+/ }; name=$(printf '%b' "${name//\%/\\x}"); legacy=""
      fi
      dest="$dir/${post}_${name//\//_}"
      if [[ -s $dest ]]; then print -- "exists $dest"; continue; fi
      if [[ -n $legacy && -s $legacy ]]; then print -- "exists $legacy"; continue; fi
      _pc_curl -fSL --retry 3 -C - -A "$PAWCHIVE_UA" -o "$dest.part" "$url" \
        && mv -- "$dest.part" "$dest" && print -- "saved $dest"
    else
      dest="$dir/${post}.mp4"
      if [[ -s $dest ]]; then print -- "exists $dest"; continue; fi
      (( $+commands[ffmpeg] )) || { _pc_err "--hls needs ffmpeg"; return 1 }
      ffmpeg -nostdin -loglevel error -stats -y -i "$url" -c copy "$dest" </dev/null \
        && print -- "saved $dest"
    fi
  done <<<"$list"
  (( found )) || _pc_err "post $post: no '$want' links on that page (try ${${want:#hls}:+--hls}${${want:#file}:+without --hls})"
}

# ------------------------------------------------------------------ fzf browser
# Interactive picker: creator -> posts (multi-select) -> action -> back to the posts.
#   pawchive browse [-s service] [-d root_dir] [--refresh] [query]
#   pawchive browse <service> <creator_id> [-d root_dir] [--refresh]   (skips the creator step)
# Needs fzf + jq. Files go to <root_dir>/<creator name>/ (default ~/Downloads/pawchive, or
# $PAWCHIVE_DL_DIR). Posts that are already downloaded there are marked with a check mark.

_pc_cache_dir() { print -r -- "${XDG_CACHE_HOME:-$HOME/.cache}/pawchive" }

# Helper scripts for fzf's preview pane + jq programs (written into $tmp, see pawchive_browse)
_pc_browse_write_helpers() {
  cat >| "$tmp/prev_creator.sh" <<'PCEOF'
#!/bin/sh
# $1 creators.json  $2 service  $3 id  $4 site
jq -r --arg svc "$2" --arg id "$3" --arg site "$4" '
  first(.[] | select(.id == $id and .service == $svc))
  | "\(.name)", "", "service:    \(.service)", "id:         \(.id)",
    "public id:  \(.public_id // "-")", "favorited:  \(.favorited // 0)",
    "imported:   \(.ever_imported // "?")", "", "\($site)/\(.service)/user/\(.id)"' "$1"
PCEOF
  cat >| "$tmp/prev_post.sh" <<'PCEOF'
#!/bin/sh
# $1 posts.json  $2 post id  $3 site
jq -r --arg id "$2" --arg site "$3" '
  def txt: (. // "")
    | gsub("<br\\s*/?>|</p>"; "\n") | gsub("<[^>]*>"; "")
    | gsub("&#x27;"; "\u0027") | gsub("&quot;"; "\"") | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&amp;"; "&");
  first(.[] | select(.id == $id))
  | (.title // ""),
    "published \(.published // "?")   edited \(.edited // "?")",
    "tags: \(.tags // "-")",
    "",
    ((.attachments // [])[] | "• \(.name // "?")" + (if .temp_expires then "   (temporary copy until \(.temp_expires[:10]))" else "" end)),
    (if (.embed.url // "") != "" then "▶ \(.embed.provider // "embed"): \(.embed.url)\n  \(.embed.subject // "")" else empty end),
    "",
    (.content | txt),
    "",
    "\($site)/\(.service)/user/\(.user)/post/\(.id)"' "$1"
PCEOF
  cat >| "$tmp/creators.jq" <<'PCEOF'
def d: try ((.updated | if type == "number" then floor | todate else tostring end) | .[:10]) catch "?";
[ .[] | select($svc == "" or .service == $svc) ] | sort_by(-(.favorited // 0)) | .[]
| [ .service, .id, .name,
    (.name + "  [" + .service + "]"
      + (if $det then "  ♥" + ((.favorited // 0) | tostring) + "  upd " + d else "" end)
      + (if .ever_imported == false then "  (not imported)" else "" end)) ]
| @tsv
PCEOF
  cat >| "$tmp/defs.jq" <<'PCEOF'
def vid: ((.name // .path // "") | test("\\.(mp4|mkv|webm|mov|m4v)$"; "i"));
def img: ((.name // .path // "") | test("\\.(png|jpe?g|gif|webp|bmp|avif)$"; "i"));
# a post's files, minus the preview thumbnail the archive attaches to video posts
def items: [(.file // empty), (.attachments // [])[]]
           | map(select(type == "object" and ((.preview_only // false) | not)
                        and (((.name // "") != "") or ((.path // "") != ""))));
def has_vid:   (items | any(vid));
def has_emb:   ((.embed.url // "") != "");
def has_img:   (items | any(img));
def has_other: (items | any((vid | not) and (img | not)));
def has_files: (items | any(vid | not));
PCEOF
  cat "$tmp/defs.jq" - >| "$tmp/lines.jq" <<'PCEOF'
def tags: ([ (if has_vid then "VID" else empty end), (if has_emb then "EMB" else empty end),
             (if has_img then "IMG" else empty end), (if has_other then "FILE" else empty end) ] | join(" "));
.[] | [ .id,
        ((.published // .added // "")[:10]) + "  " + ((tags + "                ")[:16]) + "  "
          + ((.title // "") | gsub("\\s+"; " ") | sub("^ "; "") | sub(" $"; "")),
        (first((.attachments // [])[] | select(.name) | .name) // "") ]
| @tsv
PCEOF
  cat "$tmp/defs.jq" - >| "$tmp/kinds.jq" <<'PCEOF'
.[] | select(.id as $i | ($ids | index($i)) != null)
| [ .id, (if has_vid then 1 else 0 end), (if has_emb then 1 else 0 end), (if has_files then 1 else 0 end) ] | @tsv
PCEOF
}

# Pick a creator. Sets $creator_line = service<TAB>id<TAB>name<TAB>display. rc!=0 on esc.
_pc_browse_pick_creator() {   # query service refresh
  local file; file=$(_pc_cache_dir)/creators.json
  _pc_creators_json ${3:+--refresh} >/dev/null || return 1
  local line det=false
  [[ -n $PAWCHIVE_BROWSE_DETAILS ]] && det=true     # likes + last-updated date in the list
  line=$(jq -r --arg svc "$2" --argjson det "$det" -f "$tmp/creators.jq" "$file" \
    | fzf --delimiter $'\t' --with-nth 4 --no-sort --query "$1" --prompt 'creator> ' \
          --header $'type to search · enter = open · esc = quit' \
          --preview "sh ${(q)tmp}/prev_creator.sh ${(q)file} {1} {2} ${(q)PAWCHIVE_SITE}" \
          --preview-window 'right,40%,wrap') || return 1
  creator_line=$line
}

# Load (cached) full post list for a creator into $tmp/posts.json
_pc_browse_load_posts() {   # service id refresh
  local cdir f out rc; cdir=$(_pc_cache_dir); f=$cdir/posts_${1}_${2}.json
  mkdir -p "$cdir"
  if [[ -z $3 && -s $f && -z $(find "$f" -mmin +"$PAWCHIVE_CACHE_MIN" 2>/dev/null) ]]; then
    cp -- "$f" "$tmp/posts.json"; return 0
  fi
  print -u2 -- "loading posts (big creators take a while; failed pages are retried)..."
  out=$(PAWCHIVE_ALLOW_PARTIAL=1 pawchive_user_posts "$1" "$2" --all); rc=$?
  (( rc == 0 || rc == 3 )) || return 1
  [[ $(jq -r 'type' <<<"$out" 2>/dev/null) == array ]] || { _pc_err "unexpected response while loading posts"; return 1 }
  if (( rc == 3 )); then      # partial: show what we have, but don't cache it
    print -r -- "$out" >| "$tmp/posts.json"
    _pc_err "showing a PARTIAL list (older posts missing, not cached) - leave and re-open to retry"
    sleep 2; return 0
  fi
  print -r -- "$out" >| "$f"; cp -- "$f" "$tmp/posts.json"
}

# "id<TAB>display" lines; posts already on disk get a check mark
_pc_browse_lines() {   # dir
  local dir=$1 id disp nm mark; local -a hit
  jq -r -f "$tmp/lines.jq" "$tmp/posts.json" | while IFS=$'\t' read -r id disp nm; do
    mark="  "; hit=(${(b)dir}/${id}_*(N[1]))
    if (( ${#hit} )) || [[ -n $nm && -s $dir/$nm ]]; then mark="✓ "; fi
    print -r -- "${id}"$'\t'"${mark}${disp}"
  done
}

# ---- mpv queue ---------------------------------------------------------------
# Selected posts become an m3u playlist: already-downloaded file if there is one, else the
# fresh signed HLS stream (PAWCHIVE_PLAY=file for the direct mp4 instead), else the YouTube
# embed (mpv uses yt-dlp for that). One long-lived mpv listens on an IPC socket, so further
# selections are appended to the SAME queue while it keeps playing.

_pc_mpv_sock() { print -r -- "${PAWCHIVE_MPV_SOCK:-${XDG_RUNTIME_DIR:-/tmp}/pawchive-mpv.sock}" }

# Send one JSON command to the queue mpv, print its reply. rc 1 = no instance, 2 = no tool.
_pc_mpv_ipc() {
  local sock; sock=$(_pc_mpv_sock); [[ -S $sock ]] || return 1
  if (( $+commands[socat] )); then
    print -r -- "$1" | timeout 3 socat -t1 - UNIX-CONNECT:"$sock" 2>/dev/null
  elif (( $+commands[python3] )); then
    python3 - "$sock" "$1" <<'PYEOF' 2>/dev/null
import socket, sys
s = socket.socket(socket.AF_UNIX); s.settimeout(3)
s.connect(sys.argv[1]); s.sendall((sys.argv[2] + "\n").encode())
buf = b""
while True:
    d = s.recv(4096)
    if not d: break
    buf += d
    if b'"error"' in buf: break
sys.stdout.write(buf.decode())
PYEOF
  else
    return 2
  fi
}

_pc_browse_play() {   # replace(0|1) service creator dir ids...
  local replace=$1 svc=$2 cid=$3 dir=$4; shift 4
  (( $+commands[mpv] )) || { _pc_err "mpv not found (Arch: sudo pacman -S mpv)"; return 1 }
  # the playlist must outlive this browse session (mpv may still be reading it), so it lives
  # in the cache dir, not in the throwaway $tmp; old ones are pruned after a day
  local qdir; qdir=$(_pc_cache_dir)/queues; mkdir -p "$qdir"
  find "$qdir" -name '*.m3u' -mmin +1440 -delete 2>/dev/null
  local m3u=$qdir/queue_$$_$RANDOM.m3u id title nm url media n=0 count=0 total=$#
  local -a loc
  print '#EXTM3U' >| "$m3u"
  for id in "$@"; do
    (( n++ )); print -u2 -- "resolving [$n/$total] post $id"
    title=$(jq -r --arg id "$id" 'first(.[] | select(.id == $id)
              | ((.published // "")[:10] + "  " + ((.title // "") | gsub("[\\r\\n]+"; " ")))) // $id' "$tmp/posts.json")
    nm=$(jq -r --arg id "$id" 'first(.[] | select(.id == $id) | (.attachments // [])[] | select(.name) | .name) // empty' "$tmp/posts.json")
    url=""
    loc=(${(b)dir}/${id}_*.(mp4|mkv|webm|mov|m4v)(N[1]))
    if (( ${#loc} )); then
      url=$loc[1]
    elif [[ -n $nm && -s $dir/$nm ]]; then
      url=$dir/$nm
    else
      media=$(pawchive_media "$svc" "$cid" "$id" 2>/dev/null)
      url=$(print -r -- "$media" | awk -F'\t' -v k="${PAWCHIVE_PLAY:-hls}" '$1 == k {print $2; exit}')
      [[ -z $url ]] && url=$(print -r -- "$media" | awk -F'\t' 'NF >= 2 {print $2; exit}')
      [[ -z $url ]] && url=$(_pc_embed_url "$svc" "$cid" "$id")
      sleep "$PAWCHIVE_DELAY"
    fi
    if [[ -z $url ]]; then _pc_err "post $id: nothing playable (no video, no embed)"; continue; fi
    print -r -- "#EXTINF:-1,$title" >> "$m3u"
    print -r -- "$url" >> "$m3u"
    (( count++ ))
  done
  (( count )) || return 1

  local sock; sock=$(_pc_mpv_sock)
  local -a mpvopts=(--user-agent="$PAWCHIVE_UA" --force-window=yes)
  if ! (( $+commands[socat] || $+commands[python3] )); then
    _pc_err "no socat/python3 for queue control - playing in a plain mpv (close it to come back)"
    mpv "${mpvopts[@]}" --playlist="$m3u"; return
  fi
  if (( replace )); then
    _pc_mpv_ipc '{"command":["quit"]}' >/dev/null 2>&1 && sleep 0.5
  elif _pc_mpv_ipc '{"command":["get_property","idle-active"]}' | grep -q '"error":"success"'; then
    if _pc_mpv_ipc "{\"command\":[\"loadlist\",\"$m3u\",\"append-play\"]}" | grep -q '"error":"success"'; then
      print -- "queued $count item(s) in the running mpv"
    else
      _pc_err "could not talk to the running mpv"; return 1
    fi
    return 0
  fi
  rm -f -- "$sock"
  mpv --no-terminal --idle=yes "${mpvopts[@]}" --input-ipc-server="$sock" --playlist="$m3u" >/dev/null 2>&1 &!
  print -- "mpv started with $count item(s). In mpv: < > = prev/next, F8 = playlist, q = quit."
  print -- "Pick more posts and choose 'Play in mpv' again to append to this queue."
}

# Run one action over the selected posts
_pc_browse_run() {   # action service creator dir ids...
  local act=$1 svc=$2 cid=$3 dir=$4; shift 4
  local id n=0 total=$#; local -a failed=()
  if [[ $act == fav && -z $PAWCHIVE_COOKIE ]]; then
    _pc_err "favoriting needs PAWCHIVE_COOKIE (your logged-in session cookie)"
  elif [[ $act == open ]] && (( total > 5 )) && ! read -q "?Open $total browser tabs? [y/N] "; then
    print
  elif [[ $act == play || $act == playnew ]]; then
    local rep=0; [[ $act == playnew ]] && rep=1
    _pc_browse_play $rep "$svc" "$cid" "$dir" "$@"
  else
    for id in "$@"; do
      (( n++ )); print -- "\n-- [$n/$total] post $id"
      case $act in
        vid)   pawchive_download_media "$svc" "$cid" "$id" -d "$dir" ;;
        vidyt) pawchive_download_media "$svc" "$cid" "$id" -d "$dir" --embed ;;
        files) pawchive_download_files "$svc" "$cid" "$id" -d "$dir" ;;
        urls)  pawchive_media "$svc" "$cid" "$id" ;;
        fav)   pawchive_fav_post add "$svc" "$cid" "$id" ;;
        open)  xdg-open "${PAWCHIVE_SITE}/$svc/user/$cid/post/$id" >/dev/null 2>&1 ;;
      esac || failed+=("$id")
      case $act in vid|vidyt|files) (( n < total )) && sleep "${PAWCHIVE_BATCH_DELAY:-2}" ;; esac
    done
    (( ${#failed} )) && print -- "\nfailed or skipped (${#failed}): ${failed[*]}"
  fi
  if [[ -t 0 ]]; then print -n "\nPress any key to go back... "; read -rs -k1; print; fi
}

# Post list for one creator (loops until esc)
_pc_browse_posts() {   # service id name refresh root
  local svc=$1 cid=$2 cname=$3 refresh=$4 root=$5
  _pc_browse_load_posts "$svc" "$cid" "$refresh" || { sleep 2; return 1 }
  if (( ! $(jq 'length' "$tmp/posts.json") )); then
    _pc_err "no posts found for $cname (not imported yet?)"; sleep 2; return 1
  fi
  local dir="$root/${${cname//\//_}:-${svc}_${cid}}"
  local out act lines idsjson pid v e f menu
  local -a ids vid_ids media_ids file_ids run_ids
  local hdr=$'TAB mark · ctrl-a all · ctrl-x none · alt-v/e/i/f = only VID/EMB/IMG/FILE · alt-c clear · enter · esc = back\n✓ downloaded   VID video   EMB YouTube/embed   IMG images   FILE zip/other'
  while true; do
    lines=$(_pc_browse_lines "$dir")
    out=$(print -r -- "$lines" | fzf --multi --exact --no-sort --delimiter $'\t' --with-nth 2 \
          --prompt "${cname}> " --header "$hdr" \
          --preview "sh ${(q)tmp}/prev_post.sh ${(q)tmp}/posts.json {1} ${(q)PAWCHIVE_SITE}" \
          --preview-window 'right,55%,wrap' \
          --bind 'ctrl-a:select-all,ctrl-x:deselect-all,alt-v:change-query(VID),alt-e:change-query(EMB),alt-i:change-query(IMG),alt-f:change-query(FILE),alt-c:clear-query') || return 0
    ids=(${${(f)out}%%$'\t'*})
    (( ${#ids} )) || continue

    # what the selected posts actually contain decides which actions are offered
    idsjson=$(jq -nc '$ARGS.positional' --args "${ids[@]}")
    vid_ids=() media_ids=() file_ids=()
    while IFS=$'\t' read -r pid v e f; do
      (( v )) && vid_ids+=($pid)
      (( v || e )) && media_ids+=($pid)
      (( f )) && file_ids+=($pid)
    done < <(jq -r --argjson ids "$idsjson" -f "$tmp/kinds.jq" "$tmp/posts.json")
    local nemb=$(( ${#media_ids} - ${#vid_ids} ))

    menu=""
    (( ${#media_ids} )) && menu+=$'play\tPlay in mpv (add to queue)\nplaynew\tPlay in mpv (replace the queue)\n'
    if   (( ${#vid_ids} && nemb )); then menu+=$'vidyt\tDownload videos (archived + YouTube embeds)\n'
    elif (( ${#vid_ids} ));         then menu+=$'vid\tDownload videos\n'
    elif (( nemb ));                then menu+=$'vidyt\tDownload embedded videos (YouTube etc. via yt-dlp)\n'
    fi
    (( ${#file_ids} )) && menu+=$'files\tDownload files (images, zips, ...)\n'
    menu+=$'open\tOpen in browser\n'
    (( ${#vid_ids} )) && menu+=$'urls\tPrint signed video URLs\n'
    [[ -n $PAWCHIVE_COOKIE ]] && menu+=$'fav\tAdd to favorites\n'
    menu+=$'back\t<- Back'

    act=$(print -r -- "$menu" | fzf --delimiter $'\t' --with-nth 2 --prompt "${#ids} post(s) > " \
          --height '~12' --reverse --header "-> $dir") || continue
    act=${act%%$'\t'*}
    case $act in
      back)          continue ;;
      play|playnew|vidyt) run_ids=("${media_ids[@]}") ;;
      vid|urls)      run_ids=("${vid_ids[@]}") ;;
      files)         run_ids=("${file_ids[@]}") ;;
      *)             run_ids=("${ids[@]}") ;;
    esac
    _pc_browse_run "$act" "$svc" "$cid" "$dir" "${run_ids[@]}"
  done
}

_pc_browse_main() {
  local -A o; zparseopts -D -E -F -A o -- s: d: -refresh || return 1
  local root=${o[-d]:-${PAWCHIVE_DL_DIR:-$HOME/Downloads/pawchive}}
  local refresh=""; (( ${+o[--refresh]} )) && refresh=1
  local svc cid cname query="" creator_line; local -a f
  _pc_browse_write_helpers
  if (( $# >= 2 )); then
    svc=$1 cid=$2
    cname=$(jq -r --arg svc "$svc" --arg id "$cid" 'first(.[] | select(.id == $id and .service == $svc) | .name) // empty' \
              "$(_pc_cache_dir)/creators.json" 2>/dev/null)
    _pc_browse_posts "$svc" "$cid" "${cname:-${svc}_${cid}}" "$refresh" "$root"
    return 0
  fi
  query=${1:-}
  while true; do
    _pc_browse_pick_creator "$query" "${o[-s]:-}" "$refresh" || return 0
    f=("${(@ps:\t:)creator_line}")
    svc=$f[1] cid=$f[2] cname=$f[3]
    _pc_browse_posts "$svc" "$cid" "$cname" "$refresh" "$root"
    refresh=""
  done
}

pawchive_browse() {
  (( $+commands[fzf] )) || { _pc_err "browse needs fzf (Arch: sudo pacman -S fzf)"; return 1 }
  (( $+commands[jq]  )) || { _pc_err "browse needs jq (Arch: sudo pacman -S jq)"; return 1 }
  local tmp; tmp=$(mktemp -d "${TMPDIR:-/tmp}/pawchive.XXXXXX") || return 1
  _pc_browse_main "$@"; local rc=$?
  rm -rf -- "$tmp"
  return $rc
}

# Fetch the live OpenAPI document
pawchive_schema() {
  _pc_curl -sS -A "$PAWCHIVE_UA" "${PAWCHIVE_BASE%/v1}/schema" | { [[ -t 1 ]] && jq . || cat }
}

# -------------------------------------------------------------- dispatcher

pawchive_help() {
  cat <<'EOF'
pawchive <command> [args]

Interactive (fzf)
  browse [-s svc] [-d dir] [--refresh] [query]   pick creator -> posts -> action
  browse <svc> <creator_id>                      jump straight to a creator

Scriptable commands

Posts
  creators [--refresh]                        list all creators (big, cached 30 min)
  creators-search [name] [-s svc] [--sort pop|new|lat|tit] [--limit N] [--refresh]
  posts [-q text] [-o N] [--all]              recent posts
  user-posts <svc> <id> [-q text] [-t tag]... [-o N] [--all]
  announcements <svc> <id>
  fancards <svc> <id>                         fanbox only
  post <svc> <id> <post_id>
  revisions <svc> <id> <post_id>
Creators
  profile <svc> <id>
  links <svc> <id>
  tags <svc> <id>
Comments
  comments <svc> <id> <post_id>
Flagging
  flag <svc> <id> <post_id>                   flag for re-import
  flag-status <svc> <id> <post_id>
Favorites (needs PAWCHIVE_COOKIE)
  favorites [artist|post]
  app-version
  fav-post    add|rm <svc> <id> <post_id>
  fav-creator add|rm <svc> <id>
Files
  hash <sha256>                               lookup file by hash
  download <path> [outfile] [--thumb]
  download-post <svc> <id> <post_id> [--thumb] [--all-files]   images
  download-files <svc> <id> <post_id> [-d dir]   images, zips, other non-video files
  media <svc> <id> <post_id>                  list signed video/attachment URLs (API, HTML fallback)
  download-media <svc> <id> <post_id> [-d dir] [--hls] [--embed]   videos/attachments
                                              (--embed: YouTube etc. via yt-dlp when nothing is archived)
Misc
  schema                                      dump the live OpenAPI doc
EOF
}

pawchive() {
  local cmd=${1:-help}; (( $# )) && shift
  case $cmd in
    creators)        pawchive_creators "$@" ;;
    creators-search|cs) pawchive_creators_search "$@" ;;
    posts)           pawchive_posts "$@" ;;
    user-posts|user) pawchive_user_posts "$@" ;;
    announcements)   pawchive_announcements "$@" ;;
    fancards)        pawchive_fancards "$@" ;;
    post)            pawchive_post "$@" ;;
    revisions)       pawchive_revisions "$@" ;;
    profile)         pawchive_profile "$@" ;;
    links)           pawchive_links "$@" ;;
    tags)            pawchive_tags "$@" ;;
    comments)        pawchive_comments "$@" ;;
    flag)            pawchive_flag "$@" ;;
    flag-status)     pawchive_flag_status "$@" ;;
    favorites)       pawchive_favorites "$@" ;;
    fav-post)        pawchive_fav_post "$@" ;;
    fav-creator)     pawchive_fav_creator "$@" ;;
    hash)            pawchive_hash "$@" ;;
    download)        pawchive_download "$@" ;;
    download-post)   pawchive_download_post "$@" ;;
    app-version)     pawchive_app_version "$@" ;;
    media)           pawchive_media "$@" ;;
    download-media|dm) pawchive_download_media "$@" ;;
    download-files|df) pawchive_download_files "$@" ;;
    browse|b)        pawchive_browse "$@" ;;
    schema)          pawchive_schema "$@" ;;
    help|-h|--help)  pawchive_help ;;
    *) _pc_err "unknown command '$cmd'"; pawchive_help >&2; return 1 ;;
  esac
}

# ------------------------------------------------------------- completion

_pawchive() {
  local -a cmds=(
    'creators:list all creators' 'creators-search:search cached creators' 'posts:recent posts' 'user-posts:posts by creator'
    'announcements:creator announcements' 'fancards:fanbox fancards' 'post:single post'
    'revisions:post revisions' 'profile:creator profile' 'links:linked accounts'
    'tags:creator tags' 'comments:post comments' 'flag:flag post for re-import'
    'flag-status:check flag' 'favorites:list favorites' 'fav-post:add/remove favorite post'
    'fav-creator:add/remove favorite creator' 'hash:lookup file by hash'
    'download:download a file' 'download-post:download all files of a post'
    'download-files:download images/zips/other files' 'media:list signed video URLs' 'download-media:download videos/attachments' 'app-version:backend version'
    'browse:interactive fzf picker' 'schema:dump OpenAPI doc' 'help:show help'
  )
  if (( CURRENT == 2 )); then
    _describe 'command' cmds
  elif [[ $words[2] == fav-(post|creator) && CURRENT == 3 ]]; then
    compadd add rm
  fi
}

[[ $_PC_ALIASES_WERE == on ]] && setopt aliases
unset _PC_ALIASES_WERE

# Sourced -> register completion. Executed -> run.
if [[ $ZSH_EVAL_CONTEXT == *:file* ]]; then
  (( $+functions[compdef] )) && compdef _pawchive pawchive
else
  pawchive "$@"
fi
