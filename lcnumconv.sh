#!/usr/bin/env bash
# lcnumconv
read -r lcnumconv_description <<EOF
lcnumconv.sh is a Bash library and a stand-alone command
for numbers format conversion between locales.
EOF

lcnumconv_author='Copyright © 2019 Léa Gris <lea.gris@noiraude.net>'
lcnumconv_date='Sat, 04 Apr 2020'
lcnumconv_version='1.2.3'
read -r lcnumconv_license <<EOF
This program is free software.
It comes without any warranty, to the extent permitted by applicable law.
You can redistribute it and/or modify it under the terms of the Do What
The Fuck You Want To Public License, Version 2, as published by Sam Hocevar.
See: http://www.wtfpl.net/ for more details.
EOF

lcnumconv::l2l() {
  # Convert numbers from the source locale to the destination locale
  # $1: The source locale
  # $2: The destination locale
  # $@|<&1: The numbers to convert
  # >&1: The converted numbers
  if [[ $# -lt 2 ]]; then
    printf >&2 'Missing locales parameters\n'
    return 1
  fi

  local -r in_lc="${1}"
  if ! lcnumconv::lck "${in_lc}"; then
    printf >&2 'The source locale %s is not available to this system.\n' \
      "${in_lc}"
    return 3
  fi
  shift

  local -r out_lc="${1}"
  if ! lcnumconv::lck "${out_lc}"; then
    printf >&2 'The destination locale %s is not available to this system.\n' \
      "${out_lc}"
    return 3
  fi
  shift

  # If no number in arguments, stream stdin as arguments
  if [[ $# -eq 0 ]]; then
    local -a args=()
    while IFS= read -r line || [[ $line ]]; do
      args+=("${line}")
    done
    set -- "${args[@]}"
  fi

  if [[ $# -eq 0 ]]; then
    printf >&2 'No number to convert\n'
    return 2
  fi

  local -- \
    in_decimal_point \
    out_decimal_point \
    in_thousands_sep

  # Get the numeric format settings for input and output locales
  in_decimal_point="$(LC_NUMERIC="${in_lc}" locale decimal_point)"
  out_decimal_point="$(LC_NUMERIC="${out_lc}" locale decimal_point)"
  in_thousands_sep="$(LC_NUMERIC="${in_lc}" locale thousands_sep)"

  shopt -s extglob # Need for string substitution
  # Process the numbers passed as arguments
  while (($#)); do
    # strip-out spaces and thousands separators if any
    local -- out_number="${1//?([[:space:]]|${in_thousands_sep})/}"
    shift

    # convert the decimal-point character
    echo "${out_number/${in_decimal_point}/${out_decimal_point}}"
  done
}

# shellcheck disable=SC2120 # Needs no argument when streamed
lcnumconv::l2p() {
  # Convert numbers from $LC_NUMERIC to POSIX locale
  # $@|<&1: The numbers to convert
  # >&1: The converted numbers
  lcnumconv::l2l "${LC_NUMERIC}" POSIX "${@}"
}

# shellcheck disable=SC2120 # Needs no argument when streamed
lcnumconv::p2l() {
  # Convert numbers from POSIX locale to $LC_NUMERIC
  # $@|<&1: The numbers to convert
  # >&1: The converted numbers
  lcnumconv::l2l POSIX "${LC_NUMERIC}" "${@}"
}

lcnumconv::lck() {
  # Check if a given locale is known to the system
  # $1: The locale to check (example: en_US.utf8)
  # $?: 0=true, 1=false
  [[ -z "$({ LC_ALL="${1}"; } 2>&1)" ]]
}

### It is safe to remove everything from here if you only need the library

# If it is sourced, it can return from here
[[ ${BASH_SOURCE[0]} != "${0}" ]] && return

# Stand-alone lcnumconv command
(
  # Sub-shell to prevent the stand-alone part from polluting
  # the sourcing script name-space

  show_help() {
    cat >&2 <<EOF

${lcnumconv_description}

$(show_version)

Usage: ${0##*/} [OPTIONS...] [<number>...]
Convert numbers format from one locale to another locale.

-f, --from-lc=locale       locale from the numbers
-t, --to-lc=locale         locale to convert numbers into

-?, --help                 show this

When no option is specified, conversion is done
from POSIX locale to current locale

When no numbers are provided as argument,
reads numbers from stdin (one number per line)

EOF
    exit 1
  }

  show_version() {
    cat <<EOF
${0##*/} version ${lcnumconv_version} - ${lcnumconv_date}

${lcnumconv_author}

${lcnumconv_license}
EOF
    exit
  }

  die() {
    printf >&2 '%s\n' "${1}"
    exit 1
  }
  declare -- \
    __opt_from_lc='' \
    __opt_to_lc=''

  # Options processing
  while :; do
    case $1 in
      -h | -\? | --help)
        show_help
        ;;
      -v | --version)
        show_version
        ;;
      -f | --from-lc)
        [[ "${2}" ]] || die "Option ${1} require an argument"
        __opt_from_lc="${2}"
        shift
        ;;
      --from-lc=?*)
        __opt_from_lc="${1#*=}"
        ;;
      --from-lc=)
        die "Option ${1} require an argument"
        ;;
      -t | --to-lc)
        [[ "${2}" ]] || die "Option ${1} require an argument"
        __opt_to_lc="${2}"
        shift
        ;;
      --to-lc=?*)
        __opt_to_lc="${1#*=}"
        ;;
      --to-lc=)
        die "Option ${1} require an argument"
        ;;
      --) # End of all options.
        shift
        break
        ;;
      -?*)
        die "Unknown option (ignored): ${1}"
        ;;
      *) # Default case: No more options, so break out of the loop.
        break ;;
    esac

    shift
  done

  # Adjust defaults for unset options
  if [[ ${__opt_from_lc} == '' && ${__opt_to_lc} == '' ]]; then
    # None set defaults to converting from POSIX to current locale
    __opt_from_lc='POSIX'
    __opt_to_lc="${LC_NUMERIC}"
  elif [[ ${__opt_from_lc} == '' ]]; then
    # When only destination locale is set
    if [[ ${__opt_to_lc} == 'POSIX' ]]; then
      # from locale is current locale
      __opt_from_lc="${LC_NUMERIC}"
    else
      # from locale is POSIX
      __opt_from_lc='POSIX'
    fi
  elif [[ ${__opt_to_lc} == '' ]]; then
    # When only source locale is set
    if [[ ${__opt_from_lc} == 'POSIX' ]]; then
      # to locale is current locale
      __opt_to_lc="${LC_NUMERIC}"
    else
      # to locale is POSIX
      __opt_to_lc='POSIX'
    fi
  fi

  lcnumconv::l2l "${__opt_from_lc}" "${__opt_to_lc}" "${@}"
  exit "${?}"
)
