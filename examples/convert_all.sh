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

# Populate variables from the LC_NUMERIC locale:
{
  read -r _ # skip decimal_point
  read -r thousands_sep
  read -r _ # skip grouping
  read -r _ # skip numeric_decimal_point_wc
  read -r _ # skip numeric_thousands_sep_wc
  read -r numeric_codeset
} < <(locale LC_NUMERIC) # values list in the LC_NUMERIC locale category

# Collect the actual character code
# as numeric_thousands_sep_wc is always Unicode
# and may not match the actual numeric_codeset
printf -v numeric_thousands_sep_c '%d' "'${thousands_sep}"

# If there is a thousands separator, prepare a digits_group_information
if [[ ${numeric_thousands_sep_c} -gt 0 ]]; then

  # Compose the character-set and the code value of the thausands separator
  if ((numeric_thousands_sep_c >> 8)); then
    printf -v sep_unit_value '%s U+%04X' "${numeric_codeset}" "${numeric_thousands_sep_c}"
  else
    printf -v sep_unit_value '%s %d' "${numeric_codeset}" "${numeric_thousands_sep_c}"
  fi

  # Compose an information about grouping digits
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
