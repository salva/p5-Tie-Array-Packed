#!/usr/bin/perl

# See http://perlmonks.org/?node_id=1065851

use strict;
use warnings;
use 5.010;

use Tie::Array::Packed;
use Image::Magick;
use Math::Random qw(random_uniform);
my $file = shift @ARGV // die <<EOU;
Usage:
  $0 image_file [n [exp]]

EOU

my $n = shift @ARGV || 100;
my $exp = shift @ARGV || 1;
my $inv = shift;

my $img = Image::Magick->new;
$img->Read($file);

my $w = $img->Get('Width');
my $h = $img->Get('Height');

my $out = Image::Magick->new(size => join('x', $w * 3, $h));
$out->Read("xc:black");

tie my(@acu), 'Tie::Array::Packed::DoubleNative';
$#acu = $h * $w; # preallocate
$#acu = 1;

for my $j (0..$h-1) {
    for my $i (0..$w-1) {
        my @c = $img->GetPixel(x => $i, y => $j);
        $out->SetPixel(x => $i, y => $j, color => \@c);
        if ($inv) {
            $_ = 1.0 - $_ for @c;
            # warn "@c";
        }
        my $c = sqrt((1/3) * ($c[2] * $c[2] + $c[1] * $c[1] + $c[0] * $c[0])) ** $exp;
        push @acu, $acu[-1] + $c;
        $out->SetPixel(x => $w + $i, y => $j, color => [$c, $c, $c]);
    }
}

my $top = $acu[-1];
my $ref = tied(@acu);

for my $r (random_uniform($n, 0, $top)) {
    #map rand($top), 1..$n) {
    my $ix = $ref->bsearch_le($r);
    my $j = int($ix / $w);
    my $i = $ix - $j * $w;
    $out->SetPixel(x => $w * 2 + $i, y => $j, color => [1, 1, 1]);
}

$out->Annotate(pointsize => 18, stroke => 'black', fill => 'red', x => 5, y => $h - 5, text => "n: $n, exp: $exp");

$out->Write('out.png');
