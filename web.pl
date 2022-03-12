#!/usr/bin/env perl

use Mojolicious::Lite -signatures;

use Mojo::Pg;
use Mojo::IOLoop;
use Mojo::ByteStream qw(b);
use Mojo::Collection qw(c);

use Data::Pageset;
use Cpanel::JSON::XS;

use constant MOJO_MODE_DEVELOPMENT => 'developement';
use constant MOJO_MODE_PRODUCTION  => 'production';

# BEGIN {};

# Appliction config
app->moniker('sevstar perl test');

my $config = plugin 'Config', file => app->home->child('app.conf');

app->config($config);
app->secrets($config->{'secrets'});
app->defaults({
  'entries_per_page' => 5,
  'pages_per_set'    => 5,
  'max_connections'  => 10
});

app->log->path(app->config('log'));

# $ENV{MOJO_MODE} = MOJO_MODE_PRODUCTION;

if (app->mode eq MOJO_MODE_DEVELOPMENT) {
    app->log->on(message => sub ($log, $level, @lines) {
      say "$level: ", @lines ;
    });
}

# Database support
helper pg => sub {
  my $self = shift;
  state $pg = Mojo::Pg->new( $self->app->config('pg') )
    ->max_connections($self->app->defaults('max_connections'))
};

# plugin 'PODViewer';

# Database versioning
# See migration.sql for details
app->log->info('Run database migrations');

# If migration file does not exists or something went wrong
eval { 
  app->pg->migrations->from_file(
    app->home->child('migration.sql')
  )->migrate
};
my $e = $@ if defined $@;
app->log->error('Migrate failed with message "'
               . $e . '". Near ' . __FILE__ .':'. __LINE__)
  && die $e
  if $e;

# Routes
get '/' => sub ($c) {
  $c->render_later;

  my $page  = $c->param('page') || 1;
  my $entries_per_page = $c->app->defaults('entries_per_page');
  my $where = {};

  my $count = $c->app->pg->db->select('url',
    [
      \'COUNT(id) AS num'
    ],
    $where,
    {
      'order_by' => { -asc => \'id'},
      'group_by' => \'id'
    }
  );

  my $page_info = Data::Pageset->new({
    'total_entries'       => $count->rows, 
    'entries_per_page'    => $entries_per_page, 
    'current_page'        => $page,
    'pages_per_set'       => $c->app->defaults('pages_per_set'),
    'mode'                => 'slide',
  });

  my $rows = $c->app->pg->db->select('url',
    ['*'],  
    $where,
    {
      'order_by' => { -asc => 'id'},
      'limit' => $entries_per_page,
      'offset' => ($page-1)*$entries_per_page
    }
  );
  $c->render('template' => 'list', 'rows' => $rows->hashes, 'page_info' => $page_info);
} => 'url.list';

post '/' => sub ($c) {
  if ($c->param('location') ne '') {
    my $location = b($c->param('location'))->decode;

    if ($c->app->pg->db->select('url', ['*'], {'location' => $location})->rows) {
      $c->flash(
        'warn' => sprintf('Url with location "%s" already exists', $location)
      );
      $c->redirect_to($c->url_for('url.list'));
    } else {
      my $row = $c->app->pg->db->insert('url', {'location' => $location}, {'returning' => 'id'})->hash;
      $c->app->pg->pubsub->notify('url' => $row->{id});
      $c->flash(
        'info' => sprintf('Url with location "%s" added', $location)
      );
      $c->redirect_to($c->url_for('url.detail', {id => $row->{id}}));
    }
  }
} => 'url.create';

del '/' => sub ($c) {
  $c->render_later;

  $c->app->pg->db->delete('url' => {'id' => $c->param('id')} => {'returning' => 'location'} => sub ($db, $err, $results){
    $c->flash(
      'info' => sprintf('Url with location "%s" was deleted', $results->hash->{'location'})
    );
    $c->redirect_to('/');
  });
} => 'url.delete';

get '/:id' => sub ($c) {
  $c->render_later;

  $c->app->pg->db->select('url', ['*'], {'id' => $c->param('id')} => sub ($db, $err, $results) {
    $results->expand;
    $c->render(
      'template' => 'detail',
      'result' => $results->hash
    );
  });
} => 'url.detail';

post '/:id' => sub ($c) {
  if ($c->app->pg->db->select('url', ['*'], {'id' => $c->param('id')})->rows) {
    my $result = $c->app->pg->db->update('url',
      {'location' => b($c->param('location'))->encode},
      {'id' => $c->param('id')},
      {'returning' => 'id'}
    );
    if (!$result->rows) {
      $c->flash('error' => "URL was not updated")
    } else {
      $c->flash('info' => "URL was successfully updated");
    }
    my $row = $result->hash;
    $c->app->pg->db->notify(url => $row->{'id'});
    $c->redirect_to('url.detail', { 'id' => $row->{'id'} });
  }
} => 'url.update'; 

app->start;
