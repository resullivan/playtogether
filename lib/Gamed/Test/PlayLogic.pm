package Gamed::Test::PlayLogic;

sub new {
    bless {}, shift;
}

sub is_valid_play {
    my ( $self, $card, $trick, $hand ) = @_;
    return unless $hand->contains($card);
    my $min = 100;
    for ( $hand->values ) {
        $min = $_ if $_ < $min;
    }
    return $card == $min;
}

sub trick_winner {
    my ( $self, $trick, $game ) = @_;
    my $winning_seat  = 0;
    my $winning_value = 0;
    for my $p ( 0 .. $#$trick ) {
        if ( $trick->[$p] > $winning_value ) {
            $winning_seat  = $p;
            $winning_value = $trick->[$p];
        }
    }
    return $winning_seat;
}

sub on_trick_end {
    my ( $self, $game ) = @_;
    $game->broadcast( trick => { trick => $game->{public}{trick}, winner => $game->{public}{player}, leader => $game->{public}{leader} } );
}

sub suit { return 1 }

sub on_round_end {
    my ( $self, $game ) = @_;
    $game->change_state('end');
}

1;
