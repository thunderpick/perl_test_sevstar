package Application::Plugin::Model {
  use Mojo::Base 'Mojolicious::Plugin', -signatures;

  our $VERSION = '0.01';

  use Mojo::Loader qw(load_class);
  use Mojo::Util qw(camelize decamelize);

  sub register ($self, $app, $config) {
    
    $app->helper(model => sub ($c, $model, %args) {

      # User -> user -> App::Model::User
      # User::Profile -> user-profile -> App::Model::User::Profile
      # UserProfile -> user_profile -> App::Model::UserProfile

      $model = camelize(
        join('-', decamelize(ref $app), "model", lc decamelize($model))
      );

      my $e = load_class $model;
      # Can't load a model? Die, because 'load_class' returns an exception
      die qq{Loading "$model" failed: $e} if ref $e;

      # All is OK, return a model instance
      return $model->new(_pg => $app->pg, %args);
    });
  }

  1;
}

=encoding utf8

=head1 NAME

Application::Plugin::Model - Load a model

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Application::Plugin::Model');

  # Mojolicious::Lite
  plugin 'Application::Plugin::Model';

  # $c->model('url')->select(['fields'] => {where => clause} => sub ($db, $err, $results) {})

=head1 DESCRIPTION

L<Application::Plugin::Model> is a L<Mojolicious> plugin.

=head1 METHODS

L<Application::Plugin::Model> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
