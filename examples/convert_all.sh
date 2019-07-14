#!/usr/bin/env bash
# convert_all.sh
# Convert a number input in current locale
# into all the locales known to the host
#
# Using the lcnumconv.sh library:
# Demonstrates handling of a floating-point number input
# in arbitrary locale and print-out format with Bash's
# built-in printf into another arbitrary numeric locale

source ../lcnumconv.sh

# Read some LC_NUMERIC locale settings for our own fancy use
read -r -d '' _ thousands_sep _ _ sep_wc codeset < <(locale LC_NUMERIC)

# Compose the character-set and the code value of the thausands separator
if ((sep_wc < 255)); then
  sep_unit_value="$(printf '%s %d' "${codeset}" "${sep_wc}")"
else
  sep_unit_value="$(printf '%s U+%04X' "${codeset}" "${sep_wc}")"
fi

# Print detailed informations about the current LC_NUMERIC locale settings
cat <<EOF
The current numeric locale setting is:
LC_NUMERIC=${LC_NUMERIC}

This host defines the folloiwng numeric format settings for the ${LC_NUMERIC} locale:
$(locale -k LC_NUMERIC)

Digits groups may be separated by the '${thousands_sep}' character,
wich is also known as: ${sep_unit_value}.

EOF

# Ask for a floating-point number formatted in current locale
read -r -p "Please enter a floating-point number in your ${LC_NUMERIC} format:"$'\n' locale_float

# Print a table of host locales and number formatted to these locales

# Columns headers
printf '\n\n%-31s %-40s\n' 'Locales known to host' 'Number formatted to locale'

# Make string of 72 spaces
hl="$(printf '%-72s' '')"

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
