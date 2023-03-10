ggetopt
=======

A module for the [V programming language] which facilitates the use of the
[GNU Getopt library] via a more V-like interface.

Version 0.1

Installation
------------

``` Shell
$ v install edam.ggetopt
```

Usage
=====

The API has been kept in the spirit of GNU getopt library.

Short Options (basic usage)
---------------------------

At its most basic, you can use `getopt()` to process only short options, just as
you would GNU getopt library:

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
			'?' { println('Usage: foo [-v] [-u USER] [-?]') exit(0) }
			else {}
		}
	}) or { exit(1) }

	if opts.verbose {
		println('debug: printing name')
	}
	println('Hi ${opts.name}!')
}
```

Long Options (typical usage)
----------------------------

Defining long options is done in an array, just like `getopt_long()` in C, but,
as a small improvement, the short options string no longer needs to be supplied
as it can be derived from the long options.

Note that the array of options (`OptDef`s, actually) is built-up with the
following functions:
* option factory function: `option(long_name string, short_opt ?rune)`
* extend options with: `.arg(arg_name string, required bool)`

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
		ggetopt.option('user', `u`).arg('NAME', true),
		ggetopt.option('insult', none).arg('ADJECTIVE', false),
		ggetopt.option('verbose', none),
		ggetopt.option_help(),
	]
)

fn (mut o Options) process_arg(arg string, val ?string) ! {
	match arg {
		'u', 'user' { o.name = val or { '' } }
		'insult' { o.insult = val or { 'stinky' } }
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
`OptDef`s.  These define the available options, but can also define help
strings, which can be used by `print_help()` to generate some sensible-looking
help text.

* extend options with: `.help(text string)`
* line of text (not an option) factory function: `text(text string)`
* default `--help` option factory function: `option_help()`
* default `--version` option factory function: `option_version()`

``` V
const (
    options = [
        ggetopt.text('Usage: myprog [OPTION]... [MESSAGE]...')
        ggetopt.text('')
		ggetopt.text('Options:')
        ggetopt.option('user', `u`).arg('NAME', true)
            .help("provide the user's NAME")
        ggetopt.option('insult', none).arg('ADJECTIVE', false)
            .help('insult the user (default: stinky)')
        ggetopt.option('verbose', none)
            .help('display debug information')
        ggetopt.option_help()
    ]
)
```

Then, `print_help()` will output:

```
Usage: myprog [OPTION]... [MESSAGE]...

Options:
  -u, --user=NAME           provide the user's NAME
      --insult[=ADJECTIVE]  insult the user (default: stinky)
      --verbose             display debug information
      --help                display this help and exit
```

Error handling
--------------

By default, GNU getopt writes errors to stderr (as well as returning them).
This can be disabled, so that you can handle and display the errors yourself,
like so:

``` V
ggetopt.report_errors(false)
```

The errors that are returned by `getopt()`, `getopt_cli()`, `getopt_long()` and
`getopt_long_cli()` are essentially the same as the errors that GNU getopt
displays.  They have been changed only to make them slightly more consistent.

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

Licence
-------

Copyright (C) 2023 Tim Marston <tim@ed.am>

[GNU Lesser General Public Licence (version 3 or later)](../master/LICENCE)



[V programming language]: http://vlang.io
[GNU Getopt library]: https://www.gnu.org/software/libc/manual/html_node/Getopt.html
