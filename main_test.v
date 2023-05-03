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

	// inbuilt errors
	ot.fail_run('-x') // invalid option -- x
	ot.fail_run('--xxx') // unrecognised option '--xxx'

	// consistent errors
	ot.fail_with('-x', 'unrecognised option: -x')
	ot.fail_with('--xxx', 'unrecognised option: --xxx')
}

struct OptTester {
	options []OptDef
	vfile   string
}

fn new_opt_tester(options []OptDef) &OptTester {
	mut gen_opts := []string{}
	for opt in options {
		long := if l := opt.long { '"${l}"' } else { 'none' }
		short := if s := opt.short { '`${s}`' } else { 'none' }
		mut gen_opt := 'opt(${long}, ${short})'
		if arg := opt.arg {
			gen_opt += '.arg("${arg.name}", ${!arg.optional})'
		}
		if help := opt.help {
			gen_opt += '.help("${help}")'
		}
		gen_opt += ','
		gen_opts << gen_opt
	}
	content := '
fn mock_proc_fn(arg string, optarg ?string) ! {}
fn main() {
    o := [
        ${gen_opts.join('\n        ')}
    ]
    ggetopt.getopt_long_cli(options, opts.process_arg) or { exit(1) }
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

fn (ot &OptTester) fail_run(args string) {
	// run via OS
	vexe := os.find_abs_path_of_executable('v') or { panic(err) }
	mut p := os.new_process(vexe)
	p.set_args(args.split('run "${ot.vfile}" -- ${args}'))
	p.set_redirect_stdio()
	p.run()
	p.wait()
	assert p.code != 0
	assert p.stderr_slurp().len > 0
	p.close()
}

fn (ot &OptTester) cleanup() {
	os.rm(ot.vfile) or { panic(err) }
}
