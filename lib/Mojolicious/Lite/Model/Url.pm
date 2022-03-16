package Mojolicious::Lite::Model::Url;
use Mojo::Base 'Application::Model::Abstract', -base;

has '_name' => 'url';

has $_ for qw(
  id location created_at
  updated_at content code
);

1;
