use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my $game  = bless { called => 'AC', public => { rules => { play_to => 42 } }, state => {} }, 'Gamed::Game::Spitzer';
my $logic = Gamed::Game::Spitzer::PlayLogic->new;
my $hand  = bag(qw/AD AC 7D 10C 9D/);

good_play( '7D', [], 'Lead valid card' );
fail_play( 'AH', [], 'Lead invalid card' );
good_play( '7D', ['9D'], 'Follow suit' );
good_play( '7D', ['QC'], 'Follow suit, Q is trump' );
good_play( '7D', ['JH'], 'Follow suit, J is trump' );
fail_play( '1D', ['5C'], "Must follow suit" );
good_play( '9D', ['AS'], "Must trump if you don't have lead" );
fail_play( 'AC', ['AS'], 'Must play trump if you don\'t have lead' );
good_play( '10C', [], "Can lead something other than the called ace in suit" );
fail_play( '10C', ['9C'], "Must play ace if called suit is led" );
good_play( 'AC', ['9C'], "Must play ace if called suit is led" );

$game->{state}{suits_led}{C} = 1;
good_play( '10C', ['9C'], "Must play ace if called suit is led, unless you led the suit earlier" );

$hand = bag([ 'KH', 'JH', 'KS', '8S', 'QH', '10H', '9D', 'QC' ]);
fail_play( 'KH', ['8C'], "Must trump" );
good_play( 'JH', ['8C'], "Trump when don't have suit" );
fail_play( 'KS', ['8C'], "Must trump" );
fail_play( '8S', ['8C'], "Must trump" );
good_play( 'QH', ['8C'], "Trump ok when no suit" );
fail_play( '10H', ['8C'], "Must trump" );
good_play( '9D', ['8C'], "Trump ok when no suit" );
good_play( 'QC', ['8C'], "Trump ok when no suit" );

$hand = bag(qw/AS AC 7S 10C 9S/);
fail_play( 'AC', ['9H'], "Can't slough called ace" );
good_play( '10C', ['9H'], "Can play anything else if don't have trump or lead" );

$hand = bag(qw/JS AC 7S 10C 9S/);
good_play( '9S', ['8S'], "Follow suit" );
fail_play( 'JS', ['8S'], "J is trump, not spade" );

$logic->{reztips} = 1;
good_play( '9S', ['8S'], "Follow suit" );
good_play( 'JS', ['8S'], "J is a spade when reztips is active" );

$hand = bag(qw/JS AC 7S 10C 9D/);
fail_play( '9D', ['8S'], "Must follow suit - reztips" );
good_play( 'JS', ['8S'], "Must follow suit - reztips" );
$logic->{reztips} = 0;

$hand = bag('AC');
good_play( 'AC', ['9H'], "Can play called ace if it is all you have" );

is( $logic->trick_winner( [qw/9D JD 8D/],  $game ), 1, 'High card wins' );
is( $logic->trick_winner( [qw/9D KD QD/],  $game ), 2, 'Q is high' );
is( $logic->trick_winner( [qw/9D KD JD/],  $game ), 2, 'J is high' );
is( $logic->trick_winner( [qw/9S 10C AH/], $game ), 0, 'Non suit loses' );
is( $logic->trick_winner( [qw/9S AS 8D/],  $game ), 2, 'Trump wins' );
is( $logic->trick_winner( [qw/9S QD AS/],  $game ), 1, 'Trump wins' );
is( $logic->trick_winner( [qw/9G 7D QS/],  $game ), 1, 'High trump wins' );
is( $logic->trick_winner( [qw/9H 10H AH 7H/],  $game ), 2, 'High card wins' );

$logic->{reztips} = 1;
is( $logic->trick_winner( [qw/9S QC AS/],  $game ), 1, 'Trump wins' );
is( $logic->trick_winner( [qw/KC QC AS/],  $game ), 0, 'Lost the queen to reztips' );
is( $logic->trick_winner( [qw/AC JC AS/],  $game ), 0, 'Lost the jack to reztips' );
is( $logic->trick_winner( [qw/QC KC AS/],  $game ), 0, 'Reztips not active if trump led' );
is( $logic->trick_winner( [qw/8D KC QC/],  $game ), 2, 'Reztips not active if trump led' );
$logic->{reztips} = 0;

round_end(
    name         => 'Make normal',
    type         => 'normal',
    calling_team => [ 'n', 'e' ],
    end_points   => { n => 3, e => 3, s => 0, w => 0 },
    state        => 'Dealing',
    taken => [ [qw/AS AC AD/], [qw/10S 10C 10D/], [], [] ] );

round_end(
    name         => 'Badly lose sneaker',
    type         => 'sneaker',
    calling_team => ['n'],
    end_points   => { n => 0, s => 9, e => 9, w => 9 },
    state        => 'Dealing',
    taken => [ [qw/QC QD QS QH/], [], [], [] ] );

my $full_deck = Gamed::Object::Deck::FrenchSuited->new('spitzer')->generate_cards;

round_end(
    name         => 'Standard Game over with all tricks taken',
    type         => 'zola',
    calling_team => ['n'],
    start_points => { n => 9, s => 18, e => 21, w => 15 },
    end_points   => { n => 45, s => 18, e => 21, w => 15 },
    state        => 'Game Over',
    taken => [ $full_deck, [], [], [] ] );

round_end(
    name         => 'Game over with horrible loss (got no tricks)',
    type         => 'schneider',
    calling_team => [ 'n', 's' ],
    start_points => { n => 9, s => 18, e => 24, w => 15 },
    end_points   => { n => 9, s => 18, e => 42, w => 33 },
    state        => 'Game Over',
    taken => [ [], [], [], [] ] );

round_end(
    name         => 'Tie continues game',
    type         => 'normal',
    calling_team => [ 'n', 'e' ],
    start_points => { n => 36, s => 9, e => 36, w => 24 },
    end_points   => { n => 42, s => 9, e => 42, w => 24 },
    state        => 'Dealing',
    taken => [ [qw/AC AH AD AS JC JH QD/], [qw/10C 10H 10D 10S/], [], [] ] );

done_testing;

sub good_play {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( $logic->is_valid_play( shift, shift, $hand, $game ), shift );
}

sub fail_play {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( !$logic->is_valid_play( shift, shift, $hand, $game ), shift );
}

sub round_end {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my %opts = @_;
    my $game = bless {
        states => {
            DEALING   => bless( { name => 'Dealing' },   'Gamed::State' ),
            GAME_OVER => bless( { name => 'Game Over' }, 'Gamed::State' ),
        },
        state        => bless( { name => 'start' }, 'Gamed::State' ),
        seats        => [qw/n e s w/],
        type         => $opts{type},
        calling_team => $opts{calling_team},
        public       => { rules => { play_to => 42 } },
        players => {
            n => { taken => $opts{taken}[0], public => { points => $opts{start_points}{n} || 0 } },
            e => { taken => $opts{taken}[1], public => { points => $opts{start_points}{e} || 0 } },
            s => { taken => $opts{taken}[2], public => { points => $opts{start_points}{s} || 0 } },
            w => { taken => $opts{taken}[3], public => { points => $opts{start_points}{w} || 0 } },
        },
      },
      'Gamed::Game::Spitzer';

    $logic->on_round_end($game);
    Gamed::States::after_star($game);
    my $name = $opts{name};
    is( $game->{players}{n}{public}{points}, $opts{end_points}{n}, "n points" );
    is( $game->{players}{e}{public}{points}, $opts{end_points}{e}, "e points" );
    is( $game->{players}{s}{public}{points}, $opts{end_points}{s}, "s points" );
    is( $game->{players}{w}{public}{points}, $opts{end_points}{w}, "w points" );
    is( $game->{state}{name},                $opts{state},         "$name - state" );
}
