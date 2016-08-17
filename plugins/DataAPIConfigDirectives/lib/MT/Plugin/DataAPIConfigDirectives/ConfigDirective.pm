package MT::Plugin::DataAPIConfigDirectives::ConfigDirective;
use strict;
use warnings;

use base 'Class::Accessor::Fast';

use boolean ();
use Class::Method::Modifiers;

use MT;
use MT::Plugin::DataAPIConfigDirectives::ConfigDirectiveList;

__PACKAGE__->mk_ro_accessors(qw/ name /);

around 'new' => sub {
    my $orig = shift;
    my $self = $orig->(@_);
    die unless $self->name;
    $self;
};

sub fields {
    qw( name type value updatable );
}

sub value {
    my $self = shift;
    return MT->config( $self->name, $_[0], 1 ) if @_;
    $self->type eq 'ARRAY'
        ? [ MT->config( $self->name ) ]
        : MT->config( $self->name );
}

sub type {
    my $self = shift;
    MT->config->type( $self->name );
}

sub updatable {
    my $self = shift;
    MT->config->is_readonly( $self->name )
        ? boolean::false()
        : boolean::true();
}

sub load {
    my $class = shift;
    my $terms = shift || +{};
    my $args  = shift || +{};

    my $config_directives = $class->_get_config_directives_from_registry;
    my $list = MT::Plugin::DataAPIConfigDirectives::ConfigDirectiveList->new(
        $config_directives);

    my @fields = grep { $_ ne 'value' } $class->fields;
    $list->filter( $_, $terms->{$_} ) for @fields;
    $list->sort( $args->{sort}, $args->{direction} );
    $list->limit( $args->{limit} );

    wantarray ? @{ $list->array_ref } : $list->array_ref->[0];
}

sub count {
    my $class             = shift;
    my $terms             = shift || +{};
    my @config_directives = $class->load($terms);
    scalar @config_directives;
}

sub save {
    my $self = shift;
    return 0 unless $self->updatable;
    MT->config( $self->name, $self->value );
    MT->config->save_config;
}

sub reset {
    my $self = shift;
    return 0 unless $self->updatable;
    delete MT->config->{__dbvar}{$self->name};
    MT->config->save_config;
}

sub hash_ref {
    my $self = shift;
    my %hash;
    $hash{$_} = $self->$_ for $self->fields;
    \%hash;
}

sub _get_config_directives_from_registry {
    my $class = shift;
    +[  map { $class->new( { name => $_ } ) }
            keys %{ MT->registry('config_settings') }
    ];
}

1;

