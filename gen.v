module ggetopt

import math
import os

const (
	argv0           = ''
	min_columns     = 30 // min acceptable terminal width (columns)
	max_help_offset = 40 // longest long-opt name before help uses 2 lines
)

// TODO: remove when smartcasting optionals is implemented
fn oa_() OptArgDef {
	return OptArgDef{
		name: ''
	}
}

fn gen_short_optdefs(options string) ![]OptDef {
	mut res := []OptDef{}
	for opt in options.runes() {
		if opt.bytes().len > 1 {
			return error('short option must be ASCII: ${opt.str()}')
		}
		match opt {
			`:` {
				if res.len > 0 {
					if res.last().arg != none {
						res[res.len - 1] = OptDef{
							...res.last()
							arg: OptArgDef{
								...res.last().arg or { oa_() }
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
		if option.short != none {
			if (option.short or { ` ` }).bytes().len > 1 {
				s := (option.short or { ` ` }).str()
				return error('short option must be ASCII: ${s}')
			}
			if (option.short or { ` ` }) == `?` {
				has_qm = true
			}
			shortopts += (option.short or { ` ` }).str()
			if option.arg != none {
				shortopts += ':'
				if (option.arg or { oa_() }).optional {
					shortopts += ':'
				}
			}
		}
		if option.long != none {
			mut has_arg := 0
			if option.arg != none {
				has_arg++
				if (option.arg or { oa_() }).optional {
					has_arg++
				}
			}
			longopts << C.option{
				name: (option.long or { '' }).str
				has_arg: has_arg
				flag: C.NULL
				val: 256 + i
			}
			max_long_idx = i
		}
	}
	if has_qm && max_long_idx >= 0 {
		// There is no way to tell between a valid '?' shortopt and a longopt
		// error.  For shortopts, when there is an error, the option char that
		// is invalid or requires an argument is set in C.optopt, but this is
		// not the case for longopts.  So when longopts are in use, a longopt
		// error can't be distinguished from the `?` shortopt.
		return error('short option `?` can not be used with long options')
	}
	longopts << C.option{C.NULL, 0, C.NULL, 0}
	return shortopts, longopts, max_long_idx
}

fn gen_c_args(args []string) (int, &&char) {
	argc := args.len + 1
	mut argv := unsafe { &&char(malloc(u32(argc) * sizeof(&char))) }
	unsafe {
		*argv = argv0.str
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

fn gen_help_lines(options []OptDef) []string {
	cols := math.max(min_columns, (os.getenv_opt('COLUMNS') or { '80' }).int())
	max_offset := math.min(cols / 2, max_help_offset)
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
	mut best_w := 0
	mut offset := 0
	for option in options {
		mut w := 0
		if option.long != none {
			w += (option.long or { '' }).len + 2
		}
		if option.arg != none && (!has_long || option.long != none) {
			w += (option.arg or { oa_() }).name.len +
				if (option.arg or { oa_() }).optional { 3 } else { 1 }
		}
		if w > best_w {
			mut tmp := w + 4
			tmp += if has_short { 2 } else { 0 } // "-x"
			tmp += if has_short && has_long { 2 } else { 0 } // ", "
			if tmp < max_offset {
				offset = tmp
				best_w = w
			}
		}
	}
	// println("long: ${has_long}, short: ${has_short}, offset: ${offset}")
	mut out := []string{}
	for option in options {
		if option.short != none || option.long != none {
			mut line := '  '
			if option.short != none {
				line += '-${(option.short or { ` ` }).str()}'
			}
			if option.long != none {
				if option.short != none {
					line += ', '
				} else if has_short {
					line += '    '
				}
				line += '--${option.long or { '' }}'
			}
			if option.arg != none {
				argname := (option.arg or { oa_() }).name
				braces := if (option.arg or { oa_() }).optional {
					['[', ']']
				} else {
					['', '']
				}
				if has_long {
					if option.long != none {
						line += '${braces[0]}=${argname}${braces[1]}'
					}
				} else {
					line += ' ${braces[0]}${argname}${braces[1]}'
				}
			}
			if tmp := option.help {
                lines := gen_wraped_lines(tmp, cols - offset, 2)
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
		} else if tmp := option.help {
            for line in gen_wraped_lines(tmp, cols, 0) {
                out << line
            }
		}
	}
	return out
}

fn gen_wraped_lines(line string, width int, indent int) []string {
    mut lines := []string{}
    lines << line
    return lines
}

//fn gen_wraped_lines(line, width, indent) []string {
//    mut lines := []string{}
//    for line.len > width {
//        mut taken := 0
//        mut take := 0
//        for i := 0; i < lines.len; i++ {
//            if lines[i] == ' ' {

//            } else {
//                take ++
//            }
//            match lines[i] {
//                ' ' { split++ }
//                '-' {  }
//            }
//        }

//        mut take := 0
//        for i := 0; line[i] in [` `]
//    }
//}
