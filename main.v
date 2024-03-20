// Copyright (c) 2023 Tim Marston <tim@ed.am>.  All rights reserved.
// Use of this file is permitted under the terms of the GNU General Public
// Licence, version 3 or later, which can be found in the LICENCE file.

module ggetopt

import os

pub struct OptDef {
	long  ?string    // optional long option
	short ?rune      // optional short option
	arg   ?OptArgDef // optional option-argument
	help  ?string    // optional help string (for print_help())
}

pub struct OptArgDef {
	name     string @[required] // option-argument name (for print_help())
	optional bool // is option-argument optional?
}

type ProcessFn = fn (arg string, optarg ?string) !

// Argument Processing

// Process command-line args with getopt().  This simply calls getopt() with
// os.args as the first parameter.
pub fn getopt_cli(options string, process_fn ProcessFn) ![]string {
	return getopt(os.args[1..], options, process_fn)
}

// Just like the basic GNU getopt() function, process short options only,
// specified in options string in the getopt format (e.g., "abc:d:").  Valid
// arguments are handed off to the processing function, one at a time, and
// remaining arguments are returned.
pub fn getopt(args []string, options string, process_fn ProcessFn) ![]string {
	options_ := gen_short_optdefs(options)!
	return getopt_long(args, options_, process_fn)
}

// Process command-line args with getopt_long().  This simply calls
// getopt_long() with os.args as the first parameter.
pub fn getopt_long_cli(options []OptDef, process_fn ProcessFn) ![]string {
	return getopt_long(os.args[1..], options, process_fn)
}

// Process supplied args against an array of OptDefs.  Valid arguments are
// handed off to the process function, one at a time, and remaining arguments
// are returned.
pub fn getopt_long(args []string, options []OptDef, process_fn ProcessFn) ![]string {
	shortopts, longopts, max_long_idx := gen_getopt_opts(options)!
	argc, argv := gen_c_args(args)
	defer {
		unsafe { free(argv) }
	}
	$if trace_ggetopt ? {
		println('---argc: ${argc}')
		println('---shortopts: ${shortopts}')
		// println('---longopts: ${longopts}')
	}
	C.optind = 1 // reset getopt
	mut idx := int(0)
	for {
		opt := C.getopt_long(argc, argv, shortopts.str, &longopts[0], &idx)
		$if trace_ggetopt ? {
			ch := if opt >= 32 && opt < 256 { ' (${u8(opt).ascii_str()})' } else { '' }
			arg := if C.optarg != 0 {
				unsafe { cstring_to_vstring(&char(C.optarg)) }
			} else {
				'NULL'
			}
			println('---OPT: ${opt}${ch}, idx ${idx} (optopt: ${C.optopt}, optarg: ${arg}, optind: ${C.optind})')
		}
		if opt < 0 {
			break
		} else if opt == 63 && C.optopt != 0 { // ? and optopt set
			ch := u8(C.optopt).ascii_str()
			if _ := options.find_short(ch[0]) {
				return error('option requires an argument: -${ch}')
			} else if C.optopt >= 32 && C.optopt <= 126 { // C.isprint()
				return error('unrecognised option: -${ch}')
			} else if C.optopt >= 256 && C.optopt <= 256 + max_long_idx {
				long := options[C.optopt - 256].long or { '' }
				return error('option requires an argument: --${long}')
			} else {
				return error('invalid character: \\x${u32(C.optopt):x}')
			}
		} else if opt == 63 && max_long_idx >= 0 { // ? and we're using longopts
			return error('unrecognised option: ${args[C.optind - 2]}')
		} else {
			mut arg := ?string(none)
			if C.optarg != 0 {
				arg = unsafe { cstring_to_vstring(&char(C.optarg)) }
			}
			selopt := match true {
				opt < 256 { u8(opt).ascii_str() }
				else { options[opt - 256].long or { '' } }
			}
			$if trace_ggetopt ? {
				println('---processing ${selopt}')
			}
			process_fn(selopt, arg) or {
				if C.opterr != 0 {
					eprintln('${prog()}: ${err}')
				}
				return err
			}
		}
	}
	remain := gen_remain_from_c_args(argc, argv, C.optind)
	$if trace_ggetopt ? {
		println('---optind: ${C.optind}')
		println('---remain: ${remain}')
	}
	return remain
}

// Turn on/off automatic printing of errors to stderr.  Disabled by default.
pub fn report_errors(enable bool) {
	C.opterr = if enable { 1 } else { 0 }
}

// OptDefs functions

// Make an OptDef for a long option with optional short option, which can be
// extended via .arg() and .help() methods.
@[inline]
pub fn opt(long ?string, short ?rune) OptDef {
	return OptDef{
		long: long
		short: short
	}
}

// Extend an OptDef to include a named argument.
@[inline]
pub fn (o &OptDef) arg(name string, required bool) OptDef {
	return OptDef{
		...o
		arg: OptArgDef{
			name: name
			optional: !required
		}
	}
}

// Extend an OptDef to include help text for the option.
@[inline]
pub fn (o &OptDef) help(help string) OptDef {
	return OptDef{
		...o
		help: help
	}
}

// Make an OptDef for a --help option
pub fn opt_help() OptDef {
	return OptDef{
		long: 'help'
		help: 'display this help and exit'
	}
}

// Make an OptDef for a --version option
pub fn opt_version() OptDef {
	return OptDef{
		long: 'version'
		help: 'output version information and exit'
	}
}

// Make OptDef which displays some text in print_help()
pub fn text(text string) OptDef {
	return OptDef{
		help: text
	}
}

// Find an OptDef by it's short option.
pub fn (opts []OptDef) find_short(short rune) ?OptDef {
	for opt in opts {
		if opt.short or { ` ` } == short {
			return opt
		}
	}
	return none
}

// Find an OptDef by it's short option.
pub fn (opts []OptDef) find_long(long string) ?OptDef {
	for opt in opts {
		if opt.long or { '' } == long {
			return opt
		}
	}
	return none
}

@[deprecated: 'use opt() instead']
pub fn option(long ?string, short ?rune) OptDef {
	return opt(long, short)
}

@[deprecated: 'use opt_help() instead']
pub fn option_help() OptDef {
	return opt_help()
}

@[deprecated: 'use opt_version() instead']
pub fn option_version() OptDef {
	return opt_version()
}

// Help Generation and Utility

@[params]
pub struct PrintConfig {
	// wrapping
	columns     int // width of terminal (defaults to COLUMNS from environment)
	min_columns int = 40 // min acceptable terminal width (columns)
	wrap_indent int = 2 // after wrapping, indent by spaces
	// line overflowing
	max_offset int = 40 // longest option before starting on second line
}

// Generate and print program help (e.g., in response to --help), based on the
// OptDefs provided.
pub fn print_help(options []OptDef, conf PrintConfig) {
	for line in gen_help_lines(options, conf) {
		println(line)
	}
}

// Print output for --version, based on executable name.
pub fn print_version(version string, description []string, conf PrintConfig) {
	app := os.base(os.args[0])
	println('${app} ${version}')
	cols := calc_cols(conf)
	for line in description {
		for wrapped_line in gen_wrapped_lines(line, cols, 0) {
			println(wrapped_line)
		}
	}
}

// Get the programme name, as specified in os.args[0]
pub fn prog() string {
	return os.base(os.args[0])
}

// Print message and exit(1)
@[noreturn]
pub fn die[T](msgs ...T) {
	eprintln('${prog()}: ${msgs.map(it.str()).join('\n')}')
	exit(1)
}

// Print message and hint to try --help and exit
@[noreturn]
pub fn die_hint[T](msgs ...T) {
	eprintln('${prog()}: ${msgs.map(it.str()).join('\n')}')
	eprintln('Try `${prog()} --help` for more information.')
	exit(1)
}
