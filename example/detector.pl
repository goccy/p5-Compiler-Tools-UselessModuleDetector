#! /usr/bin/env perl
use strict;
use warnings;
use Compiler::Tools::UselessModuleDetector;


my $detector = Compiler::Tools::UselessModuleDetector->new();
my $results = $detector->detect(\@ARGV);
my $notice = '';
foreach (@$results) {
    $notice .= <<"NOTICE";
    filename : $_->{name}
    modules  : @{$_->{modules}}
NOTICE
}

print $notice, "\n";
