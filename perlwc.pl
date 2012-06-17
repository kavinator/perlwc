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
use threads;

# input: $file_name, ref_to_@opts
# return: ref_to_hash
sub analyze_file {
	my $file = shift;
	my $opts = shift;
	my $data = {};
	$$data{ $_ } = 0 for @$opts;
	open F, '<', $file or die "$0: $file: $!\n";
		while ( <F> ) {
			$$data{ w }+= grep { $_ if defined } split /\s+/ if 'w' ~~ @$opts;
			$$data{ c }+= split // if 'c' ~~ @$opts;
		}
		$$data{ l } = $. if 'l' ~~ @$opts;
	close F;
	return $data;
}

my %options;
getopts( 'lwc', \%options );
my $opts;
$opts = [ keys \%options ];
$opts = [ qw( l w c ) ] unless @$opts;

my $total_data = {};
$$total_data{ $_ } = 0 for @$opts;

my $format = ( "%8d " x @$opts ) . "%2s\n";

my $thread = [];
for my $file ( @ARGV ) {
	push @$thread, {
		data => threads->new( \&analyze_file, $file, $opts ),
		file => $file,
	}
}

for my $th ( @$thread ) {
	my $data = $$th{ data }->join();
	my $file = $$th{ file };
	if ( $data and $file ) {
		$$total_data{ $_ } += $$data{ $_ } for keys %$data;
		printf $format, @$data{ @$opts }, $file;
	}
}

printf $format, @$total_data{ @$opts }, 'total' if $#ARGV > 0;
