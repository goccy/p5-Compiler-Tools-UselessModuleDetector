package Compiler::Tools::UselessModuleDetector;
use 5.012004;
use strict;
use warnings;

### =================== Exporter ======================== ###
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.01';
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

### ============== Dependency Modules =================== ###

use Compiler::Lexer;
use List::MoreUtils qw(first_value);
use Module::CoreList;
use Data::Dumper;

my @ignore_modules = qw{
    strict
    warnings
    constant
};

sub new {
    my ($class, $options) = @_;
    my $ignore = +{};
    $ignore->{$_}++ foreach (@ignore_modules);
    my $self = {ignore => $ignore};
    return bless($self, $class);
}

sub detect {
    my ($self, $files) = @_;
    $self->__detect($_) foreach (@$files);
    return $self->{results};
}

sub __detect {
    my ($self, $filename) = @_;
    open my $fh, '<', $filename or die "failed to open file: $!";
    my $script = do { local $/; <$fh> };
    my $lexer = Compiler::Lexer->new($filename);
    my $modules = $lexer->get_used_modules($script);
    my %module_names;
    $module_names{$_->{name}} = $_->{args}
        foreach(grep {!exists $self->{ignore}->{$_->{name}}} @$modules);
    my $tokens = $lexer->tokenize($script);
    foreach my $token (@$tokens) {
        if ($token->{type} == Compiler::Lexer::TokenType::T_Class ||
            $token->{type} == Compiler::Lexer::TokenType::T_Namespace) {
            my $v = first_value { $token->{data} =~ /$_/ } keys %module_names;
            delete $module_names{$v} if (defined $v);
        }
    }
    $self->__add($filename, \%module_names) if (scalar keys %module_names > 0);
}

sub __add {
    my ($self, $filename, $module_name) = @_;
    push(@{$self->{results}}, { name => $filename, modules => [keys %$module_name] });
}

1;

__END__

