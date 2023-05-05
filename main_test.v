module ggetopt

import os
import rand

fn test_shortopts() {
	o := [
		opt('aaa', `a`),
		opt('bbb', none).arg('BBB', true),
		opt(none, `c`).arg('CCC', true),
		opt('ddd', none).arg('DDD', false),
		opt(none, `e`).arg('EEE', false),
	]

	ot := new_opt_tester(o)
	defer {
		ot.cleanup()
	}

	ot.run_ok('') // test runs ok

	// inbuilt errors
	ot.run_fail('-x') // invalid option -- x
	ot.run_fail('--xxx') // unrecognised option '--xxx'

	// consistent errors
	ot.fail_with('-x', 'unrecognised option: -x')
	ot.fail_with('--xxx', 'unrecognised option: --xxx')
}

fn test_version() {
	o := [
		opt_help(),
		opt_version(),
	]

	ot := new_opt_tester(o)
	defer {
		ot.cleanup()
	}

	// inbuilt errors
	ot.run_version()
}

// --

struct OptTester {
	options []OptDef
	vfile   string
}

fn new_opt_tester(options []OptDef) &OptTester {
	mut gen_opts := []string{}
	for opt in options {
		mut gen_opt := ''
		long := opt.long or { '' }
		match long {
			'help' {
				gen_opt = 'ggetopt.opt_help()'
			}
			'version' {
				gen_opt = 'ggetopt.opt_version()'
			}
			else {
				ll := if l := opt.long { '"${l}"' } else { 'none' }
				ss := if s := opt.short { '`${s}`' } else { 'none' }
				gen_opt = 'ggetopt.opt(${ll}, ${ss})'
				if arg := opt.arg {
					gen_opt += '.arg("${arg.name}", ${!arg.optional})'
				}
				if help := opt.help {
					gen_opt += '.help("${help}")'
				}
			}
		}
		gen_opt += ','
		gen_opts << gen_opt
	}
	content := 'import edam.ggetopt
const opts = [
    ${gen_opts.join('\n        ')}
]
fn proc_fn(arg string, optarg ?string) ! {
    if arg == "version" { ggetopt.print_version("x", ["y"]) exit(0) }
    if arg == "help" { ggetopt.print_help(opts) exit(0) }
}
fn main() {
    ggetopt.getopt_long_cli(opts, proc_fn) or { exit(1) }
}'
	vfile := os.join_path(os.vtmp_dir(), rand.string(8) + '.v')
	os.write_file(vfile, content) or { panic(err) }
	return &OptTester{
		options: options
		vfile: vfile
	}
}

fn mock_procfn(arg string, optarg ?string) ! {
}

fn (ot &OptTester) fail_with(args string, expect_err string) {
	// call directly
	if rest := getopt_long(args.split(' '), ot.options, mock_procfn) {
		println(rest)
		assert false // should have failed
	} else {
		assert err.msg() == expect_err
	}
}

fn run(cmd string) (int, string, string) {
	println(cmd)
	args := cmd.split(' ')
	exe := os.find_abs_path_of_executable(args[0]) or { panic(err) }
	mut p := os.new_process(exe)
	p.set_args(args[1..])
	p.set_redirect_stdio()
	p.run()
	p.wait()
	code := p.code
	out := p.stdout_slurp()
	err := p.stderr_slurp()
	p.close()
	println('exit: ${code}')
	println('out: ${out}')
	println('err: ${err}')
	return code, out, err
}

fn (ot &OptTester) run_ok(args string) {
	code, _, _ := run('v run ${ot.vfile} ${args}')
	assert code == 0
}

fn (ot &OptTester) run_fail(args string) {
	code, _, err := run('v run ${ot.vfile} ${args}')
	assert code != 0
	assert err.len > 0
}

fn (ot &OptTester) run_version() {
	code, out, err := run('v run ${ot.vfile} --version')
	assert code == 0
	app := os.base(ot.vfile)[..8]
	assert out == '${app} x\ny\n'
}

fn (ot &OptTester) cleanup() {
	os.rm(ot.vfile) or { panic(err) }
}
