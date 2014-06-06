#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::Server::Daemon;
use EV;
use AnyEvent;
use Mojo::IOLoop;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Gamed;
use Gamed::Player;

get '/' => sub {
    shift->render_static('index.html');
};

websocket '/websocket' => sub {
    my $self = shift;
    my $player;
    $self->app->log->debug('WebSocket connected.');
    Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
    $player = Gamed::Player->new( { sock => $self } );
    $self->send('{"cmd":"login"}');
    $self->on(
        message => sub {
            my ( $self, $msg ) = @_;
            eval { $player->handle($msg); };
            $player->err($@) if $@;
        } );

    $self->on(
        finish => sub {
            my $self = shift;
            $player->disconnected();
            delete $player->{sock};
            $self->app->log->debug('WebSocket disconnected.');
        } );
};

my $daemon = Mojo::Server::Daemon->new( app => app, listen => ['http://*:3000'] );
$daemon->app->home->parse( catdir( dirname(__FILE__), '..', 'Gamed' ), 'Gamed' );
$daemon->app->static->paths->[0]   = $daemon->app->home->rel_dir('public');
$daemon->app->renderer->paths->[0] = $daemon->app->home->rel_dir('public');
$daemon->run;

AE::cv->recv;
