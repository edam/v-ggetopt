module ggetopt

fn test_line_wrapping() {
	assert gen_wraped_lines('', 10, 0) == []
	assert gen_wraped_lines(' ', 10, 0) == []
	assert gen_wraped_lines('     ', 10, 0) == []
	assert gen_wraped_lines('a', 10, 0) == ['a']
	assert gen_wraped_lines('a a', 10, 0) == ['a a']
	assert gen_wraped_lines(' a a', 10, 0) == ['a a']
	assert gen_wraped_lines('     a a', 10, 0) == ['a a']
	assert gen_wraped_lines('a a ', 10, 0) == ['a a']
	assert gen_wraped_lines('a a      ', 10, 0) == ['a a']
	assert gen_wraped_lines('       a      ', 10, 0) == ['a']
	assert gen_wraped_lines('                a               ', 10, 0) == ['a']
	assert gen_wraped_lines('aaaaaaaaaaaaaaaaaaaaaa', 10, 0) == [
		'aaaaaaaaaaaaaaaaaaaaaa',
	]
	assert gen_wraped_lines('a                    a', 10, 0) == ['a', 'a']

	assert gen_wraped_lines('abc def ghi jkl mno pqr', 11, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wraped_lines('abc def ghi  jkl mno pqr', 11, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wraped_lines('abc def ghi      jkl mno pqr', 11, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 12, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 13, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 14, 0) == ['abc def ghi', 'jkl mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 15, 0) == ['abc def ghi jkl', 'mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 10, 0) == ['abc def', 'ghi jkl', 'mno pqr']
	assert gen_wraped_lines('    abc def ghi jkl mno pqr', 10, 0) == ['abc def', 'ghi jkl', 'mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr    ', 10, 0) == ['abc def', 'ghi jkl', 'mno pqr']

	assert gen_wraped_lines('abc def ghi jkl mno pqr', 10, 2) == ['abc def', '  ghi jkl', '  mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 9, 2) == ['abc def', '  ghi jkl', '  mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 8, 1) == ['abc def', ' ghi jkl', ' mno pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 8, 2) == ['abc def', '  ghi', '  jkl', '  mno',
		'  pqr']
	assert gen_wraped_lines('abc def ghi jkl mno pqr', 1, 1) == ['abc', ' def', ' ghi', ' jkl',
		' mno', ' pqr']

	assert gen_wraped_lines('abc  def ghi jkl mno pqr', 10, 2) == ['abc  def', '  ghi jkl',
		'  mno pqr']
	assert gen_wraped_lines('abc    def ghi jkl mno pqr', 10, 2) == ['abc    def', '  ghi jkl',
		'  mno pqr']
	assert gen_wraped_lines('abc    def  ghi jkl mno pqr', 10, 2) == ['abc    def', '  ghi jkl',
		'  mno pqr']

	assert gen_wraped_lines('abc def ghi jkl mno pqr', 11, 4) == ['abc def ghi', '    jkl mno',
		'    pqr']

	assert gen_wraped_lines('abc def ghi jkl mno pqr', 11, 0) == ['abc def ghi', 'jkl mno pqr']
}

// fn test_opt_fns() {
//    assert opt(none, none).help == none
//    assert opt(none, none).help("foo").help != none
//    assert opt("a", none).help("foo").long != none
//    assert opt("a", none).help("foo").short == none
//    assert opt(none, `a`).help("foo").short != none
//    assert opt(none, `a`).help("foo").long == none
//    assert opt_help().help != none
//    assert opt_version().help != none
//}

fn test_help_line() {
    mut o := []OptDef{}

	c1 := PrintHelpConfig{
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

	o = [opt('aaa', none).arg('X',true).help('foo')]
	assert gen_help_lines(o, c1) == ['  --aaa=X  foo']
	o = [opt('aaa', none).arg('X', false).help('foo')]
	assert gen_help_lines(o, c1) == ['  --aaa[=X]  foo']
	o = [opt('aaa', none).arg('X',true).help('foo'), opt(none, `b`)]
	assert gen_help_lines(o, c1) == ['      --aaa=X  foo', '  -b']

	o = [opt(none, `a`).arg('X',true).help('foo')]
	assert gen_help_lines(o, c1) == ['  -a X  foo']
	o = [opt(none, `a`).arg('X', false).help('foo')]
	assert gen_help_lines(o, c1) == ['  -a [X]  foo']
	o = [opt(none, `a`).arg('X',true).help('foo'), opt('bbb', none)]
	assert gen_help_lines(o, c1) == ['  -a         foo', '      --bbb']
}
