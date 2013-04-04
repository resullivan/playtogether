use strict;
use warnings;

use Test::More;
use Gamed::Test;
use Data::Dumper;
use Test::Builder;
my $tb = Test::Builder->new;

my ( $game, $n, $e, $s, $w ) = game(
    [qw/n e s w/],
    {
        seat        => [ {}, {}, {}, {} ],
        state_table => {
            start => Gamed::State::Dealing->new(
                {
                    next => 'end',
                    deck => Gamed::Object::Deck::Rook->new('partnership'),
                    deal => { seat => 10, nest => 5 },
                } ) } } );

$e->game( { do => 'deal' }, { reason => 'Not your turn' }, 'Deal out of turn' );
$n->game( { do => 'deal' } );
my $rook = qr/(\d+[RGBY])|0/;
check_deal( $rook, 10 );
is( scalar( $game->{nest}->values ), 5, "5 cards in the nest" );

change_state($game, 'start');
$e->game( { do => 'deal' } );
check_deal( $rook, 10 );
is( scalar( $game->{nest}->values ), 5, "5 cards in the nest" );

$game->{state_table}{start}->build( { next => 'end', deck => Gamed::Object::Deck::FrenchSuited->new('normal'), deal => 13 } );
change_state($game, 'start');
my $french = qr/([\dJQKA]+[SHCD])/;
$n->game( { do => 'deal' } );
check_deal( $french, 13 );

$game->{state_table}{start}{deal} = { seat => 13, dummy => 13 };
pop @{ $game->{seat} };
pop @{ $game->{players} };
change_state($game, 'start');
$e->game( { do => 'deal' } );
check_deal( $french, 13 );
is( scalar( $game->{dummy}->values ), 13, "13 cards to dummy" );

sub check_deal {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $re, $cards ) = @_;
    broadcast_one(
        $game,
        {
            hand => sub { grep( /$re/, @{ $_[0] } ) == $cards }
        },
        'Hand Dealt'
    );
    for my $s ( @{ $game->{seat} } ) {
        is( scalar( $s->{cards}->values ), $cards, "Game kept record of cards dealt to player" );
    }
    is( $game->{leader}, $game->{state_table}{start}{dealer}, 'leader set' );
    is( ref( $game->{state} ), 'Gamed::State', "Finished dealing" );
}

sub change_state {
	my ($game, $state) = @_;
	$game->change_state($state);
	$game->_change_state;
}

done_testing;
