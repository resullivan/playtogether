package Gamed::Game::SpeedRisk::Placing;

use parent 'Gamed::State';

sub build {
}

sub on_enter_state {
	my ($self, $game) = @_;
	my @countries;
	$game->broadcast({ cmd=>'state', state=>'Placing', countries=>\@countries });
}

sub on_message {
}

sub on_leave_state {
}

1;
