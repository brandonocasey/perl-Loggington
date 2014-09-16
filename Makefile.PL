use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Output2',
    license             => 'Commercial',
    dist_author         => 'Brandon Casey <brandon.casey@interoptechnologies.com>',
    build_requires      => {
        'FileHandle'      => 0,
        'Term::ANSIColor' => 0,
        'Data::Dumper'    => 0,
    },
    'test_files'        =>  [
    ],

);

# This will create a Build file in the directory so that you can run steps manually
# Helpfull for running ./Build install --uninst=1 (error that we keep getting)
#)->create_build_script;


$builder->dispatch('build');
# Run Unit tests and ask what to do on failure
eval
{
    $builder->dispatch('test');
    return 1;
} or do
{
    my $choice = "";
    while($choice ne 'yes' and $choice ne 'no')
    {
        print STDOUT "\nUnit Tests Failed, do you want to continue installing (type yes or no)?\n";
        chomp($choice = <>);
    }
    if($choice eq 'no')
    {
        print STDOUT "\nExiting!\n";
        exit;
    }
    else
    {
        print STDOUT "\nContinuing Installation, lets hope you know what your doing...\n";
    }
};

# Install
$builder->dispatch('install', uninst => 1);
# "Cleanup" old/depricated files here
$builder->dispatch('clean');
