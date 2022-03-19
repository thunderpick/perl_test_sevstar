package Application::Plugin::PODRenderer;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Asset::File;
use Mojo::ByteStream;
use Mojo::DOM;
use Mojo::File 'path';
use Mojo::URL;
use Mojo::Util 'deprecated';
use Pod::Simple::XHTML;
use Pod::Simple::Search;

sub register {
  my ($self, $app, $conf) = @_;

  deprecated 'Application::Plugin::PODRenderer is DEPRECATED'; 

  my $preprocess = $conf->{preprocess} || 'ep';
  $app->renderer->add_handler(
    $conf->{name} || 'pod' => sub {
      my ($renderer, $c, $output, $options) = @_;
      $renderer->handlers->{$preprocess}($renderer, $c, $output, $options);
      $$output = _pod_to_html($$output) if defined $$output;
    }
  );

  $app->helper(
    pod_to_html => sub { shift; Mojo::ByteStream->new(_pod_to_html(@_)) });

  # Perldoc browser
  return undef if $conf->{no_perldoc};
  my $defaults = {module => 'Application/Plugin/Model'};
  return $app->routes->any(
    '/perldoc/:module' => $defaults => [module => qr/[^.]+/] => \&_perldoc);
}

sub _indentation {
  (sort map {/^(\s+)/} @{shift()})[0];
}

sub _html {
  my ($c, $src) = @_;

  # Rewrite links
  my $dom     = Mojo::DOM->new(_pod_to_html($src));
  my $perldoc = $c->url_for('/perldoc/');
  $_->{href} =~ s!^https://metacpan\.org/pod/!$perldoc!
    and $_->{href} =~ s!::!/!gi
    for $dom->find('a[href]')->map('attr')->each;

  # Rewrite code blocks for syntax highlighting and correct indentation
  for my $e ($dom->find('pre > code')->each) {
    next if (my $str = $e->content) =~ /^\s*(?:\$|Usage:)\s+/m;
    next unless $str =~ /[\$\@\%]\w|-&gt;\w|^use\s+\w/m;
    my $attrs = $e->attr;
    my $class = $attrs->{class};
    $attrs->{class} = defined $class ? "$class prettyprint" : 'prettyprint';
  }

  # Rewrite headers
  my $toc = Mojo::URL->new->fragment('toc');
  my @parts;
  for my $e ($dom->find('h1, h2, h3, h4')->each) {

    push @parts, [] if $e->tag eq 'h1' || !@parts;
    my $link = Mojo::URL->new->fragment($e->{id});
    push @{$parts[-1]}, my $text = $e->all_text, $link;
    my $permalink = $c->link_to('#' => $link, class => 'permalink');
    $e->content($permalink . $c->link_to($text => $toc));
  }

  # Try to find a title
  my $title = 'Perldoc';
  $dom->find('h1 + p')->first(sub { $title = shift->text });

  # Combine everything to a proper response
  $c->content_for(perldoc => "$dom");
  $c->render('perldoc', title => $title, parts => \@parts);
}

sub _perldoc {
  my $c = shift;

  # Find module or redirect to CPAN
  my $module = join '::', split('/', $c->param('module'));
  $c->stash(cpan => "https://metacpan.org/pod/$module");
  my $path
    = Pod::Simple::Search->new->find($module, map { $_, "$_/pods" } @INC);
  return $c->redirect_to($c->stash('cpan')) unless $path && -r $path;

  my $src = path($path)->slurp;
  $c->respond_to(txt => {data => $src}, html => sub { _html($c, $src) });
}

sub _pod_to_html {
  return '' unless defined(my $pod = ref $_[0] eq 'CODE' ? shift->() : shift);

  my $parser = Pod::Simple::XHTML->new;
  $parser->perldoc_url_prefix('https://metacpan.org/pod/');
  $parser->$_('') for qw(html_header html_footer);
  $parser->strip_verbatim_indent(\&_indentation);
  $parser->output_string(\(my $output));
  return $@ unless eval { $parser->parse_string_document("$pod"); 1 };

  return $output;
}

1;