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

my %options;
getopts( 'lwc', \%options );
my $opts;
$opts = [ keys %options ];
$opts = [ qw( l w c ) ] unless @$opts;

my $files = [ @ARGV ];
my $max_threads = 8;
my @tids_order;
my $threads_data = {};
my $total_data = {};
my $format = ( "%8d " x @$opts ) . "%2s\n";

$$total_data{ $_ } = 0 for @$opts;

# input: $file_name, ref_to_@opts
# return: ref_to_hash
sub analyze_file {
	my $name = shift;
	my $data = {};
	$$data{ $_ } = 0 for @{ +shift };
	open my $FILE, '<', $name or die "$0: $name: $!\n";
		while ( <$FILE> ) {
			$$data{ w }+= grep { $_ if defined } split /\s+/
				if defined $$data{ w };
			$$data{ c }+= split //
				if defined $$data{ c };
		}
		$$data{ l } = $. if defined $$data{ l };
	close $FILE;
	return $data;
}

# input: ref_to_%file_data, $file_name
sub thread_processing {
	my ( $data, $name ) = @_;
	if ( $data and $name ) {
		$$total_data{ $_ } += $$data{ $_ } for keys %$data;
		printf $format, @$data{ @$opts }, $name;
	}
}

for my $name ( @$files ) {
	for my $thr ( threads->list( threads::joinable ) ) {
		my $tid  = $thr->tid();
		my $data = $thr->join();
		if ( $tids_order[ 0 ] and ( $tids_order[ 0 ] == $tid ) ) {
			&thread_processing(
				$data,
				$threads_data->{ $tid }->{ name }
			);
			shift @tids_order;
		} else {
			$threads_data->{ $tid }->{ data } = $data;
		}
		$tid = $tids_order[ 0 ];
		if ( $tid and $threads_data->{ $tid } ) {
			$data = $threads_data->{ $tid }->{ data };
			if ( $data ) {
				&thread_processing(
					$data,
					$threads_data->{ $tid }->{ name }
				);
				shift @tids_order;
			}
		}
	}
	if ( threads->list( threads::running ) <= ( $max_threads - 1 ) ) {
		my $tid = threads->new( \&analyze_file, $name, $opts )->tid();
		push @tids_order, $tid;
		$threads_data->{ $tid } = { name => $name };
	} else {
		redo;
	}
}

for my $tid ( @tids_order ) {
	my $data = $threads_data->{ $tid }->{ data };
	my $name = $threads_data->{ $tid }->{ name };
	$data = threads->object( $tid )->join() unless $data;
	&thread_processing(
		$data,
		$name
	);
}

printf $format, @$total_data{ @$opts }, 'total' if scalar @$files > 0;
