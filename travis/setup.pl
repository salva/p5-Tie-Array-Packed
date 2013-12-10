#!/usr/bin/perl

use strict;
use warnings;

unless ($ENV{TRAVIS}) {
    die "This script is only intended to be run from Travis CI platform\n";
}

unlink "perl_math_int64.h";
symlink "dependencies/p5-Math-Int64/c_api_client/perl_math_int64.h", "perl_math_int64.h"
    or die "unable to symlink perl_math_int64.h: $!";

unlink "perl_math_int64.c";
symlink "dependencies/p5-Math-Int64/c_api_client/perl_math_int64.c", "perl_math_int64.c"
    or die "unable to symlink perl_math_int64.c: $!";

unlink "perl_math_int128.h";
symlink "dependencies/p5-Math-Int128/c_api_client/perl_math_int128.h", "perl_math_int128.h"
    or die "unable to symlink perl_math_int128.h: $!";

unlink "perl_math_int128.c";
symlink "dependencies/p5-Math-Int128/c_api_client/perl_math_int128.c", "perl_math_int128.c"
    or die "unable to symlink perl_math_int128.c: $!";

mkdir "dependencies";
chdir "dependencies" or die "unable to chdir to dependencies: $!";

system "git clone https://github.com/salva/p5-Module-CAPIMaker.git";
system "cd p5-Module-CAPIMaker && perl Makefile.PL && make install";

system "git clone https://github.com/salva/p5-Math-Int64.git";
system "cd p5-Math-Int64 && perl Makefile.PL && make install";

system "git clone https://github.com/salva/p5-Math-Int128.git";
system "cd p5-Math-Int128 && perl Makefile.PL && make install";
