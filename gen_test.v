module ggetopt

fn test_line_wrapping() {
	assert gen_wrapped_lines('', 10, 0) == []
	assert gen_wrapped_lines(' ', 10, 0) == []
	assert gen_wrapped_lines('     ', 10, 0) == []
	assert gen_wrapped_lines('a', 10, 0) == ['a']
	assert gen_wrapped_lines('a a', 10, 0) == ['a a']
	assert gen_wrapped_lines(' a a', 10, 0) == ['a a']
	assert gen_wrapped_lines('     a a', 10, 0) == ['a a']
	assert gen_wrapped_lines('a a ', 10, 0) == ['a a']
	assert gen_wrapped_lines('a a      ', 10, 0) == ['a a']
	assert gen_wrapped_lines('       a      ', 10, 0) == ['a']
	assert gen_wrapped_lines('                a               ', 10, 0) == ['a']
	assert gen_wrapped_lines('aaaaaaaaaaaaaaaaaaaaaa', 10, 0) == [
		'aaaaaaaaaaaaaaaaaaaaaa',
	]
	assert gen_wrapped_lines('a                    a', 10, 0) == ['a', 'a']

	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 11, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wrapped_lines('abc def ghi  jkl mno pqr', 11, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wrapped_lines('abc def ghi      jkl mno pqr', 11, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 12, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 13, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 14, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 15, 0) == ['abc def ghi jkl', 'mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 10, 0) == ['abc def', 'ghi jkl', 'mno pqr']
	assert gen_wrapped_lines('    abc def ghi jkl mno pqr', 10, 0) == ['abc def', 'ghi jkl',
		'mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr    ', 10, 0) == ['abc def', 'ghi jkl',
		'mno pqr']

	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 10, 2) == ['abc def', '  ghi jkl',
		'  mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 9, 2) == ['abc def', '  ghi jkl', '  mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 8, 1) == ['abc def', ' ghi jkl', ' mno pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 8, 2) == ['abc def', '  ghi', '  jkl',
		'  mno', '  pqr']
	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 1, 1) == ['abc', ' def', ' ghi', ' jkl',
		' mno', ' pqr']

	assert gen_wrapped_lines('abc  def ghi jkl mno pqr', 10, 2) == ['abc  def', '  ghi jkl',
		'  mno pqr']
	assert gen_wrapped_lines('abc    def ghi jkl mno pqr', 10, 2) == ['abc    def', '  ghi jkl',
		'  mno pqr']
	assert gen_wrapped_lines('abc    def  ghi jkl mno pqr', 10, 2) == ['abc    def', '  ghi jkl',
		'  mno pqr']

	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 11, 4) == ['abc def ghi', '    jkl mno',
		'    pqr']

	assert gen_wrapped_lines('abc def ghi jkl mno pqr', 11, 0) == ['abc def ghi', 'jkl mno pqr']
}

// fn test_opt_fns() {
//	assert opt(none, none).help == none
//	assert opt(none, none).help('foo').help != none
//	assert opt('a', none).help('foo').long != none
//	assert opt('a', none).help('foo').short == none
//	assert opt(none, `a`).help('foo').short != none
//	assert opt(none, `a`).help('foo').long == none
//	assert opt_help().help != none
//	assert opt_version().help != none
//}

fn test_help_line() {
	mut o := []OptDef{}

	c1 := PrintConfig{
		columns: 40
		max_offset: 20
	}

	o = [opt('aaa', `a`)]
	assert gen_help_lines(o, c1) == ['  -a, --aaa']
	o = [opt('aaa', `a`).help('foo')]
	assert gen_help_lines(o, c1) == ['  -a, --aaa  foo']
	o = [opt('aaa', `a`).arg('X', true).help('foo')]
	assert gen_help_lines(o, c1) == ['  -a, --aaa=X  foo']
	o = [opt('aaa', `a`).arg('X', false).help('foo')]
	assert gen_help_lines(o, c1) == ['  -a, --aaa[=X]  foo']

	o = [opt('aaa', none).arg('X', true).help('foo')]
	assert gen_help_lines(o, c1) == ['  --aaa=X  foo']
	o = [opt('aaa', none).arg('X', false).help('foo')]
	assert gen_help_lines(o, c1) == ['  --aaa[=X]  foo']
	o = [opt('aaa', none).arg('X', true).help('foo'), opt(none, `b`)]
	assert gen_help_lines(o, c1) == ['      --aaa=X  foo', '  -b']

	o = [opt(none, `a`).arg('X', true).help('foo')]
	assert gen_help_lines(o, c1) == ['  -a X  foo']
	o = [opt(none, `a`).arg('X', false).help('foo')]
	assert gen_help_lines(o, c1) == ['  -a [X]  foo']
	o = [opt(none, `a`).arg('X', true).help('foo'), opt('bbb', none)]
	assert gen_help_lines(o, c1) == ['  -a         foo', '      --bbb']

	o = [opt('aaa', `a`), opt('bbbbbbbbbb', none).help('x x x x x x x x x x y y y y')]
	assert gen_help_lines(o, c1) == ['  -a, --aaa', '      --bbbbbbbbbb  x x x x x x x x x x',
		'                      y y y y']
	o = [opt('aaa', `a`), opt('bbbbbbbbbbb', none).help('x x x x x x x x x x x x x x y y y y')]
	assert gen_help_lines(o, c1) == ['  -a, --aaa', '      --bbbbbbbbbbb',
		'             x x x x x x x x x x x x x x', '               y y y y']
	o = [opt('aaa', `a`), opt('bbbbbbbbbb', none).help('x x x x x x x x\nx x y y y y')]
	assert gen_help_lines(o, c1) == ['  -a, --aaa', '      --bbbbbbbbbb  x x x x x x x x',
		'                      x x y y y y']
	o = [opt('aaa', `a`), opt('bbbbbbbbbb', none).help('x x x x x x x x    \n\n\n    x x y y y y')]
	assert gen_help_lines(o, c1) == ['  -a, --aaa', '      --bbbbbbbbbb  x x x x x x x x',
		'                      x x y y y y']
	o = [opt('aaa', `a`), opt('bbbbbbbbbb', none).help('x x x x x x x x    \n  \n  \n    x x y y y y')]
	assert gen_help_lines(o, c1) == ['  -a, --aaa', '      --bbbbbbbbbb  x x x x x x x x',
		'                      x x y y y y']

	o = [opt('aaa', `a`).help('x x x y y')]
	c2 := PrintConfig{
		columns: 10
		min_columns: 16 // so max_offset is 8 and is limited by min_offset (10)
	}
	assert gen_help_lines(o, c2) == ['  -a, --aaa', '          x x x', '            y y']
	c3 := PrintConfig{
		columns: 10
		min_columns: 26 // so max_offset is 13 and line wrapping isn't necessary
	}
	assert gen_help_lines(o, c3) == ['  -a, --aaa  x x x y y']
	c4 := PrintConfig{
		columns: 10
		min_columns: 25 // so max_offset is 12 and line wrapping is necessary
	}
	assert gen_help_lines(o, c4) == ['  -a, --aaa', '          x x x y y']
}
