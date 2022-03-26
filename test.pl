#!/usr/bin/env perl
use lib qw(lib);
use Singleton;

my $s1 = Singleton::getInstance();
my $s2 = Singleton::getInstance();
my $s3 = getInstance Singleton;
my $s4 = getInstance Singleton();

printf(
  "\$s1 and \$s2 are %s\n",
  ($s1 eq $s2 ? 'same' : 'different')
);

printf("\$s1=%s\n", $s1);
printf("\$s2=%s\n", $s2);
printf("\$s3=%s\n", $s3);
printf("\$s4=%s\n", $s4);