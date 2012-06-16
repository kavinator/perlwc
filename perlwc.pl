#!/usr/bin/env perl
# perlwc — print newline, word and character counts for each file
# Copyright (c) 2012 Vladimir Petukhov (kavinator@gmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use 5.006;
use Getopt::Std;

my %options;
getopts( 'lwc', \%options );
my $opts;
$opts = [ keys \%options ];
$opts = [ qw( l w c ) ] unless @$opts;

my $total_data = {};
$$total_data{ $_ } = 0 for @$opts;
my $format  = ( "%8d " x @$opts ) . "%2s\n";
for my $file( @ARGV ) {
	open F, '<', $file or die "$0: $file: $!\n";
		my $file_data = {};
		$$file_data{ $_ } = 0 for @$opts;
		while ( <F> ) {
			$$file_data{ w } += grep { defined } split /\s+/ if 'w' ~~ @$opts;
			$$file_data{ c } += split // if 'c' ~~ @$opts;
		}
		$$file_data{ l }  = $. if 'l' ~~ @$opts;
		$$total_data{ $_ } += $$file_data{ $_ } for keys %$file_data;
		printf $format, @$file_data{ @$opts }, $file;
	close F;
}
printf $format, @$total_data{ @$opts }, 'total' if $#ARGV > 0;
