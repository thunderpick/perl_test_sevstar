package Application::Model::Abstract {
	use Mojo::Base 'Mojo::EventEmitter', -signatures;

	has '_name';
	has '_pg';
	has '_priamry' => 'id';

	sub getAdapter { shift->_pg }
	sub getPrimary { shift->_priamry }
	sub getTableName { shift->_name }

	has '_methods' => sub ($self) {
    c(qw(insert select),
      qw(update delete)
    )->each(sub ($method, $index) {
      $self->attr($method => sub ($table, @args) {
        return $table->getAdapter()->db->select($table->getTableName(), @args);
      });
    })->to_array
	};

  for my $method (qw(insert select update delete)) {
    has $method => sub ($table, @args) {
      return $table->getAdapter()->db->select($table->getTableName(), @args);
    }
  }

  sub new {
    my $class = shift;
    bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
  }

  sub find ($self, @args) { $self->find_by($self->getPrimary, @args)->hash }
  sub find_by { shift->select(undef, { (shift) => shift }, shift) }

  1;
}
