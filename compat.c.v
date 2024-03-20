// Copyright (c) 2023 Tim Marston <tim@ed.am>.  All rights reserved.
// Use of this file is permitted under the terms of the GNU General Public
// Licence, version 3 or later, which can be found in the LICENCE file.

module ggetopt

//#flag darwin -I/usr/local/opt/readline/include
//#flag darwin -L/usr/local/opt/readline/lib
//#flag darwin -lgetopt
//#flag linux -lgetopt

#include <getopt.h>

struct C.option {
	name    &char
	has_arg int
	flag    &int
	val     int
}

fn C.getopt_long(argc int, argv &&char, shortopts &char, longopts &C.option, indexptr &int) int

fn init() {
	C.opterr = 0
}
