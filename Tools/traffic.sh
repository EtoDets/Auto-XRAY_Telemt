#!/bin/bash

_APISERVER=127.0.0.1:10185
_XRAY=/usr/local/bin/xray

# Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_RED='\033[38;5;203m'
C_GREEN='\033[38;5;83m'
C_BLUE='\033[38;5;75m'
C_CYAN='\033[38;5;87m'
C_YELLOW='\033[38;5;221m'
C_MAGENTA='\033[38;5;183m'
C_WHITE='\033[38;5;255m'
C_GRAY='\033[38;5;245m'

ARROW_UP="▲"
ARROW_DN="▼"
ARROW_TOTAL="◆"

apidata() {
    local ARGS=
    if [[ $1 == "reset" ]]; then
        ARGS="-reset=true"
    fi
    $_XRAY api statsquery --server=$_APISERVER "${ARGS}" \
    | awk '{
        if (match($1, /"name":/)) {
            f=1; gsub(/^"|link"|,$/, "", $2);
            split($2, p, ">>>");
            printf "%s:%s->%s\t", p[1],p[2],p[4];
        }
        else if (match($1, /"value":/) && f) {
            f=0;
            gsub(/"/, "", $2);
            printf "%.0f\n", $2;
        }
        else if (match($0, /}/) && f) { f=0; print 0; }
    }'
}

human_size() {
    local bytes=$1
    if   (( bytes >= 1073741824 )); then printf "%.2f GiB" "$(echo "scale=4; $bytes/1073741824" | bc)"
    elif (( bytes >= 1048576 ));    then printf "%.2f MiB" "$(echo "scale=4; $bytes/1048576" | bc)"
    elif (( bytes >= 1024 ));       then printf "%.2f KiB" "$(echo "scale=4; $bytes/1024" | bc)"
    else printf "%d B" "$bytes"
    fi
}

print_section() {
    local DATA="$1"
    local PREFIX="$2"
    local TITLE="$3"
    local COLOR="$4"

    local SORTED
    SORTED=$(echo "$DATA" | grep "^${PREFIX}" | sort -r)

    if [[ -z "$SORTED" ]]; then
        return
    fi

    local up_sum=0 down_sum=0

    # Header
    echo -e "${C_BOLD}${COLOR}  ${TITLE}${C_RESET}"
    echo -e "${C_GRAY}$(printf '%.0s─' {1..70})${C_RESET}"
    printf "${C_BOLD}${C_GRAY}  %-38s %10s  %10s  %12s${C_RESET}\n" \
        "Name" "Upload" "Download" "Total"
    echo -e "${C_GRAY}$(printf '%.0s─' {1..70})${C_RESET}"

    while IFS=$'\t' read -r name bytes; do
        [[ -z "$name" || -z "$bytes" ]] && continue

        local direction="${name##*->}"
        local label="${name%->*}"
        label="${label#${PREFIX}:}"

        # Accumulate for sum
        if [[ "$direction" == "up" ]]; then
            up_map["$label"]=$bytes
            (( up_sum += bytes ))
        elif [[ "$direction" == "down" ]]; then
            down_map["$label"]=$bytes
            (( down_sum += bytes ))
        fi
    done <<< "$SORTED"

    # Collect unique labels
    local all_labels=()
    for k in "${!up_map[@]}" "${!down_map[@]}"; do
        all_labels+=("$k")
    done
    # Deduplicate
    IFS=$'\n' read -rd '' -a all_labels < <(printf '%s\n' "${all_labels[@]}" | sort -u)

    for label in "${all_labels[@]}"; do
        local up_b=${up_map["$label"]:-0}
        local dn_b=${down_map["$label"]:-0}
        local total_b=$(( up_b + dn_b ))

        local up_h dn_h total_h
        up_h=$(human_size $up_b)
        dn_h=$(human_size $dn_b)
        total_h=$(human_size $total_b)

        printf "  ${COLOR}%-38s${C_RESET} ${C_GREEN}%10s${C_RESET}  ${C_RED}%10s${C_RESET}  ${C_CYAN}%12s${C_RESET}\n" \
            "$label" "$up_h" "$dn_h" "$total_h"
    done

    # Summary
    local total_sum=$(( up_sum + down_sum ))
    local up_h dn_h total_h
    up_h=$(human_size $up_sum)
    dn_h=$(human_size $down_sum)
    total_h=$(human_size $total_sum)

    echo -e "${C_GRAY}$(printf '%.0s─' {1..70})${C_RESET}"
    printf "  ${C_BOLD}${C_WHITE}%-38s ${C_GREEN}%10s${C_RESET}  ${C_RED}${C_BOLD}%10s${C_RESET}  ${C_CYAN}${C_BOLD}%12s${C_RESET}\n" \
        "TOTAL" "$up_h" "$dn_h" "$total_h"
    echo

    # Reset maps
    unset up_map down_map
    declare -gA up_map=()
    declare -gA down_map=()
}

# --- Main ---

clear

if [[ $1 == "reset" ]]; then
    echo -e "${C_YELLOW}${C_BOLD}  Resetting statistics...${C_RESET}\n"
fi

declare -A up_map=()
declare -A down_map=()

DATA=$(apidata "$1")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo
echo -e "${C_BOLD}${C_WHITE}  Xray Traffic Statistics${C_RESET}  ${C_DIM}${C_GRAY}${TIMESTAMP}${C_RESET}"
echo -e "${C_GRAY}$(printf '%.0s═' {1..70})${C_RESET}"
echo

print_section "$DATA" "inbound"  "Inbound"  "$C_BLUE"
print_section "$DATA" "outbound" "Outbound" "$C_MAGENTA"
print_section "$DATA" "user"     "Users"    "$C_YELLOW"