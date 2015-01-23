package t::RoboRally;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/N E S W bot archive flag/;
use Gamed::Game::RoboRally::Pieces;

sub bot {
    my ( $id, $x, $y, $o ) = @_;
    return $id => Bot( $id, $x, $y, $o );
}

sub archive {
    my ( $id, $x, $y ) = @_;
    return "$id\_archive" => Archive( $id, $x, $y );
}

sub flag {
    my ( $id, $x, $y ) = @_;
    return "flag_$id" => Flag( $id, $x, $y );
}

1;
