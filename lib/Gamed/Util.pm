package Gamed::Util;

use Exporter 'import';
use Gamed::Util::Bag;

our @EXPORT = qw/bag/;

sub bag {
	return Gamed::Bag->new(@_);
}

1;
