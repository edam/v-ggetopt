ggetopt
=======

A module for the [V programming language] which facilitates the use of the
[GNU Getopt library] via a more V-like interface.

Version 0.6

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
major difference is that processing options is done in a function, not a loop.

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

Notes

* `getopt(args []string, options string, process_fn ProcessFn) ![]string`
  processed short opts and returns any unused arguments
* `getopt_cli()` just calls `getopt()`, passing in `os.args` as the first
  argument.

Long Options (typical usage)
----------------------------

Defining long options is done in an array, just like `getopt_long()` in C.  But,
unlike in C, the short options are not given separately as a string.

The array of options (`OptDef`s, actually) is built-up with the following helper
functions (and some more, introduced in the next section):
* `opt(long_name string, short_opt ?rune) OptDef` is an option factory function
* `(OptDef) arg(arg_name string, required bool) OptDef` can be used to extend an
  option, giving it an argument
* `opt_help() OptDef` is a factory function returning a standard `--help` option

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

Notes

* `print_help(options []OptDef, conf PrintConfig)` can be used to automatically
  generate help for an array of `OptDef`s.  `PrintConfig` can be omitted.

* `die[T](msg ...T)` can be used to terminate with error (exit code 1) and print
  a message to stderr prefixed with the binary name, e.g.: `myprog: some
  message`.

* `die_hint[T](msg ...T)`, as shown above, is the same as `die()` but also
  includes a message hinting the user to "Try `myprog --help` for more
  information."

OptDefs and Automatic Help (getting fancy!)
-------------------------------------------

The array of `OptDef`s which specifies options can also include help text, both
for options and also general lines of text, which `print_help()` includes in its
output.

More of those array-building helpers:
* `(OptDef) help(text string) OptDef` can be used to extend an option and
  supplement it with help text
* `text(text string) OptDef` is a factory function for a line of help text (so,
  not an option)
* `opt_version() OptDef` is a factory function returning a standard `--version`
  option

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

If `options` had been defined this in way in the previous example, then `--help`
would output:

```
Usage: myprog [OPTION]... [MESSAGE]...

Options:
  -u, --user=NAME           provide the user's NAME
  -i, --insult[=ADJECTIVE]  insult the user (default: stinky)
      --verbose             show debug information
      --help                display this help and exit
```

Notes

* `print_version(version string, description []string, conf PrintConfig)` also
  exists to complement `print_help()` and generates output for `--version`.
  `PrintConfig` can be omitted.

* `prog() string`, as shown above, can be used to get the name of the binary
  (which it gets from `os.args[0]`).

Error handling
--------------

By default, GNU getopt writes errors to stderr.  This is disabled by default in
the V wrapper, since errors are returned, and the recommendation is that you
display them yourself and exit with `die_hint()`, as shown above.

If you want to turn on the default behaviour of the C getopt library back on, so
that errors are automatically emitted to stderr, please note the following:

1. When turned on, some emitted errors have to be generated by the V wrapper
   where there is no equivalent in underlying C library, so this is still not
   "pure GNU getopt" behaviour.

2. In some cases, minimal difference exist between the errors returned and the
   ones emitted, so that all the errors are more consistent.

Notes

* `report_errors(enable bool)` can use used to turn on/off automatic error
  emitting.

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

0.6 - fix returned non-option args; added die_hint(); rename trace_ggetopt;
      report_errors off by default

Licence
-------

Copyright (C) 2023-2024 Tim Marston <tim@ed.am>

[GNU Lesser General Public Licence (version 3 or later)](../master/LICENCE)



[V programming language]: http://vlang.io
[GNU Getopt library]: https://www.gnu.org/software/libc/manual/html_node/Getopt.html
