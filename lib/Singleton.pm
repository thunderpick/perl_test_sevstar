package Singleton;

my $instance;

sub __new { bless {}, shift }

sub getInstance {
    $instance = __PACKAGE__->__new() unless $instance;
    return $instance;
}

1;

=encoding utf8

=head1 NAME

Singleton

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use lib qw(lib);
  use Singleton;
  
  my $s1 = Singleton::getInstance();
  my $s2 = Singleton::getInstance();
  my $s3 = getInstance Singleton;
  my $s4 = getInstance Singleton();

  # $s1 and $s2 are same
  printf(
    "\$s1 and \$s2 are %s\n",
    ($s1 eq $s2 ? 'same' : 'different')
  );

  # $s1=Singleton=HASH(0x55da0d477470)
  printf("\$s1=%s\n", $s1);

  # $s2=Singleton=HASH(0x55da0d477470)
  printf("\$s2=%s\n", $s2);

  # $s3=Singleton=HASH(0x55da0d477470)
  printf("\$s3=%s\n", $s3);

  # $s4=Singleton=HASH(0x55da0d477470)
  printf("\$s4=%s\n", $s4);
  

=head1 DESCRIPTION

Use a L<Singleton>.

=head1 SEE ALSO

L<Application::Plugin::Model>, L<http://82.146.44.41/>.

=cut
