module ggetopt

import math
import os

const (
	argv0           = ''
	min_columns     = 30 // min acceptable terminal width (columns)
	max_help_offset = 40 // longest long-opt name before help uses 2 lines
)

fn gen_short_optdefs(options string) ![]OptDef {
	mut res := []OptDef{}
	for opt in options.runes() {
		if opt.bytes().len > 1 {
			return error('short option must be ASCII: ${opt.str()}')
		}
		match opt {
			`:` {
				if res.len > 0 {
					if arg := res.last().arg {
						res[res.len - 1] = OptDef{
							...res.last()
							arg: OptArgDef{
								...arg
								optional: true
							}
						}
					} else {
						res[res.len - 1] = OptDef{
							...res.last()
							arg: OptArgDef{
								name: 'PARAM'
							}
						}
					}
				}
			}
			`-`, `+` {}
			else {
				res << OptDef{
					short: opt
				}
			}
		}
	}
	return res
}

fn gen_getopt_opts(options []OptDef) !(string, []C.option, int) {
	mut shortopts := ''
	mut longopts := []C.option{}
	mut max_long_idx := -1
	mut has_qm := false
	for i, option in options {
		if short := option.short {
			if short.bytes().len > 1 {
				s := short.str()
				return error('short option must be ASCII: ${s}')
			}
			if short == `?` {
				has_qm = true
			}
			shortopts += short.str()
			if arg := option.arg {
				shortopts += ':'
				if arg.optional {
					shortopts += ':'
				}
			}
		}
		if long := option.long {
			mut has_arg := 0
			if arg := option.arg {
				has_arg++
				if arg.optional {
					has_arg++
				}
			}
			longopts << C.option{
				name: long.str
				has_arg: has_arg
				flag: C.NULL
				val: 256 + i
			}
			max_long_idx = i
		}
	}
	if has_qm && max_long_idx >= 0 {
		// The API provides no way to distinguish a valid '?' shortopt from a
		// longopt error.  For shortopts, when there is an error, the option
		// char that is invalid/requires an argument is also set in C.optopt,
		// but this is not the case for longopts. So longopt errors are
		// indistinguishable from `?` shortopts and we must therefore disallow
		// `?` shortopts when longopts are in use.
		return error('short option `?` can not be used with long options')
	}
	longopts << C.option{C.NULL, 0, C.NULL, 0}
	return shortopts, longopts, max_long_idx
}

fn gen_c_args(args []string) (int, &&char) {
	argc := args.len + 1
	mut argv := unsafe { &&char(malloc(u32(argc) * sizeof(&char))) }
	unsafe {
		*argv = ggetopt.argv0.str
	}
	for i, arg in args {
		ptr := unsafe { &&char(argv + i + 1) }
		unsafe {
			*ptr = arg.str
		}
	}
	return argc, argv
	// mut argv := unsafe{[]&char{len: argc, init: C.NULL}}
	// unsafe{argv << &char(C.NULL)}
	// for arg in args {
	//    argv << arg.str
	//}
	// return argc, argv
}

fn gen_help_lines(options []OptDef, conf PrintHelpConfig) []string {
	mut has_short := false
	mut has_long := false
	for option in options {
		if option.short != none {
			has_short = true
		}
		if option.long != none {
			has_long = true
		}
	}
	mut cols := conf.columns
	if cols == 0 {
		cols = (os.getenv_opt('COLUMNS') or { '80' }).int()
	}
	cols = math.max(conf.min_columns, cols)
	min_offset := match true {
		has_long && has_short { 10 }
		has_long || has_short { 6 }
		else { 0 }
	}
	max_offset := math.min(cols / 2, conf.max_offset)
	mut offset := min_offset
	for option in options {
		mut w := min_offset
		if long := option.long {
			w += long.len
		}
		if arg := option.arg {
			if !has_long || option.long != none {
				w += arg.name.len + if arg.optional { 3 } else { 1 }
			}
		}
		if w > offset && w <= max_offset {
			offset = w
		}
	}
	// println("offset ${offset} min ${min_offset} max ${max_offset}")
	mut out := []string{}
	for option in options {
		if option.short != none || option.long != none {
			mut line := '  '
			if short := option.short {
				line += '-${short.str()}'
			}
			if long := option.long {
				if option.short != none {
					line += ', '
				} else if has_short {
					line += '    '
				}
				line += '--${long}'
			}
			if arg := option.arg {
				braces := if arg.optional { ['[', ']'] } else { ['', ''] }
				if has_long {
					if option.long != none {
						line += '${braces[0]}=${arg.name}${braces[1]}'
					}
				} else {
					line += ' ${braces[0]}${arg.name}${braces[1]}'
				}
			}
			if help := option.help {
				// println("cols ${cols} cols-offset ${cols - offset} help [${help}]")
				lines := gen_wraped_lines(help, cols - offset, conf.wrap_indent)
				if line.len > offset - 2 {
					out << line
					for text in lines {
						out << ' '.repeat(offset) + text
					}
				} else {
					out << line + ' '.repeat(offset - line.len) + lines[0]
					for i := 1; i < lines.len; i++ {
						out << ' '.repeat(offset) + lines[i]
					}
				}
			} else {
				out << line
			}
		} else if help := option.help {
			for line in gen_wraped_lines(help, cols, 0) {
				out << line
			}
		}
	}
	return out
}

fn gen_wraped_lines(line string, width int, indent int) []string {
	mut lines := []string{}
	mut i := 0
	mut actind := 0
	// println("LINE: len ${line.len} ${line}")
	for i < line.len {
		for i < line.len && line[i] == ` ` {
			i++
		}
		from := i
		mut till := -1
		mut insp := false
		for i < line.len && (till == -1 || i - from <= (width - actind)) {
			oldinsp := insp
			insp = line[i] == ` `
			if insp && !oldinsp {
				till = i
			}
			i++
		}
		if i == line.len && !insp && (till == -1 || i - from <= (width - actind)) {
			till = line.len
		}
		// println("from ${from} till ${till} i ${i}")
		if till > -1 && till > from {
			i = till + 1
			// println("taking: [${line[from..till]}]")
			lines << ' '.repeat(actind) + line[from..till]
		}
		actind = indent
	}
	return lines
}
