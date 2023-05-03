ggetopt
=======

A module for the [V programming language] which facilitates the use of the
[GNU Getopt library] via a more V-like interface.

Version 0.2

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

Short Options (not recommended)
-------------------------------

At its most basic, you can use `getopt()` to process only short options,
similary to how you would in C.

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
	}) or { exit(1) }

	if opts.verbose {
		println('debug: printing name')
	}
	println('Hi ${opts.name}!')
}
```

Note: `getopt_cli()` just calls `getopt()`, passing in `os.args`.

Note: arguments are handled by a processing function.

Long Options (typical usage)
----------------------------

Defining long options is done in an array, just like `getopt_long()` in C, but,
as a small improvement, the short options string no longer needs to be supplied
as it can be derived from the long options.

Note that the array of options (`OptDef`s, actually) is built-up with the
following functions:
* option factory function: `opt(long_name string, short_opt ?rune)`
* extend option with an argument: `.arg(arg_name string, required bool)`

``` V
import edam.ggetopt

[heap]
struct Options {
mut:
	name    string = 'user'
	insult  ?string
	verbose bool
}

const (
	options = [
		ggetopt.opt('user', `u`).arg('NAME', true),
		ggetopt.opt('insult', `i`).arg('ADJECTIVE', false),
		ggetopt.opt('verbose', none),
		ggetopt.opt_help(),
	]
)

fn (mut o Options) process_arg(arg string, val ?string) ! {
	match arg {
		'u', 'user' { o.name = val or { '' } }
		'i', 'insult' { o.insult = val or { 'stinky' } }
		'verbose' { o.verbose = true }
		'help' { ggetopt.print_help(options) exit(0) }
		else {}
	}
}

fn main() {
	mut opts := Options{}
	rest := ggetopt.getopt_long_cli(options, opts.process_arg) or { exit(1) }

	if opts.verbose {
		println('debug: printing message')
	}
	greet := if insult := opts.insult { 'Hi ${insult}' } else { 'Hello' }
	println('${greet} ${opts.name}!')
	if rest.len > 0 {
		println(rest.join(' '))
	}
}
```

OptDefs and Automatic Help (getting fancy!)
-------------------------------------------

To use `getopt_long()` and `getopt_long_cli()`, you must pass in an array of
`OptDef`s.  These define the available options, but they can also define help
strings, which can be used by `print_help()` to generate some sensible-looking
help text.

* extend option with help text: `.help(text string)`
* line of text (not an option) factory function: `text(text string)`
* default `--help` option factory function: `opt_help()`
* default `--version` option factory function: `opt_version()`

Note: all text/help output is line-wrapped.

``` V

const (
    options = [
        ggetopt.text('Usage: myprog [OPTION]... [MESSAGE]...')
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
)
```

Then, `print_help()` will output:

```
Usage: myprog [OPTION]... [MESSAGE]...

Options:
  -u, --user=NAME           provide the user's NAME
  -i, --insult[=ADJECTIVE]  insult the user (default: stinky)
      --verbose             show debug information
      --help                display this help and exit
```

Error handling
--------------

By default, GNU getopt writes errors to stderr (as well as returning them).
This can be disabled, so that you can display any returned error yourself:

``` V
ggetopt.report_errors(false)
```

The errors that are returned by `getopt()`, `getopt_cli()`, `getopt_long()` and
`getopt_long_cli()` are not entirely the same as the errors that GNU getopt
displays.  They have been changed only for consistence.

Development
===========

Testing the module

``` shell
$ v test .
```

Debugging
---------

To dump GNU getopt library state, after each call to `getopt_long()`, set
`ggetopt_debug` when running the code, like so:

``` shell
$ v -d ggetopt_debug ...
```

Changes
-------

0.1 Initial version
0.2 Renamed opt() fns; tests; help-gen improvements (wrapping, config)

Licence
-------

Copyright (C) 2023 Tim Marston <tim@ed.am>

[GNU Lesser General Public Licence (version 3 or later)](../master/LICENCE)



[V programming language]: http://vlang.io
[GNU Getopt library]: https://www.gnu.org/software/libc/manual/html_node/Getopt.html
