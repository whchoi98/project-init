#!/bin/bash
# PreToolUse (Bash) gate: block `git commit` when the files it will commit contain secrets.
# project-init:commit-scope -- the scan covers what the commit will contain, not only what is
# already staged: staged files (read from the index; renames and type changes included); modified
# tracked files for `commit -a`, `--all`, `-am`, or a pathspec (a glob such as '*.py' included); and,
# when the same command line runs `git add` or `git stage`, modified tracked plus untracked
# non-ignored files, and the ignored files that `add -f` names, taken from the directory that add
# runs in. That last case over-approximates on purpose; the block message names the file.
# It follows `cd`/`pushd` earlier on the line (with -L, -P, or --), `git -C`, and
# `--git-dir`/`--work-tree`, returns on `popd`, and leaves a closed `( ... )` where it entered it.
# Every `git commit` on the line is scanned, each in the directory and repository it runs in, so
# `git commit -m a && git commit -am b` scans what both would contain. A commit's own arguments,
# its message included, are not read as commands. Commits that would scan the same files are
# scanned once, and a line with more than MAX_SCANS different commits reports the rest as unscanned.
# Best effort: it reads the command text, so commits made by rebase, cherry-pick, am, merge, a git
# alias, or a script are not seen, and a directory given as a variable ($DIR) is not followed. The
# words `git commit` in other text, such as an echo string or a heredoc body, count as a commit,
# which only widens the scan.
# Input: the command as $1 (tests), else the event JSON on stdin (tool_input.command, cwd).
# Stdin is read only when no argument is given, so a test passing "" never blocks.
# Exit 2 blocks the tool call (ADR-008). Any other command exits 0 with no output.
# Patterns are matched with python3 `re`, because grep -P is missing on macOS and silently fails
# on some patterns. A commit that cannot be scanned (no working python3, a failed scan) goes
# through (fail open, ADR-008) with a warning in systemMessage for the user and additionalContext
# for Claude, because stderr from a hook that exits 0 reaches neither.
# /project-init:migrate-hooks carries custom PATTERNS and SKIP_PATTERNS entries over.

PATTERNS=(
    'AKIA[0-9A-Z]{16}'                           # AWS Access Key ID
    '(?i)aws_secret_access_key["\x27]?\s{0,5}[=:]\s{0,5}["\x27]?[A-Za-z0-9/+=]{40}' # AWS Secret Key
    'sk-[A-Za-z0-9]{20}T3BlbkFJ[A-Za-z0-9]{20}'  # OpenAI API Key (legacy)
    'sk-(proj|svcacct|admin)-[A-Za-z0-9_-]{40,}' # OpenAI project, service account, admin keys
    'sk-ant-[A-Za-z0-9_-]{80,}'                  # Anthropic API Key
    'ghp_[A-Za-z0-9]{36}'                        # GitHub Personal Access Token
    'gho_[A-Za-z0-9]{36}'                        # GitHub OAuth Token
    'github_pat_[A-Za-z0-9_]{82}'                # GitHub Fine-grained PAT
    'xoxb-[0-9]+-[A-Za-z0-9]+'                   # Slack Bot Token
    'xoxp-[0-9]+-[A-Za-z0-9]+'                   # Slack User Token
    'sk_live_[A-Za-z0-9]{24,}'                   # Stripe Secret Key
    'rk_live_[A-Za-z0-9]{24,}'                   # Stripe Restricted Key
    'AIza[A-Za-z0-9_-]{35}'                      # Google API Key
    'ya29\.[A-Za-z0-9_-]{50,}'                   # Google OAuth Token
    'DefaultEndpointsProtocol=https;Account'     # Azure Connection String
    '-----BEGIN ([A-Z]+ )?PRIVATE KEY( BLOCK)?-----' # PEM, OpenSSH, and PGP private keys
    # A quoted literal assigned to a password, secret, or API key name, in any case, JSON included.
    # A value starting with $ % { < is a reference (${VAR}, %(name)s, {{ ... }}, <placeholder>).
    # Unquoted values (DB_PASSWORD=x in .env) are left out: .env is gitignored, and unquoted
    # matches are mostly code (password = os.environ[...]).
    '(?i)passw(?:or)?d["\x27]?\s*[:=]\s*["\x27](?![$%{<])[^"\x27\n]{8,}'      # Password assignments
    '(?i)secret(?:[_-]?key)?["\x27]?\s*[:=]\s*["\x27](?![$%{<])[^"\x27\n]{8,}' # Secret assignments
    '(?i)api[_-]?key["\x27]?\s*[:=]\s*["\x27](?![$%{<])[^"\x27\n]{8,}'        # API key assignments
)

# Paths never scanned: bash globs against the repo-relative path, and against the path relative to
# the project when the project is a subdirectory of the repository (`*` also matches `/`).
# The first four hold pattern definitions and test samples by design. CLAUDE.md files are scanned
# even when a glob here matches them: they are committed, and Claude loads them every session.
SKIP_PATTERNS=(
    '*secret-scan.sh'
    'tests/hooks/test-secret-patterns.sh'
    'tests/fixtures/secret-samples.txt'
    'tests/fixtures/false-positives.txt'
    '*.md'
    '.env.example'
    '*package-lock.json'
    '*yarn.lock'
)

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
START_DIR="$PWD"   # where Claude Code started the hook; the cd/-C logic below moves away from it

# warn_unscanned <reason>: let the commit through, and say it was not scanned
warn_unscanned() {
    echo "[secret-scan] $1; this commit was not scanned for secrets." >&2
    printf '{"systemMessage": "[secret-scan] %s; this commit was not scanned for secrets.", "hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "[secret-scan] %s, so this commit was not scanned for secrets. Tell the user."}}\n' "$1" "$1"
    exit 0
}

# --- Read the command ---
CMD="${1:-}"
HOOK_CWD=""
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    RAW=$(cat)
    # Most Bash calls are not commits, so leave before starting python3 for them
    case "$RAW" in *commit*) ;; *) exit 0 ;; esac
    if command -v python3 >/dev/null 2>&1; then
        { IFS= read -r HOOK_CWD; CMD=$(cat); } < <(printf '%s' "$RAW" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print(d.get("cwd", ""))
print(d.get("tool_input", {}).get("command", ""))' 2>/dev/null)
    fi
    # A python3 that does not run, or JSON it cannot parse, leaves CMD empty. Match the raw event
    # instead, so a commit is still noticed and reported as unscanned below.
    [ -n "$CMD" ] || CMD="$RAW"
fi

# --- Gate only commits: `git commit`, `git -C dir commit`, `git -c k=v commit`, chained or not ---
# One shell word: unquoted characters, \x escapes, $(...), `...`, "...", and '...'. No bracket
# expression ends in a backslash, so a regex library that reads \ in brackets as an escape still
# compiles these.
SQ="'"
WORD='([^[:space:]"\;&|<>()`'"$SQ"']|\\.|\$\([^)]*\)|`[^`]*`|"([^\"]|\\.)*"|'"$SQ[^$SQ]*$SQ"')+'
LEADING_WORD_RE='^[[:space:]]*('"$WORD"')'
VALUE_FLAG_RE='^-[^mFCct]*[mFCct]$'   # -m, -am, -F, -C, -c, -t: the value is the next word
GIT_OPTS='([[:space:]]+(-[cC][[:space:]]+'"$WORD"'|--(git-dir|work-tree|namespace|config-env|exec-path|super-prefix)[[:space:]]+'"$WORD"'|--?[[:alnum:]]('"$WORD"')?))*'
COMMIT_RE='(^|[^[:alnum:]_.-])git'"$GIT_OPTS"'[[:space:]]+commit([^[:alnum:]_-]|$)'
ADD_RE='(^|[^[:alnum:]_.-])git'"$GIT_OPTS"'[[:space:]]+(add|stage)([^[:alnum:]_-]|$)'
# What moves the directory a later command runs in: a parenthesis (BASH_REMATCH[1]), popd ([4]), or
# cd/pushd ([6]) and its directory ([9]); -L, -P, -e, -@, and -- before the directory are options
DIR_RE='([()])|(^|[;&|{}'$'\n''])[[:space:]]*((popd)([^[:alnum:]_-]|$)|(cd|pushd)[[:space:]]+((-[LPe@]+|--)[[:space:]]+)*('"$WORD"'))'
# One argument word of a command, on the command's own line
OWN_WORD_RE='^[ '$'\t'']*('"$WORD"')'
# Text in which every quote is closed, so what follows it is not inside a quoted string
BALANCED_RE='^([^\"'"$SQ"']|\\.|"([^\"]|\\.)*"|'"$SQ[^$SQ]*$SQ"')*$'
MAX_SCANS=20   # different commits scanned per command line; more are reported as not scanned
[[ "$CMD" =~ $COMMIT_RE ]] || exit 0

# split_words <text>: set WORDS to the shell words at the start of <text>, up to the first
# control operator (; & | < > parentheses) or unbalanced quote
split_words() {
    local rest="$1"
    WORDS=()
    while [[ "$rest" =~ $LEADING_WORD_RE ]]; do
        WORDS+=("${BASH_REMATCH[1]}")
        rest="${rest:${#BASH_REMATCH[0]}}"
    done
}
# args_after <text> <match>: the text after <match>, including the one character the regex took
args_after() {
    local after="${1#*"$2"}"
    case "$2" in
        *[[:alnum:]]) ;;
        *) after="${2#"${2%?}"}$after" ;;
    esac
    printf '%s' "$after"
}
# unquote <word>: the word without quotes or backslashes, with a leading ~ expanded; fails for a
# word with $ or `, whose value the hook cannot know
unquote() {
    local w="$1"
    case "$w" in *'$'*|*'`'*) return 1 ;; esac
    w="${w//\"/}"; w="${w//\'/}"; w="${w//\\/}"
    case "$w" in "~") w="$HOME" ;; "~/"*) w="$HOME/${w#\~/}" ;; esac
    printf '%s' "$w"
}
# chdir <word>: follow one cd or -C target
UNRESOLVED=false
chdir() {
    local dir
    dir=$(unquote "$1") || { UNRESOLVED=true; return 0; }
    cd "$dir" >/dev/null 2>&1 || true
}
# follow_cd <text>: end in the directory a command after <text> runs in. It follows every cd and
# pushd in order, returns on popd, and leaves a closed ( ... ) or $( ... ) where it entered it.
follow_cd() {
    local text="$1" paren verb dir n
    local entered=() marks=() pushed=()   # per open parenthesis: directory and pushd depth; pushd stack
    while [[ "$text" =~ $DIR_RE ]]; do
        paren="${BASH_REMATCH[1]}"; verb="${BASH_REMATCH[4]}${BASH_REMATCH[6]}"; dir="${BASH_REMATCH[9]}"
        text="${text#*"${BASH_REMATCH[0]}"}"
        case "$paren$verb" in
            "(") entered+=("$PWD"); marks+=("${#pushed[@]}") ;;
            ")")
                n=${#entered[@]}
                [ "$n" -gt 0 ] || continue
                cd "${entered[$((n - 1))]}" >/dev/null 2>&1 || true
                while [ "${#pushed[@]}" -gt "${marks[$((n - 1))]}" ]; do unset "pushed[$((${#pushed[@]} - 1))]"; done
                unset "entered[$((n - 1))]" "marks[$((n - 1))]" ;;
            popd)
                n=${#pushed[@]}
                [ "$n" -gt 0 ] || continue
                cd "${pushed[$((n - 1))]}" >/dev/null 2>&1 || true
                unset "pushed[$((n - 1))]" ;;
            pushd) pushed+=("$PWD"); chdir "$dir" ;;
            cd) chdir "$dir" ;;
        esac
    done
}
# own_args <text after a command name>: set OWN to the command's argument words, which end at an
# unquoted newline or control operator
own_args() {
    local rest="$1"
    OWN=""
    while [[ "$rest" =~ $OWN_WORD_RE ]]; do
        OWN="$OWN${BASH_REMATCH[0]}"
        rest="${rest:${#BASH_REMATCH[0]}}"
    done
}

# add_directory <text before the add> <add match>: print the directory `git add` runs in: Claude's
# cwd, then the cd/pushd before it on the line, then its own -C. A subshell, so the hook stays put.
add_directory() (
    cd "${HOOK_CWD:-$START_DIR}" 2>/dev/null || cd "$START_DIR" 2>/dev/null
    follow_cd "$1"
    split_words "${2#*git}"
    i=0
    while [ "$i" -lt "${#WORDS[@]}" ]; do
        case "${WORDS[$i]}" in
            -C) chdir "${WORDS[$((i + 1))]:-}"; i=$((i + 1)) ;;
            -c|--git-dir|--work-tree|--namespace|--config-env|--exec-path|--super-prefix) i=$((i + 1)) ;;
        esac
        i=$((i + 1))
    done
    pwd -P
)

# `git add`/`git stage` anywhere on the line: stage everything it could, and for `add -f` also the
# ignored files it names (every ignored file when it names none)
ADDS=false
FORCED=()   # absolute paths, since each add may run in its own directory
FORCE_ALL=false
rest="$CMD"
while [[ "$rest" =~ $ADD_RE ]]; do
    ADDS=true
    add_match="${BASH_REMATCH[0]}"
    before="${CMD%"$rest"}${rest%%"$add_match"*}"
    split_words "$(args_after "$rest" "$add_match")"
    rest="${rest#*"$add_match"}"
    force=false
    add_paths=()
    for word in "${WORDS[@]}"; do
        plain="${word//\"/}"; plain="${plain//\'/}"
        case "$plain" in
            --force) force=true ;;
            --*) ;;
            -*f*) force=true ;;
            -*) ;;
            *) path=$(unquote "$word") && add_paths+=("$path") ;;
        esac
    done
    if $force && [ ${#add_paths[@]} -eq 0 ]; then
        FORCE_ALL=true
    elif $force; then
        add_dir=$(add_directory "$before" "$add_match")
        for path in "${add_paths[@]}"; do
            case "$path" in /*) FORCED+=("$path") ;; *) FORCED+=("$add_dir/$path") ;; esac
        done
    fi
done

# The functions below run inside scan_commit, which sets PREFIX, SCAN_TRACKED, PATHSPECS, and
# COMMIT_DIR for one commit.
# skipped <path>: whether SKIP_PATTERNS excludes <path>
skipped() {
    local pattern
    case "$1" in CLAUDE.md|*/CLAUDE.md) return 1 ;; esac
    for pattern in "${SKIP_PATTERNS[@]}"; do
        [[ "$1" == $pattern || "${1#"$PREFIX"}" == $pattern ]] && return 0
    done
    return 1
}
# tag <I|W>: read NUL-separated paths; print "I <path>" (index copy) or "W <path>" (working tree),
# NUL-separated, for each path not skipped. NUL separation keeps names with quotes, tabs, or
# newlines intact, which git would otherwise print quoted.
tag() {
    local file
    while IFS= read -r -d '' file; do
        skipped "$file" || printf '%s %s\0' "$1" "$file"
    done
}
# --diff-filter=d keeps everything but deletions: added, modified, renamed, type-changed, copied
scan_list() {
    git diff -z --cached --name-only --diff-filter=d 2>/dev/null | tag I
    if $SCAN_TRACKED; then
        git diff -z --name-only --diff-filter=d 2>/dev/null | tag W
    fi
    # One git call per path, so a path outside the repository (a fatal error) drops only itself
    for spec in "${PATHSPECS[@]}"; do
        git -C "$COMMIT_DIR" diff -z --name-only --diff-filter=d -- "$spec" 2>/dev/null | tag W
    done
    if $ADDS; then
        git ls-files -z --others --exclude-standard 2>/dev/null | tag W
    fi
    if $FORCE_ALL; then
        git ls-files -z --others --ignored --exclude-standard 2>/dev/null | tag W
    else
        for spec in "${FORCED[@]}"; do
            git -C "$COMMIT_DIR" ls-files -z --full-name --others --ignored --exclude-standard \
                -- "$spec" 2>/dev/null | tag W
        done
    fi
}

# unscanned <reason>: end scan_commit with status 3; the reason is the last line it prints
unscanned() {
    echo "$1" >&2
    exit 3
}

# scan_commit <text before the commit> <commit match> <its arguments>: scan what one `git commit`
# would contain. It runs in a subshell, because each commit on the line may run in its own directory
# and repository. Exit status: 0 nothing found, 2 a secret found, 3 the commit could not be scanned,
# 4 an earlier commit on the line already scanned the same files.
scan_commit() (
    # --- Run git where the commit will run: Claude's cwd, earlier cd/pushd, then -C/--git-dir ---
    [ -n "$HOOK_CWD" ] && cd "$HOOK_CWD" 2>/dev/null
    follow_cd "$1"
    split_words "${2#*git}"
    LOCATIONS=()   # --git-dir=<dir> and --work-tree=<dir>
    i=0
    while [ "$i" -lt "${#WORDS[@]}" ]; do
        next="${WORDS[$((i + 1))]:-}"
        case "${WORDS[$i]}" in
            -C) chdir "$next"; i=$((i + 1)) ;;
            --git-dir|--work-tree) LOCATIONS+=("${WORDS[$i]}=$next"); i=$((i + 1)) ;;
            --git-dir=*|--work-tree=*) LOCATIONS+=("${WORDS[$i]}") ;;
            -c|--namespace|--config-env|--exec-path|--super-prefix) i=$((i + 1)) ;;
        esac
        i=$((i + 1))
    done
    # git resolves them after every -C, so make them absolute from here
    for location in "${LOCATIONS[@]}"; do
        if dir=$(unquote "${location#*=}") && dir=$(cd "$dir" 2>/dev/null && pwd); then
            case "$location" in --git-dir=*) export GIT_DIR="$dir" ;; *) export GIT_WORK_TREE="$dir" ;; esac
        else
            UNRESOLVED=true
        fi
    done

    # --- Work out what the commit will contain ---
    split_words "$3"
    SCAN_TRACKED=$ADDS
    PATHSPECS=()
    value_next=false
    paths_only=false
    for word in "${WORDS[@]}"; do
        if $value_next; then value_next=false; continue; fi
        plain="${word//\"/}"; plain="${plain//\'/}"
        if ! $paths_only; then
            case "$plain" in
                --) paths_only=true; continue ;;
                --all) SCAN_TRACKED=true; continue ;;
                --message|--file|--reuse-message|--reedit-message|--template|--author|--date|--cleanup|--trailer|--fixup|--squash)
                    value_next=true; continue ;;
                --*) continue ;;
                -*)
                    case "$plain" in -*a*) SCAN_TRACKED=true ;; esac
                    [[ "$plain" =~ $VALUE_FLAG_RE ]] && value_next=true
                    continue ;;
            esac
        fi
        # a path that exists, or a glob, quoted or not: as a pathspec it covers what the shell expands
        path=$(unquote "$word") && { [ -e "$path" ] || case "$path" in *[*?[]*) true ;; *) false ;; esac; } &&
            PATHSPECS+=("$path")
    done

    # A commit that would scan the same files as an earlier one on the line is not scanned again.
    # The first line printed is that key; the caller records it.
    key="$PWD|${GIT_DIR:-}|${GIT_WORK_TREE:-}|$UNRESOLVED|$SCAN_TRACKED|${PATHSPECS[*]}"
    key="${key//$'\n'/ }"
    case "$KEYS" in *$'\n'"$key"$'\n'*) exit 4 ;; esac
    printf '%s\n' "$key"
    [ "$SCANS" -lt "$MAX_SCANS" ] || unscanned "more than $MAX_SCANS different git commit commands on one line"
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        $UNRESOLVED && unscanned "could not find the repository this commit runs in"
        exit 0
    fi

    # Pathspecs are relative to this directory; git diff prints repo-relative paths from anywhere.
    COMMIT_DIR="$PWD"
    cd "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || exit 0
    PREFIX=""   # the project's path inside the repository, when it is a subdirectory
    [ "$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)" = "$PWD" ] &&
        PREFIX=$(git -C "$ROOT" rev-parse --show-prefix 2>/dev/null)

    if ! python3 -c '' >/dev/null 2>&1; then
        [ -n "$(scan_list | tr '\000' '\n')" ] && unscanned "python3 is not available"
        exit 0
    fi

    # --- Scan ---
    scan_list | python3 -c '
import re, subprocess, sys

rules = []
for pattern in sys.argv[1:]:
    try:
        rules.append((pattern, re.compile(pattern)))
    except re.error as err:
        sys.stderr.write("[secret-scan] skipped invalid pattern %s: %s\n" % (pattern[:30], err))

# Index copies come from one `git cat-file --batch` process, not one `git show` per file.
index, batch = None, None
def staged(path):
    global index, batch
    if index is None:
        listing = subprocess.run(["git", "ls-files", "-s", "-z"], stdout=subprocess.PIPE,
                                 stderr=subprocess.DEVNULL).stdout
        index = {}
        for record in listing.split(b"\0"):
            info, _, name = record.partition(b"\t")
            fields = info.split()
            if len(fields) == 3 and fields[2] == b"0":
                index[name] = fields[1]
        batch = subprocess.Popen(["git", "cat-file", "--batch"], stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    oid = index.get(path)
    if oid is None:
        return b""
    batch.stdin.write(oid + b"\n")
    batch.stdin.flush()
    header = batch.stdout.readline().split()
    if len(header) != 3:
        return b""  # "<oid> missing", such as a submodule commit
    data = batch.stdout.read(int(header[2]))
    batch.stdout.read(1)
    return data

found = False
seen = set()
for entry in sys.stdin.buffer.read().split(b"\0"):
    if not entry or entry in seen:
        continue
    seen.add(entry)
    source, path = entry[:1], entry[2:]
    if source == b"I":
        data = staged(path)
    else:
        try:
            with open(path, "rb") as handle:
                data = handle.read()
        except OSError:
            continue
    if b"\0" in data[:8192]:
        continue  # binary file
    text = data.decode("utf-8", "replace")
    for pattern, rule in rules:
        if rule.search(text):
            sys.stderr.write("[secret-scan] Potential secret in %s (pattern: %s...)\n"
                             % (path.decode("utf-8", "replace"), pattern[:30]))
            found = True
sys.exit(2 if found else 0)
' "${PATTERNS[@]}"
    rc=$?
    [ "$rc" -eq 0 ] || [ "$rc" -eq 2 ] || unscanned "the scan failed (rc=$rc)"
    exit "$rc"
)

# --- Scan every `git commit` on the line ---
BLOCKED=false
UNSCANNED=""    # why the first commit that could not be scanned was not
KEYS=$'\n'      # one line per commit scanned so far (scan_commit's key)
SCANS=0
SEEN=$'\n'      # report lines printed so far, each with its commit's directory
rest="$CMD"
trail=""        # the text before $rest, without the arguments of the commits found in it
while [[ "$rest" =~ $COMMIT_RE ]]; do
    commit_match="${BASH_REMATCH[0]}"
    lead="${rest%%"$commit_match"*}"
    quoted="${CMD%"$rest"}$lead${commit_match%%git*}"   # everything up to the word git
    rest="${rest#*"$commit_match"}"
    # The commit's flags, message, and pathspecs: the words up to the end of its command. A match
    # that ends in anything but a blank (an operator, a newline, the end of the text) has none.
    OWN=""
    case "$commit_match" in *[[:blank:]]) own_args "$rest" ;; esac
    # cd and parentheses are followed in $trail, so an earlier commit's message is not read as commands
    report=$(scan_commit "$trail$lead" "$commit_match" "$OWN" 2>&1)
    status=$?
    trail="$trail$lead$commit_match"
    # The arguments of a commit outside every quoted string are not searched for another commit.
    # Inside a quoted string the quotes pair the other way round, so nothing is skipped there.
    [[ "$quoted" =~ $BALANCED_RE ]] && rest="${rest:${#OWN}}"
    [ "$status" -eq 4 ] && continue
    key="${report%%$'\n'*}"
    KEYS="$KEYS$key"$'\n'
    SCANS=$((SCANS + 1))
    case "$report" in *$'\n'*) report="${report#*$'\n'}" ;; *) report="" ;; esac
    case "$status" in
        0) ;;
        2) BLOCKED=true ;;
        3) [ -n "$UNSCANNED" ] || UNSCANNED="${report##*$'\n'}"
           report="${report%"${report##*$'\n'}"}" ;;
        *) [ -n "$UNSCANNED" ] || UNSCANNED="the scan stopped (status $status)" ;;
    esac
    # Chained commits share the index, so two of them can report the same file: print a line once
    # per directory the commits run in
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        case "$SEEN" in *$'\n'"${key%%|*}|$line"$'\n'*) continue ;; esac
        SEEN="$SEEN${key%%|*}|$line"$'\n'
        printf '%s\n' "$line" >&2
    done <<< "$report"
done

if $BLOCKED; then
    echo "[secret-scan] BLOCKED: move the secret to .env (.env.example is the template) and retry. If a match is a false positive (a pattern definition or test fixture), tell the user the file and pattern instead of rewording the commit." >&2
    exit 2
fi
[ -n "$UNSCANNED" ] && warn_unscanned "$UNSCANNED"
exit 0
