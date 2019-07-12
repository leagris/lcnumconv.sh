# lcnumconv.sh

`lcnumconv.sh` is a Bash library and stand-alone command to convert numbers between `LC_NUMERIC` locale formats

### License

![WTFPL License badge](http://www.wtfpl.net/wp-content/uploads/2012/12/wtfpl-badge-1.png)

#### This program is free software.

It comes without any warranty, to the extent permitted by applicable law.

You can redistribute it and, or modify it under the terms of the

**Do What The Fuck You Want To Public License, Version 2**, as published by Sam Hocevar.

See:
* [The WTFPL website](http://www.wtfpl.net/)
* [LICENSE.md](LICENSE.md)

### Incentives behind `lcnumconv.sh`

It has been created to work-around a specific behavior of the `%f` format code with the Bash's built-in `printf` command, witch expects floating-point numbers arguments to be formatted accordingly to the environment variable `$LC_NUMERIC`; thus diverging from the GNU Coreutils's stand-alone `printf`'s  behavior, witch expects `POSIX` locale formatted floating-point numbers for arguments, regardless of the print-out format, using the environment variable `$LC_NUMERIC`; as one would want to control the print-out locale numeric format while internally storing, processing and exchanging values with other processes or sub-systems by using the universally compatible and portable `POSIX` locale numeric format. 

Varying a data format with system locale settings is a questionable decision when dealing with a language operating into a large variety of systems, environments and locale settings, that [Bash people seem to be backing on behalf of the POSIX compliance](https://lists.gnu.org/archive/html/bug-bash/2019-07/msg00030.html), overlooking the numeric data portability hindering consequences it has, and will continue to cause; because even if the Bash dudes changed their mind tomorrow, validating such changes takes time and efforts, and newer Bash versions would not be deployed on older systems; probably creating an even bigger issue, with version-dependent behavior differences. (how funny it sounds, isn't it?).

If you write Bash scripts for systems where you are sure there is a GNU Coreutils's `printf` available, you can avoid the Bash's built-in `printf` numerical data portability hindering of the `%f` format indicator, by calling the stand-alone Coreutils `printf` function with `env printf` rather than just `printf`, witch would call the Bash's built-in function, and be safe with passing `POSIX` locale formatted floating-point numbers to it as `%f` arguments, regardless of the independently controlled print-out locale format with the `$LC_NUMERIC` variable.

If your Bash scripts runs on non-GNU systems, this may not be an option. So you need a way to convert floating-point numbers from the `POSIX` locale format, like those output from the `bc` command, into the `$LC_NUMERIC` environment variable locale formatted floating-point numbers, that the Bash's built-in `printf` requires.

Setting the environment variable `$LC_NUMERIC='POSIX'` or `$LC_NUMERIC='C'` can't be an option either, when you need the print-out of floating-point numbers, to be formatted for a specific locale.

This `lcnumconv.sh` library and stand-alone command may help you here.

See the related [Bash's bug report here](https://lists.gnu.org/archive/html/bug-bash/2019-07/msg00028.html)

### Installation

#### Download the library file with:

You can clone the repository or download the library file only with `wget`:

```Bash
wget -qO lcnumconv.sh -- https://raw.githubusercontent.com/leagris/lcnumconv.sh/master/lcnumconv.sh
```

If you want it available in the system `$PATH`, you can install it with:

```Bash
sudo \
  install \
    --owner=root \
    --group=root \
    --mode=0755 \
    -- \
    lcnumconv.sh \
    /usr/local/bin/lcnumconv
```

### Usage

`lcnumconv --help`

```
lcnumconv is a Bash library and a stand-alone command
for numbers format conversion between locales.

lcnumconv version 1.2.1 - Date Wed, 10 Jul 2019

Copyright © 2019 Léa Gris <lea.gris@noiraude.net>

This program is free software.
It comes without any warranty, to the extent permitted by applicable law.
You can redistribute it and/or modify it under the terms of the Do What
The Fuck You Want To Public License, Version 2, as published by Sam Hocevar.
See: http://www.wtfpl.net/ for more details.

Usage: lcnumconv [OPTIONS...] [<number>...]
Convert numbers format from one locale to another locale.

-f, --from-lc=locale       locale from the numbers
-t, --to-lc=locale         locale to convert numbers into

-?, --help                 show this

When no option is specified, conversion is done
from POSIX locale to current locale

When no numbers are provided as argument,
reads numbers from stdin (one number per line)
```

### Sample usages

#### As a stand-alone tool

```Bash
lea@marvin:/tmp$ lcnumconv 42.42
42,42
lea@marvin:/tmp$ lcnumconv -f fr_FR.UTF-8 -t POSIX '1 448 216,41'
1448216.41
```

#### As a library inside a Bash script

```Bash
#!/usr/bin/env bash

source lcnumconv.sh || exit 1

printf "Using 'lcnumconv' version %s from %s\\n\\n" \
  "${lcnumconv_version}" \
  "${lcnumconv_author}"

printf "A genuine floating-point division performed by 'bc':\\n61 ÷ 7 ≈ %.2f\\n\\n" \
  "$(echo 'scale=12;61/7' | bc | lcnumconv::p2l)"

bcscript="$(
  cat <<EOF
scale = 20

/* Uses the fact that e^x = (e^(x/2))^2
   When x is small enough, we use the series:
     e^x = 1 + x + x^2/2! + x^3/3! + ...
*/

define e(x) {
  auto  a, d, e, f, i, m, v, z

  /* Check the sign of x. */
  if (x<0) {
    m = 1
    x = -x
  }

  /* Precondition x. */
  z = scale;
  scale = 4 + z + .44*x;
  while (x > 1) {
    f += 1;
    x /= 2;
  }

  /* Initialize the variables. */
  v = 1+x
  a = x
  d = 1

  for (i=2; 1; i++) {
    e = (a *= x) / (d *= i)
    if (e == 0) {
      if (f>0) while (f--)  v = v*v;
      scale = z
      if (m) return (1/v);
      return (v/1);
    }
    v += e
  }
}
e(2)
e(10)
quit
EOF
)"

read -r -d '' e2 e10 < <(echo "${bcscript}" \
  | bc \
  | lcnumconv::p2l)

printf "Some Euler–Mascheroni exponents computed by the sample 'bc' script:\\nℇ² ≈ %f\\nℇ¹⁰ ≈ %f\\n\\n" \
  "${e2}" \
  "${e10}"

printf "Thank 'lcnumconv' for letting the numbers being formatted into your locale LC_NUMERIC='%s'.\\n\\n" \
  "${LC_NUMERIC}"

printf "Bash's built-in 'printf %%f' would not support this otherwise.\\n\\n"

printf "See Bash's bug report here: https://lists.gnu.org/archive/html/bug-bash/2019-07/msg00028.html for more info.\\n\\n"
```

##### Running the library sample

```none
lea@marvin:/tmp$ bash ./test-lcnumconv.sh

Using 'lcnumconv' version 1.2.1 from Copyright © 2019 Léa Gris <lea.gris@noiraude.net>

A genuine floating-point division performed by 'bc':
61 ÷ 7 ≈ 8,71

Some Euler–Mascheroni exponents computed by the sample 'bc' script:
ℇ² ≈ 7,389056
ℇ¹⁰ ≈ 22026,465795

Thank 'lcnumconv' for letting the numbers being formatted into your locale LC_NUMERIC='fr_FR.utf8'.

Bash's built-in 'printf %f' would not support this otherwise.

See Bash's bug report here: https://lists.gnu.org/archive/html/bug-bash/2019-07/msg00028.html for more info.
```
