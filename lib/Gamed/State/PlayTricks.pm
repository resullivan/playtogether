package Gamed::State::PlayTricks;

use parent 'Gamed::State';

sub build {
    my ( $self, $next, $logic ) = @_;
    $self->{next}   = $next;
    $self->{logic}  = $logic;
	$self->{trick}  = [];
}

sub on_enter_state {
    my ($self, $game) = @_;
    $self->{active_player} = $game->{leader};
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{id} ne $game->{players}[ $self->{active_player} ]{id} ) {
        $client->err('Not your turn');
        return;
    }

    my $seat = $game->{seat}[ $self->{active_player} ];
    if ($self->{logic}->is_valid_play($msg->{play}, $self->{trick}, $seat->{cards}, $game)) {
        push @{$self->{trick}}, $msg->{play};
        $seat->{cards}->remove($msg->{play});
        $game->broadcast( { player => $self->{active_player}, play => $msg->{play} } );
		$self->{active_player}++;
		$self->{active_player} = 0 if $self->{active_player} >= @{$game->{seat}};
        if (@{$self->{trick}} == @{$game->{seat}}) {
            $self->{active_player} = $self->{logic}->trick_winner($self->{trick}, $game) + $self->{active_player};
            $self->{active_player} -= @{$game->{seat}} if $self->{active_player} >= @{$game->{seat}};
            $game->broadcast( { trick => $self->{trick}, winner => $self->{active_player} } );
            $self->{trick} = [];
            if (grep ( scalar($_->{cards}->values), @{$game->{seat}}) == 0) {
                $game->change_state($self->{next});
            }
        }
    }
    else {
        $client->err('Invalid card');
    }
}

1;
