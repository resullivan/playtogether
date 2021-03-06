package Gamed::Game::RoboRally::Executing;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Executing' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;

    for my $p ( values %{ $game->{players} } ) {
        $p->{public}{ready} = 0;
    }

    $self->{register} = 1;
    $self->{phase}    = 0;
    $self->execute();
}

my @phase = (
    [ \&do_movement => 'movement' ],
    [ \&do_phase    => 'express_conveyors' ],
    [ \&do_phase    => 'conveyors' ],
    [ \&do_phase    => 'pushers' ],
    [ \&do_phase    => 'gears' ],
    [ \&do_phase    => 'lasers' ],
    [ \&do_touches  => 'touches' ],
    [ \&do_cleanup  => 'cleanup' ],
);

sub execute {
    my $self = shift;
    my $game = $self->{game};
    while (1) {
        my $func = $phase[ $self->{phase} ];
        last unless $func->[0]->( $self, $func->[1] );
        $self->{phase}++;
    }
}

sub do_movement {
    my ( $self, $phase ) = @_;
    my $current = $self->{register} - 1;
    my @register;
    for my $p ( values %{ $self->{game}{players} } ) {
        push @register, [ $p->{public}{bot} => $p->{private}{registers}[$current] ];
        $p->{public}{bot}{register}[$current]{program} = $p->{private}{registers}[$current];
    }
    my $actions = $self->{game}{public}{course}->do_movement( $current, \@register );
    $self->{game}->broadcast( execute => { phase => $phase, actions => $actions } ) if $actions;
    return 1;
}

sub do_phase {
    my ( $self, $phase ) = @_;
    my $method  = "do_$phase";
    my $actions = $self->{game}{public}{course}->$method( $self->{register} );
    $self->{game}->broadcast( execute => { phase => $phase, actions => $actions } ) if $actions;
    return 1;
}

#TODO Rewrite with course keeping pieces in tiles in addition to hash
sub do_touches {
    my $self = shift;
    my $tiles = $self->{game}{public}{course}{tiles};
    my ( @board, @touches, %phase );
    for my $p ( values %{ $self->{game}{public}{course}{pieces} } ) {
        if ($p->{type} eq 'flag') {
            push @{ $board[ $p->{x} ][ $p->{y} ] }, $p->{flag};
        }
    }

    for my $bot ( values %{ $self->{game}{public}{course}{pieces} } ) {
        if ($bot->{active} && $bot->{type} eq 'bot') {
            my @flags;
            if ($board[$bot->{x}][$bot->{y}]) {
                @flags = sort { $a <=> $b } @{$board[$bot->{x}][$bot->{y}]};
                for my $flag (@flags) {
                    if ( $bot->{flag} + 1 == $flag ) {
                        $bot->{flag}++;
                        $phase{flag}{ $bot->{id} } = $bot->{flag};
                    }
                }
            }
            my $tile = $tiles->[$bot->{y}][$bot->{x}]->{t};
            if (@flags) {
                $bot->{archive}{loc} = $self->{game}{public}{course}{pieces}{"flag_".$flags[-1]};
                $phase{archive}{ $bot->{id} } = $bot->{archive}{loc};
            }
            elsif ($tile eq 'upgrade' || $tile eq 'wrench') {
                if ( $bot->{archive}{loc}{x} != $bot->{x} || $bot->{archive}{loc}{y} != $bot->{y} ) {
                    $bot->{archive}{loc} = { x => $bot->{x}, y => $bot->{y} };
                    $phase{archive}{ $bot->{id} } = $bot->{archive}{loc};
                }
            }
        }
    }

    if ( keys %phase ) {
        $phase{phase} = 'touches';
        $self->{game}->broadcast( execute => \%phase );
    }
    return 1;
}

sub do_cleanup {
    my $self = shift;

    $self->{phase} = -1;    # The next step after running this is to increment phase on success

    if ( ++$self->{register} > 5 ) {
        $self->{game}->change_state("CLEANUP");
        return;
    }

    return 1;
}

1;
