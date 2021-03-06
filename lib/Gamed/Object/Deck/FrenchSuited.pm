package Gamed::Object::Deck::FrenchSuited;

use parent 'Gamed::Object::Deck';

my %TYPE = (
    normal  => [ 2 .. 10, qw/J Q K A/ ],
    full    => [ 2 .. 10, qw/J Q K A/ ],
    piquet  => [ 6 .. 10, qw/J Q K A/ ],
    spitzer => [ 7 .. 10, qw/J Q K A/ ],
);

sub build {
    my ( $self, $type ) = @_;
    $type ||= 'full';
    $self->{type} = exists $TYPE{$type} ? $type : 'normal';
}

sub generate_cards {
    my $self = shift;
    my @cards;
    for my $suit ( 'S', 'H', 'C', 'D' ) {
        for my $v ( @{ $TYPE{$self->{type}} } ) {
            push @cards, "$v$suit";
        }
    }
    if ($self->{type} eq 'full') {
        push @cards, '0_', '0_';
    }
    return \@cards;
}

1;
