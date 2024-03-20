ggetopt
=======

A module for the [V programming language] which facilitates the use of the
[GNU Getopt library] via a more V-like interface.

Version 0.6dev

Features:
- V-like getopt() shim
- V-like getopt_long() shim
- Auto `--help` output generation

Installation
------------

``` Shell
$ v install edam.ggetopt
```

Usage
=====

The API has been kept in the spirit of GNU getopt library.

Short Options (very basic)
--------------------------

At its most basic, you can use `getopt()` to process only short options, similar
to how you would in C, by passing a combined short options string.  The only
major different is that processing options is done in a function, not a loop.

``` V
import edam.ggetopt

struct Options {
mut:
    verbose bool
    name    string = 'user'
}

fn main() {
    mut opts := &Options{}
    ggetopt.getopt_cli('vu:?', fn [mut opts] (arg string, val ?string) ! {
        match arg {
            'v' { opts.verbose = true }
            'u' { opts.name = val or { '' } }
            '?' { println('Usage: myprog [-v] [-u NAME] [-?]') exit(0) }
            else {}
        }
    })!

    if opts.verbose {
        println('debug: printing name')
    }
    println('Hi ${opts.name}!')
}
```

* `getopt_cli()` just calls `getopt()`, passing in `os.args`.

Long Options (typical usage)
----------------------------

Defining long options is done in an array, just like `getopt_long()` in C.  But,
unlike in C, the short options are not given separately as a string.

Note that the array of options (`OptDef`s, actually) is built-up with the
following functions:
* option factory function: `opt(long_name string, short_opt ?rune)`
* extend an option with an argument: `arg(arg_name string, required bool)`
* default `--help` option factory function: `opt_help()`

``` V
import edam.ggetopt

const options = [
    ggetopt.opt('user', `u`).arg('NAME', true),
    ggetopt.opt('insult', `i`).arg('ADJECTIVE', false),
    ggetopt.opt('verbose', none),
    ggetopt.opt_help(),
]

@[heap]
struct Options {
mut:
    name    string = 'user'
    insult  ?string
    verbose bool
}

fn (mut o Options) process_arg(arg string, val ?string) ! {
    match arg {
        'u', 'user' {
            o.name = val or { '' }
        }
        'i', 'insult' {
            o.insult = val or { 'stinky' }
        }
        'verbose' {
            o.verbose = true
        }
        'help' {
            ggetopt.print_help(options)
            exit(0)
        }
        else {}
    }
}

fn main() {
    mut opts := Options{}
    rest := ggetopt.getopt_long_cli(options, opts.process_arg) or {
        ggetopt.die_hint(err)
    }
    if rest.len > 0 {
        ggetopt.die_hint('extra arguments on command line')
    }
    if opts.verbose {
        println('debug: printing message')
    }
    greet := if insult := opts.insult { 'Hi ${insult}' } else { 'Hello' }
    println('${greet} ${opts.name}!')
}
```

* `die()` can be used to terminate with error (exit code 1) and print an error
  message to stdout prefixed with the binary name, e.g.: `myprog: some message`.

* `die_hint()`, as shown above, is the same as `die()` but also includes a
  message hinting the user to "Try `myprog --help` for more information."

OptDefs and Automatic Help (getting fancy!)
-------------------------------------------

The array of `OptDef`s which specifies options can also include help text, both
for options and also general lines of text, which `print_help()` includes in its
output.

* extend an option with help text: `help(text string)`
* line of text (not an option) factory function: `text(text string)`
* standard `--help` option factory function: `opt_help()`
* standard `--version` option factory function: `opt_version()`

E.g.,

``` V
const options = [
    ggetopt.text('Usage: ${ggetopt.prog()} [OPTION]... [MESSAGE]...')
    ggetopt.text('')
    ggetopt.text('Options:')
    ggetopt.opt('user', `u`).arg('NAME', true)
        .help("provide the user's NAME")
    ggetopt.opt('insult', `i`).arg('ADJECTIVE', false)
        .help('insult the user (default: stinky)')
    ggetopt.opt('verbose', none)
        .help('show debug information')
    ggetopt.opt_help()
]
```

If the options had been defined this way in the previous example, then `--help`
would output:

```
Usage: myprog [OPTION]... [MESSAGE]...

Options:
  -u, --user=NAME           provide the user's NAME
  -i, --insult[=ADJECTIVE]  insult the user (default: stinky)
      --verbose             show debug information
      --help                display this help and exit
```

* `print_version()` also exists, to help with `--version` output.

* `prog()`, as shown above, can be used to get the name of the binary (which it
  gets from `os.args[0]`).

Error handling
--------------

By default, GNU getopt writes errors to stderr.  This is disabled by default,
since the errors are returned by this V wrapper and the recommendation is that
you display them yourself and exit with, e.g., `die_hint()` (as shown above).

If you want to turn on the GNU getopt output, however, you can using
`report_errors(true)`.

Note that the errors returned by this library are very slightly different than
the ones emitted by GNU getopt, so that they are more consistent.

Development
===========

Testing the module

``` shell
$ v test .
```

Debugging
---------

To dump GNU getopt library state, after each call to `getopt_long()`, set
`trace_ggetopt` when running the code, like so:

``` shell
$ v -d trace_ggetopt ...
```

Changes
-------

0.1 - Initial version

0.2 - Renamed opt() fns; tests; help-gen improvements (wrapping, config)

0.3 - Added print_version(); fixed tests

0.4 - Added die(), prog(); fixed text(''); gen_wraped_lines() handles newlines;
      errors from process_fn() are eprintln()ed when reporting_errors(true)

0.5 - fix warnings; fix for lines starting with spaces

0.6dev - fix returned non-option args; added die_hint(); rename trace_ggetopt;
      report_errors off by default

Licence
-------

Copyright (C) 2023-2024 Tim Marston <tim@ed.am>

[GNU Lesser General Public Licence (version 3 or later)](../master/LICENCE)



[V programming language]: http://vlang.io
[GNU Getopt library]: https://www.gnu.org/software/libc/manual/html_node/Getopt.html
