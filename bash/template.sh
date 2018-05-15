#!/usr/bin/env bash

# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>

set -euo pipefail
IFS=$'\n\t'

################################################################################
# Automatic/Default parameters
PROGRAM_DIRECTORY="$(cd "$(dirname "$0")"; pwd;)"
PROGRAM_NAME="$0"

################################################################################
# User parameters
VERBOSE=0
REMOTE_USER=""
REMOTE_HOST=""
OUTFILE="/dev/stdout"
INFILE="/dev/stdin"

################################################################################
# Helpers

print_usage() {
cat<<EOF

 Script used to setup the host used to drive the tests running on the node.

 Usage: ${PROGRAM_NAME} [-v] -r <ip> -u <username> [-P <password>] [-o OUTFILE] [-h] [INFILE]

If no INFILE specified, it will read from stdin

 OPTIONS:
 -v             Increase verbosity
 -r <ip>        The remote host name or IP address.
 -u <username>  The remote username.
 -P <password>  The remote password. Optional.
 -o             Output file (default: stdout)
 -h             Print this help and exit.

EOF
}

readonly LOG_FILE="/tmp/$(basename "$0").log"
print_debug()   { if [[ ${VERBOSE} -gt 1 ]]; then echo "[DEBUG]   $@" | tee -a "$LOG_FILE" >&2 ; fi }
print_info()    { if [[ ${VERBOSE} -gt 0 ]]; then echo "[INFO]    $@" | tee -a "$LOG_FILE" >&2 ; fi }
print_warn()    { echo "[WARNING] $@" | tee -a "$LOG_FILE" >&2 ; }
print_err()     { echo "[ERROR]   $@" | tee -a "$LOG_FILE" >&2 ; }
print_fatal()   { echo "[FATAL]   $@" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }


################################################################################
# output to ${OUTFILE}
# Arguments:
#     $@ output
# Return:
#     none
print_output()  {
    echo "$@" >> ${OUTFILE}
}


################################################################################
# ask for user confirmation
# Arguments:
#     $1 (optional) message
# Return:
#     0 on user replying "yes", else user replied "no"
confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
} 


################################################################################
# cleanup on exit
cleanup() {
    # Remove temporary files
    # Restart services
    # ...

    print_debug "cleanup"
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    trap cleanup EXIT

    ################################################################################
    # Options parser
    while getopts ":vr:u:P:o:h" opt; do
        case $opt in
            v)  
                VERBOSE=$(( VERBOSE + 1 ))
                ;;
            r)
                REMOTE_HOST="${OPTARG}"
                ;;
            u)
                REMOTE_USER="${OPTARG}"
                ;;
            P)
                REMOTE_PASSWORD="${OPTARG}"
                ;;
            o)
                OUTFILE="${OPTARG}"
                ;;
            h)
                print_usage
                exit 1
                ;;
            \?)
                print_err "Invalid option: -${OPTARG}"
                exit 1
                ;;
            :)
                print_err "Option -${OPTARG} requires an argument."
                exit 1
                ;;
        esac
    done

    shift $((OPTIND-1))

    # expect one (optional) extra arguments
    if [ $# -gt 1 ]; then
        print_usage
        exit 1
    fi

    INFILE="${1:-/dev/stdin}"

    [ -n "${REMOTE_HOST}"       ] || { print_err "Please specify option -r"; print_usage; exit 1; }
    [ -n "${REMOTE_USER}"       ] || { print_err "Please specify option -u"; print_usage; exit 1; }
    [ -n "${REMOTE_PASSWORD:-}" ] || { print_err "Please specify option -P or set REMOTE_PASSWORD variable in the environment"; print_usage; exit 1; }

    ################################################################################
    # Main
    # ...

    print_info "Processing ${INFILE} to ${OUTFILE}"
    print_info "Host: ${REMOTE_HOST}"
    print_info "User: ${REMOTE_USER}"


    while read -r line
    do
        print_output "> ${line}"
    done < "${INFILE}"

fi

