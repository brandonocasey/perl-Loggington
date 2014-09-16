#! /usr/bin/env perl
use strict;
use warnings;
use Output2;

# Default Config
Output2->error("New")->error("Second New");
Output2::error("Static")->error("Second Static");
my $o = Output2->get();
$o->error("Object")->error("Second Object");

print "Config Test\n";
Output2->config({'log_level' => 1});
Output2->error("New")->error("Second New");
Output2::error("Static")->error("Second Static");
$o = Output2->get();
$o->error("Object")->error("Second Object");
