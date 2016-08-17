package MT::Plugin::DataAPIConfigDirectives::ConfigDirectiveList;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $config_directives = ref $_[0] eq 'ARRAY' ? $_[0] : \@_;
    bless +{ config_directives => $config_directives }, $class;
}

sub _config_directives {
    my $self = shift;
    $self->{config_directives};
}
*array_ref = \&_config_directives;

sub filter {
    my ( $self, $field, $value ) = @_;
    return unless $self->_count;
    return unless $field && defined $value;
    if ( $field eq 'updatable' ) {
        $value = 1 if $value eq 'true';
        $value = 0 if $value eq 'false';
    }
    @{ $self->_config_directives }
        = grep { $_->$field eq $value } @{ $self->_config_directives };
}

sub sort {
    my ( $self, $field, $direction ) = @_;
    return unless $self->_count;
    return unless $field;
    my $block;
    if ( $direction && lc $direction eq 'descend' ) {
        $block = sub { $_[1]->$field cmp $_[0]->$field };
    }
    else {
        $block = sub { $_[0]->$field cmp $_[1]->$field };
    }
    @{ $self->_config_directives }
        = sort { $block->( $a, $b ) } @{ $self->_config_directives };
}

sub limit {
    my ( $self, $count ) = @_;
    return unless $self->_count && $count;
    return unless $self->_count > $count;
    @{ $self->_config_directives }
        = @{ $self->_config_directives }[ 0 .. $count - 1 ];
}

sub _count {
    my $self  = shift;
    my $count = @{ $self->{config_directives} };
}

1;

