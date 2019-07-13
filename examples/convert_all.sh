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

sep_wc="$(locale numeric-thousands-sep-wc)"

if ((sep_wc<255)); then
  sep_unit_value="$(printf 'ASCII %d' "${sep_wc}")"
else
  sep_unit_value="$(printf 'Unicode U+%04X' "${sep_wc}")"
fi

cat <<EOF
Your current numeric locale format is:
LC_NUMERIC=${LC_NUMERIC}

The systems defines the folloiwng numeric format settings:
$(locale -k LC_NUMERIC)

You can group and separate digits accordingly
to the '$(locale thousands_sep)' character, wich is
also known as: ${sep_unit_value}.
EOF

read -r -p "Now please enter floating-point a number in your ${LC_NUMERIC} format:"$'\n' locale_float

printf '\n%-31s %-40s\n' 'Locales known to host' 'Number formatted to locale'
hl="$(printf '%-72s' '')"; printf '%s\n' "${hl// /-}"
for to_lc in $(
  locale --all | \
    grep \
      --invert-match \
      "${LC_NUMERIC}"
); do
  translated_float="$(
    lcnumconv::l2l "${LC_NUMERIC}" "${to_lc}" "${locale_float}"
  )"
  LC_NUMERIC="${to_lc}" printf '%-31s %f\n' "${to_lc}" "${translated_float}"
done
