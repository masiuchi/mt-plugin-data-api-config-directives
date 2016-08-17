package MT::Plugin::DataAPIConfigDirectives::DataAPI::Endpoint;
use strict;
use warnings;

use boolean ();

use MT;
use MT::Plugin::DataAPIConfigDirectives::ConfigDirective;

my $cd_class = 'MT::Plugin::DataAPIConfigDirectives::ConfigDirective';

sub list {
    my $app = shift;
    return $app->permission_denied unless $app->user->is_superuser;

    my $terms = _get_terms_from_param($app);
    my $args  = _get_args_from_param($app);

    my $count = $cd_class->count($terms);
    my @config_directives = $cd_class->load( $terms, $args );

    +{  totalResults => $count,
        items        => [ map { $_->hash_ref } @config_directives ],
    };
}

sub get {
    my $app = shift;
    return $app->permission_denied unless $app->user->is_superuser;

    my $config_directive = _get_config_directive($app);
    return _not_found($app) unless $config_directive;

    $config_directive->hash_ref;
}

sub update {
    my $app = shift;
    return $app->permission_denied unless $app->user->is_superuser;

    my $config_directive = _get_config_directive($app);
    return _not_found($app) unless $config_directive;
    return _forbidden($app) unless $config_directive->updatable;

    my $hash = _get_value_hash_from_param($app);
    return _no_parameter($app) unless $hash && exists $hash->{value};

    my $value = $hash->{value};
    my $type  = _get_type($value);
    return _invalid_data_type($app)
        unless $type && $type eq $config_directive->type;

    $config_directive->value($value);
    $config_directive->save;

    $config_directive->hash_ref;
}

sub reset {
    my $app = shift;
    return $app->permission_denied unless $app->user->is_superuser;

    my $config_directive = _get_config_directive($app);
    return _not_found($app) unless $config_directive;
    return _forbidden($app) unless $config_directive->updatable;

    $config_directive->reset;
    $config_directive->hash_ref;
}

sub _get_config_directive {
    my $app              = shift;
    my $name             = $app->param('config_directive_name');
    my $config_directive = $cd_class->load( { name => $name } );
    $config_directive;
}

sub _get_value_hash_from_param {
    my $app  = shift;
    my $json = $app->param('config_directive');
    eval { $app->current_format->{unserialize}->($json) };
}

sub _get_terms_from_param {
    my $app = shift;
    my %terms;
    for my $f ( $cd_class->fields ) {
        $terms{$f} = $app->param($f) if defined $app->param($f);
    }
    \%terms;
}

sub _get_args_from_param {
    my $app = shift;
    my %args;
    for my $p (qw/ sort order limit /) {
        $args{$p} = $app->param($p) if defined $app->param($p);
    }
    \%args;
}

sub _get_type {
    my $value = shift;
    return 'SCALAR' unless ref $value;
    return ref $value if ref $value eq 'ARRAY';
    return ref $value if ref $value eq 'HASH';
    '';
}

sub _not_found {
    my $app = shift;
    $app->print_error( 'Not found.', 404 );
}

sub _forbidden {
    my $app = shift;
    $app->print_error( 'Forbidden to change.', 403 );
}

sub _invalid_data_type {
    my $app = shift;
    $app->print_error( 'Invalid data type.', 400 );
}

sub _no_parameter {
    my $app = shift;
    $app->print_error( 'Require config_directive parameter.', 400 );
}

1;

