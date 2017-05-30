#!/bin/bash
#
# Functions

report()
{
    echo "$@" >> ./report.log
    echo "Deploy) $@"
}


countdown()
{
  IFS=:
  set -- $*
  echo -e '\E[37;41m'"\033[1m ! ! ! Press CTRL-C to Abort ! ! ! \033[0m"
  case "$#" in
    0)
        echo "Usage: $0 days hrs secs"; exit
    ;;
    1)
        secs=$1;
    ;;
    2)
        secs=$(( ${2#0} * 60 + ${3#0} ));
    ;;
    3)
        secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ));
    ;;
  esac

  while [ $secs -gt 0 ]
  do
    sleep 1 &
    printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
    secs=$(( $secs - 1 ))
    wait
  done
  echo
}

echo_success() 
{
    echo -e '[\E[37;32m'"\033[1m OK \033[0m]"
}
echo_failure()
{
    echo -e '[\E[37;31m'"\033[1m FAILED \033[0m]"
}
failout()
{
    echo
    echo -e '\E[37;41m'"\033[1m !  !  !  !  !  !  ! $@ !  !  !  !  !  !  ! \033[0m"
    echo
    exit 1
}

declare -a ELIST
ELIST=()
function elist()
{
  case "$1" in
    'a') ELIST=("${ELIST[@]} $2");;
    'c') ELIST=();;
    'n') echo "${#ELIST[@]}";;
    *) echo "${ELIST[@]}";;
  esac
}

msg() { printf '%s\n' "$@"; }
err() { printf '%s\n' "$@" >&2; }

# Credit to https://stackoverflow.com/users/68587/john-kugelman
# Example:
#     step "Remounting / and /boot as read-write:"
#     try mount -o remount,rw /
#     try mount -o remount,rw /boot
#     next
step() {
    echo -n "$@"

    STEP_OK=0
    [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
}

try() {
    # Check for `-b' argument to run command in the background.
    local BG=

    [[ $1 == -b ]] && { BG=1; shift; }
    [[ $1 == -- ]] && {       shift; }

    # Run the command.
    if [[ -z $BG ]]; then
        "$@"
    else
        "$@" &
    fi

    # Check if command failed and update $STEP_OK if so.
    local EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
        STEP_OK=$EXIT_CODE
        [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$

        if [[ -n $LOG_STEPS ]]; then
            local FILE=$(readlink -m "${BASH_SOURCE[1]}")
            local LINE=${BASH_LINENO[0]}

            echo "$FILE: line $LINE: Command \`$*' failed with exit code $EXIT_CODE." >> "$LOG_STEPS"
        fi
    fi

    return $EXIT_CODE
}

next() {
    [[ -f /tmp/step.$$ ]] && { STEP_OK=$(< /tmp/step.$$); rm -f /tmp/step.$$; }
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo
    return $STEP_OK
}

# Requires BASH 4+
function require()
{
    TOTAL=0
    local REQS
    local RCHK
    declare -A REQS=()
    declare -A RCHK=()
    declare -A _LOADED_=()
    IN="$(echo -e "$@" | tr -d '[:space:]')"
    IFS=';' read -r -a REQS <<< "$IN"
    # Load files from array
    step "Loading required sources: "
    for FILE in "${REQS[@]}"; do
        NAME=$(echo "${FILE^}" | cut -d'.' -f1)
        RCHK=("${RCHK}" "${NAME}")
        TOTAL+=1
        try source "${FILE}"
    done
    next

    # Rudimentary sanity check
    for CHK in "${RCHK}"; do
        TOTAL-=$(echo "${_LOADED_[$CHK]}")
    done
    
    if [[ ${TOTAL} -gt 0 ]]; then failout "Missing required sources!"; else return 0; fi
}

function pkgdeps()
{
    local DEPS 
    local DEP 
    local NEED
    declare -A DEPS=()
    declare -A NEED=()
    IN="$(echo -e "$@" | tr -d '[:space:]')"
    IFS=';' read -r -a DEPS <<< "$IN"

    # Check for missing deps from array
    echo "Checking for missing dependencies..."
    for DEP in "${DEPS[@]}"; do
        step "Checking for ${DEP} : "
        try hash "${DEP}" 2>/dev/null; if [[ $? -eq 1 ]]; then elist a "${DEP}"; return 1; else return 0; fi;  
        next
    done

    if [[ $(elist n) -gt 0 ]]; then
        # Install
        LIST=$(elist)
        step "Installaing missing packages ${LIST} :"
        try apt-get update
        try apt-get install "${LIST}" --force-yes; if [[ $? -eq 1 ]]; then failout "Could not install required deps"; else return 0; fi
        next
    fi  
}












# Source Check 
$_LOADED_FUNCTS=1
