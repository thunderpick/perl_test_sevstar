#!/usr/bin/env perl

use Mojolicious::Lite -signatures;

use Mojo::Pg;
use Mojo::IOLoop;
use Mojo::ByteStream qw(b);
use Mojo::Collection qw(c);

use Data::Pageset;
use Cpanel::JSON::XS;

use lib qw(lib);
use Application::Plugin::Model;
plugin 'Application::Plugin::Model';

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

state $log = new Mojo::Log( 'path' => $config->{'log'} );

# Database support
helper pg => sub {
  my $self = shift;
  state $pg = Mojo::Pg->new( $self->app->config('pg') )
    ->max_connections($self->app->defaults('max_connections'))
};

# Database versioning
# See migration.sql for details
app->log->info('Run database migrations');

# If migration file does not exists or something went wrong
eval { app->pg->migrations->from_file(app->home->child('migration.sql'))->migrate };
my $e = $@ if defined $@;
app->log->error('Migrate failed with message "' . $e . '". Near ' . __FILE__ .':'. __LINE__)
  && die $e
  if $e;

under sub ($c) {
  return 1 if $c->req->url->to_abs->userinfo && $c->req->url->to_abs->userinfo eq 'sevstar:s3cr3t';
  $c->res->headers->www_authenticate('Basic');
  $c->render(text => 'Authentication required!', status => 401);
  return undef;
};

get '/' => sub ($c) {
  $c->render_later;

  my $page  = $c->param('page') || 1;
  my $entries_per_page = $c->app->defaults('entries_per_page');
  my $where = {};

  my $count = $c->model('url')->select(
    [
      \'COUNT(id) AS num'
    ],
    $where,
    {
      'order_by' => { -asc => \'id' },
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

  my $rows = $c->model('url')->select(
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

    $c->flash(
      'warning' => sprintf(
        'Url with location "%s" already exists'
        , $location
      )
    ) and return $c->redirect_to($c->url_for('url.list'))
      if $c->app->pg->db->select('url', ['*'], {'location' => $location})->rows;

    my $row = $c->app->pg->db->insert('url', {'location' => $location}, {'returning' => '*'})->hash;
    $c->app->pg->pubsub->notify('url' => $row->{id});
    $c->flash(
      'info' => sprintf(
        'Url with location "%s" added',
        $row->{'location'}
      )
    );
    $c->redirect_to($c->url_for('url.detail', {id => $row->{id}}));

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
      $c->flash('danger' => "URL was not updated");
    } else {
      $c->flash('info' => "URL was successfully updated");
    }
    my $row = $result->hash;
    $c->app->pg->db->notify(url => $row->{'id'});
    $c->redirect_to('url.detail', { 'id' => $row->{'id'} });
  }
} => 'url.update';

app->start;
