# Global reqs
requires 'perl', '>=5.30.0';
requires 'Mojolicious', '9.22';
requires 'File::Spec', '3.78';
requires 'Mojolicious::Plugin::PODViewer', '0.007';
# Database support
requires 'Mojo::Pg', '4.26';

# JSON support
requires 'Cpanel::JSON::XS', '4.27';

# Application reqs
requires 'Data::Pageset', '1.06';

# TLS support
requires 'Net::SSLeay', '1.88';
requires 'IO::Socket::SSL', '2.074';

# XML support
requires 'XML::LibXML::Reader', '2.0207';