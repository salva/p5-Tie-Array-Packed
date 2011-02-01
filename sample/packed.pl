#!/usr/bin/perl
# $Id: dataout $
# $Date: 1.27.11 $
# $HeadURL: adamant.net $
# $Revision: 2011 $
# $Source: /dataout.pl $
##################################################################################
use strict;
#use warnings;
use CGI::Carp;
use List::Util qw(sum);
use Math::Random::MT qw(rand);
#use Math::Random::MT::Auto qw(rand);
use Tie::Array::Packed;
use Tie::File;

our $VERSION = 2.80;

my $filename = $ARGV[0] || 'tmp/datatest.txt';

open my $DAT, '<', $filename or croak 'cannot open file';
my $dataa = <$DAT>;
close $DAT or croak 'cannot close SFILE';

my (
    $model,  $initial, $copyerr, $LST,    $file,
    $format, $timein,  $popyr,   $popest, $nul
);

#tmp/datatest.txt sample= 1|8|5|8|newt|2|1296234929|0,10,15,20,25,30,35,40,45,|5,10,15,10,15,25,20,30,20,|;
(
    $model,  $initial, $copyerr, $LST,    $file,
    $format, $timein,  $popyr,   $popest, $nul
) = split /[|]/xsm, $dataa;
my @mpe = split /\,/xsm, $popest;
my @mpy = split /\,/xsm, $popyr;

$#mpy = $LST;
$#mpe = $LST;

$mpy[0] = 0;

#set delimiters;
my ( $for1, $for2, $for3 );
if ( $format == 1 ) {
    $for1 = q{,};
    $for2 = q{csv};
    $for3 = q{"};     #";
}
elsif ( $format == 2 ) {
    $for1 = qq{\t};
    $for2 = q{tab};
    $for3 = q{};
}
else {
    $for1 = q{|};
    $for2 = q{txt};
    $for3 = q{};
}

#set file names
my $datafileout = q{data/} . $file . q{output} . $for2 . q{.} . $for2;

# CALCS
my @grand    = (0);
my @popbyyer = ( $mpe[0] );
my @test     = (0);
for my $y ( 1 .. $LST ) {
    my $y_diff = ( $mpy[$y] - $mpy[ $y - 1 ] ) || 1;
    my $e_diff = ( $mpe[$y] - $mpe[ $y - 1 ] );
    $popbyyer[$y] = $e_diff / $y_diff;
    $grand[$y] = $grand[ $y - 1 ] + ( ( $e_diff < 0 ) ? abs($e_diff) : 0 );
    if   ( $e_diff > 0 ) { $test[$y] = $e_diff; }
    else                 { $test[$y] = 0; }

}
my $gener = ( sort { $a <=> $b } @mpy )[-1];
my $total = $mpe[0] + sum(@test);

#build data table;
my @dr0 = ();
my @dr1 = ();
my @dr2 = ();
my @dr3 = ();
my @dr4 = ();
my @dr5 = ();
$dr0[0] = 0;
$dr3[0] = 0;
$dr5[0] = 0;
foreach my $tablem ( 1 .. $LST - 1 ) {
    $dr0[$tablem] = $mpy[$tablem] + 1;
    $dr3[$tablem] = $mpy[$tablem];
    $dr5[$tablem] = $grand[$tablem];
}
foreach my $tablen ( 0 .. $LST - 1 ) {
    $dr1[$tablen] = $mpy[ $tablen + 1 ];
    $dr2[$tablen] = $mpe[$tablen];
    $dr4[$tablen] = $popbyyer[ $tablen + 1 ];
}

tie my @aod, 'Tie::File', 'tmp/test.txt', recsep => "\n";
tie my @aob, 'Tie::Array::Packed::DoubleNative';
#my @aob = ();
write_to_output();
print qq{DONE!!\n}
  or croak 'unable to print to screen';
# system q{tkfinal.pl};

sub popnum1 {
    my ( $x, $y, $z ) = @_;
	my ($line);
    if ( $y == 0 ) {
        $aob[$x][0] = $initial + $z;
    }
    else {
    	$line = $aod[$y-1];
        if ( substr( $line, $x, 1 ) ne 'a' ) {
            $aob[$x][$y] = $initial + $z;
        }
        else {
            $aob[$x][$y] = $z + $aob[$x][ $y - 1 ];
        }
    }

    return $aob[$x][$y];
}

sub write_to_output {
    my $cell  = 0;
    my $cella = '';
    my $cello = '';
    open my $DATABASE, '>', $datafileout or croak 'dataout not made.';

    foreach my $drp ( 0 .. $LST - 1 ) {

        foreach my $y ( $dr0[$drp] .. $dr1[$drp] ) {
        	$cello = $aod[$y];
            for my $x ( 0 .. $total ) {
                if ( substr( $cello, $x, 1 ) eq 'd' ) {
                    $cella = qq{$for1};
                }
                elsif ( substr( $cello, $x, 1 ) eq 'a' ) {
                    my $copycop =
                      ( $copyerr - int rand( 1 + 2 * $copyerr ) ) / 100;

                    if ( $model == 1 ) {
                        $cell = sprintf '%.2f', popnum1( $x, $y, $copycop );
                    }
                    else {
                        $cell = sprintf '%.2f', popnum2( $x, $y, $copycop );
                    }
                    $cella = qq{$cell$for1};
                }

                else {
                    $cella = qq{$for1};
                }

                print {$DATABASE} $cella or croak 'unable to print';
            }
            print {$DATABASE} qq{\n} or croak 'unable to print';
            print qq{Printing line $y of $mpy[-1]\n}
              or croak 'unable to print to screen';
        }
    }
    close $DATABASE or croak 'data1 not closed.';
    return;
}

exit;

