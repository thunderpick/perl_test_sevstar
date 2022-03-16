use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {
    'Mojolicious' => '9.22',
    'File::Spec' => '3.78',
    'Mojo::Pg' => '4.26',
    'Cpanel::JSON::XS' => '4.27',
    'Data::Pageset' => '1.06',
    'Net::SSLeay' => '1.92',
    'IO::Socket::SSL' => '2.074',
    'XML::LibXML::Reader' => '2.0207',
  },
  test => {TESTS => 't/*.t'}
);
