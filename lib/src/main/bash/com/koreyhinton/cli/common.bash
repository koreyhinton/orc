# Shared by the orc commands (sourced, not run). Not an orc command: it isn't
# executable, so "orc common" doesn't run it.

# orc_list_files <dir>: print the files under <dir> (as <dir>/...), one per
# line, sorted. In a git work tree it skips the folders .gitignore excludes
# (target/, node_modules/, ...) but keeps files it excludes one by one: those
# are often a build's outputs, such as a src/main.rs that build.sh generates,
# which orc must still see. Elsewhere it skips the usual build and dependency
# folders.
orc_list_files() {
    local dir=${1:-.}
    if git -C "${dir}" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        {
            git -C "${dir}" ls-files --cached --others --exclude-standard -z .
            # ignored files outside ignored folders (--directory lists an
            # ignored folder once, with a trailing /, instead of its files)
            git -C "${dir}" ls-files --others --ignored --exclude-standard --directory -z . \
                | while IFS= read -r -d '' path; do
                    [[ "${path}" != */ ]] && printf '%s\0' "${path}"
                done
        } | while IFS= read -r -d '' path; do
                [[ -f "${dir}/${path}" ]] && printf '%s\n' "${dir%/}/${path}"
            done | sed 's|^\./\./|./|' | sort -u
    else
        find "${dir}" \( -name .git -o -name target -o -name build -o -name node_modules \
            -o -name vendor -o -name dist -o -name out -o -name bin -o -name obj \
            -o -name .gradle -o -name .idea \) -prune -o -type f -print | sort
    fi
}

# a word ending in .sh, as a script path: ./x.sh, ${DIR}/x.sh, "x.sh"
ORC_SCRIPT='["'"'"']?[^[:space:]`#;|&()]*\.sh["'"'"']?([[:space:]]|$|[`;|&)])'

# A line that runs a script: a backtick call, $(...), a script path as a
# command's first word (at the start, or after ;, &&, || or |), or ., source,
# bash, sh or exec of one.
ORC_CALL=$(
    IFS='|'
    calls=(
        '`[[:space:]]*'"${ORC_SCRIPT}"
        '\$\([[:space:]]*'"${ORC_SCRIPT}"
        '^[[:space:]]*'"${ORC_SCRIPT}"
        '[;|&][[:space:]]*'"${ORC_SCRIPT}"
        '(^|[[:space:];|&(])(\.|source|bash|sh|exec)[[:space:]]+'"${ORC_SCRIPT}"
    )
    echo "${calls[*]}"
)

# orc_calls <file>: print "<line>:<text>" for each line of <file> that runs a
# script, skipping bash comment lines
orc_calls() {
    grep -nE "${ORC_CALL}" "$1" | grep -vE '^[0-9]+:[[:space:]]*#'
}

# orc_called_scripts <main.sh>: print the local scripts <main.sh> calls, as
# paths from its folder (./a.sh, lib/b.sh). Library calls through a variable
# (${ORC_WS}/snippets/read.sh) aren't local and aren't printed.
orc_called_scripts() {
    orc_calls "$1" | cut -d: -f2- \
        | grep -oE '(^|[[:space:]`"'"'"'(;|&])(\./)?[A-Za-z0-9_.][A-Za-z0-9_./-]*\.sh' \
        | sed -E 's/^[[:space:]`"'"'"'(;|&]//' | sort -u
}
