package Application::Model::Abstract {
use Mojo::Base 'Mojo::EventEmitter', -signatures;

  has '_name';
  has '_pg';
  has '_priamry' => 'id';

  sub new {
    my $class = shift;
    bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
  }

  sub getAdapter { shift->_pg }
  sub getPrimary { shift->_priamry }
  sub getTableName { shift->_name }

  sub insert ($self, @args) {
    return $self->getAdapter()->db->insert($self->getTableName(), @args);
  }
  sub select ($self, @args) {
    return $self->getAdapter()->db->select($self->getTableName(), @args);
  }
  sub update ($self, @args) {
    return $self->getAdapter()->db->update($self->getTableName(), @args);
  }
  sub delete ($self, @args) {
    return $self->getAdapter()->db->delete($self->getTableName(), @args);
  }

  sub find ($self, @args) { $self->find_by($self->getPrimary, @args)->hash }
  sub find_by { shift->select(undef, { (shift) => shift }, shift) }

  1;
}
