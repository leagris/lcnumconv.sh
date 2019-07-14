#!/usr/bin/env bash
# convert_all.sh
# Convert a number input in current locale
# into all the locales known to the host
#
# Using the lcnumconv.sh library:
# Demonstrates handling of a floating-point number input
# in arbitrary locale and print-out format with Bash's
# built-in printf into another arbitrary numeric locale

if ! source ../lcnumconv.sh; then
  echo >&2 $"Require the lcnumconv.sh library"
  exit 2
fi

# Create and populate variables from the LC_NUMERIC locale:
# decimal_point
# thousands_sep
# grouping
# numeric_decimal_point_wc
# numeric_thousands_sep_wc
# numeric_codeset

while IFS=$'\n=' read -r locale_key locale_value; do
  var_name="${locale_key//-/_}"  # Translate key to valid variable name
  var_value="${locale_value#\"}" # Strip any leading quote from value
  var_value="${var_value%\"}"    # Strip any trailing quote from value
  printf -v "${var_name}" '%s' "${var_value}"
done < <(
  locale \
    --keyword-name \
    LC_NUMERIC
) # from key=value pairs in the LC_NUMERIC locale category

# Work-around a GLibC locale definition files bug
# Locale definition files are referrencing a raw chaset
# numeric value wich is copied verbatim into other
# charsets, regardless of the actual character and
# numerical value used for the destination locale's charset.
# Example:
# LC_NUMERIC=fr_FR.iso88591 locale -k numeric-thousands-sep-wc
# returns: numeric-thousands-sep-wc=8239
# wich is the numeric value of the Unicode Character:
# 'NARROW NO-BREAK SPACE' (U+202F)
# verbatim copied from the fr_FR locale definition that is
# referrencing the Unicode value for the thousands_sep key
# https://sourceware.org/git/?p=glibc.git;a=blob;f=localedata/locales/fr_FR;h=a18c514f1921fed0049d3b769c95c9e0f864fb2f;hb=HEAD#l97
# rather-than the correct character in the thousands_sep key,
# the iso-8859-1 charset, actually is:
# 'NO-BREAK SPACE' (U+00A0)
# so the numeric-thousands-sep-wc key=value pair should be:
# numeric-thousands-sep-wc=160 instead

# Re-inject the correct character value in the bugged entries
# shellcheck disable=SC2034,SC2154 # generated from locale
printf -v numeric_decimal_point_wc '%d' "'${decimal_point}"
# shellcheck disable=SC2154 # generated from locale
printf -v numeric_thousands_sep_wc '%d' "'${thousands_sep}"

# If there is a thousands separator, prepare a digits_group_information
if [[ ${numeric_thousands_sep_wc} -gt 0 ]]; then

  # Compose the character-set and the code value of the thausands separator
  if [[ ${numeric_thousands_sep_wc} -lt 256 ]]; then
    # shellcheck disable=SC2154 # generated from locale
    printf -v sep_unit_value '%s %d' "${numeric_codeset}" "${numeric_thousands_sep_wc}"
  else
    printf -v sep_unit_value '%s U+%04X' "${numeric_codeset}" "${numeric_thousands_sep_wc}"
  fi

  printf -v digits_group_info $"
Digits groups may be separated by the '%s' character,
wich is also known as: %s.
" \
  "${thousands_sep}" \
  "${sep_unit_value}"
else
  digits_group_info=''
fi

# Print the deatils of the LC_NUMERIC locale settings
printf $"The current numeric locale setting is:
LC_NUMERIC=%s

This host defines the folloiwng numeric format settings for the %s locale:
%s
%s
" \
  "${LC_NUMERIC}" \
  "${LC_NUMERIC}" \
  "$(locale -k LC_NUMERIC)" \
  "${digits_group_info}"

# Ask for a floating-point number formatted in current locale
read -r -p $"Please enter a floating-point number in your ${LC_NUMERIC} format:"$'\n' locale_float

# Print a table of host locales and number formatted to these locales

# Columns headers
printf '\n\n%-31s %-40s\n' $"Locales known to host" $"Number formatted to locale"

# Make string of 72 spaces
printf -v hl '%-72s' ''

# Print a line of 72 dashes
printf '%s\n' "${hl// /-}"

# Iterate all host's known locales except the current numeric locale
for to_lc in $(
  locale --all-locales \
    | grep \
      --invert-match \
      "${LC_NUMERIC}"
); do
  # Transform the current locale formatted number into the destination locale
  # using the lcnumconv.sh library's l2l (locale to locale) method
  translated_float="$(
    lcnumconv::l2l "${LC_NUMERIC}" "${to_lc}" "${locale_float}"
  )"

  # Switch the numeric locale to the destination locale
  # to allow the Bash's built-in printf to accept this locale's format
  # Print the table's line with host's locale and formatted number
  LC_NUMERIC="${to_lc}" printf '%-31s %f\n' "${to_lc}" "${translated_float}"
done
