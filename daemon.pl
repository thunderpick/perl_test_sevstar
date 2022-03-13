#!/usr/bin/env perl
use v5.30;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Mojo::Pg;
use Mojo::Log;
use Mojo::IOLoop;
use Mojo::UserAgent;
use Mojo::Collection qw(c);
use Mojo::Util qw(dumper);
use Mojo::File qw(path);

use Cpanel::JSON::XS;

state $config = require path('/root/app')->child('app.conf')->to_abs;
state $pg  = new Mojo::Pg( $config->{'pg'} );
state $log = new Mojo::Log( 'path' => $config->{'log'} );
state $ua  = new Mojo::UserAgent();

# $index for compatibility with Mojo::Collection::each
sub _fetch($hashRow, $index = undef) {
  $log->info(sprintf("Check url: %s", $hashRow->{location}));
  $ua->get($hashRow->{location} => sub ($ua, $tx) {
    my $result = {
      'code' => $tx->res->code,
      'headers' => encode_json(c(split /\r\n/, $tx->res->headers->to_string)->to_array),
      'content' => '' . $tx->res->body
    };
    
    $pg->db->update('url' => 
    	$result => {
    		'id' => $hashRow->{id}
  		} => {returning => '*'} =>
    	sub ($db, $err, $results)
	  	{
	    	my $row = $results->hash;
	    	$log->info(sprintf('Location[%d]: %s', $row->{code}, $row->{location}));
	  	}
		);
  })
}

sub _process ($loop) {
	$pg->db->select('url')->hashes->each(\&_fetch)
}

$pg->pubsub->listen(url => sub ($pubsub, $payload) {
  $pubsub->pg->db->select('url', ['*'], {'id' => $payload} => sub ($db, $err, $results) {
  	$log->info("recieved message:\nchannel: url\npayload: $payload");
    _fetch($results->hash);
  })
});

# Starts immediately
Mojo::IOLoop->recurring(5*60 => \&_process);
Mojo::IOLoop->next_tick(\&_process);

$log->info('Starting daemon');

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
