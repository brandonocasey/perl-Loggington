package Output2;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(strftime);

our $VERSION = '2.0';

# Private Variables
my $log_instance;
my $class; # so I dont need to type __PACKAGE__ everywhere
my $config;
my $caller;

my $setup_handlers  = sub {
    my @handle_setup = ();
    my $handles = shift;
    while(@{$handles}) {
        my $handle = shift @{$handles};
        my $fh;
        if(ref($handle) and ref($handle) ne ref(\*STDOUT)) {
            die("Can only pass a GLOB ref, or file location to " . __PACKAGE__);
        } elsif(ref($handle) and ref($handle) eq ref(\*STDOUT)) {
            $fh = $handle;
        } elsif($handle eq 'STDOUT') {
            $fh = \*STDOUT;
        } elsif($handle eq 'STDERR') {
            $fh = \*STDERR;
        } elsif($handle =~ m/LOG_LOCAL(\d)/) {
            # Insert SYSLOG stuff
        } elsif($handle) {
            # truncate file
            $fh = FileHandle->new();
            $fh->open(">$handle");
            $fh->close();

            # append to file
            $fh = FileHandle->new();
            $fh->open(">>$handle");
        }

        push(@handle_setup, $fh);
    }
};

sub set_caller
{
    $caller = shift;
}

# Configure
sub config {
    while(@_) {
        my $arg = shift;
        if(ref($arg) ne ref({})) {
            die('Config options must be passed as a hash reference')
        }
        while(my ($key, $value) = each(%{$arg})) {
            $config->{$key} = $value;
        }
    }
    $config->{handles} = $setup_handlers->($config->{handles});
    return $class->get();
}

sub get {
    return $log_instance;
}

sub real {
    my $message = shift;
    if(!defined($message)) {
        $message = "'undef'";
    } elsif(ref($message)) {
        $message = Dumper($message);
    }
    return $message;
}

sub trim {
    my $message = shift;
    $message = $class->left_trim($message);
    $message = $class->right_trim($message);
    return $message;
}

sub left_trim
{
    my $message = shift;
    $message =~ s/^\s+//;
    return $message;
}

sub right_trim
{
    my $message = shift;
    $message =~ s/\s+$//;
    return $message;
}

# Private Functions Yay!?
# Initialize log, call pre process before every function
BEGIN {
    $class = __PACKAGE__;
    my $log_functions = {
        'error'   => 1,
        'warning' => 2,
        'success' => 3,
        'info1'   => 4,
        'info2'   => 4,
        'debug'   => 5,
        'devel'   => 6,
    };
    $config = {
        'timestamp'      => 1,
        'handles'        => [ \*STDOUT ],
        'log_level'      => 5,
        'show_log_level' => 1,
        'auto_caller'    => 1,
        'caller'         => 1,
    };
    $log_instance ||= bless({}, $class);
    no strict 'refs';
    local $SIG{__WARN__} = sub {};
    while( my ($function_name, $log_level) = each (%{$log_functions})) {
        *{"$class" . "::" . "$function_name"} = sub {
            if($log_level <= $config->{log_level}) {
                my @messages = ();
                while(@_) {
                    my $message = shift;

                    $message = $class->real($message);

                    if($config->{trim}) {
                        $message = $class->trim($message);
                    }


                    if($config->{caller}) {
                        my $local_caller = "";
                        if($config->{auto_caller} or !defined($caller)) {
                            $local_caller = (caller(1))[1];
                        } else {
                            $local_caller = $caller
                        }
                        $message = $local_caller . " $message";
                    }


                    if($config->{timestamp}) {
                        my $timestamp = "";
                        if($config->{custom_timestamp}) {
                            $timestamp = strftime($config->{custom_timestamp}, localtime);
                        } else {
                            $timestamp = strftime("%m.%d.%Y %H:%M:%S", localtime);
                        }
                        $message = "$timestamp $message";
                    }

                    if($config->{show_log_level}) {
                        $message = "[" . $function_name . "] $message";
                    }


                    push(@messages, $message);
                }
                while(@messages) {
                    my $message = shift @messages;
                    foreach my $handle (@{$config->{handles}}) {
                        print $handle "$message\n";
                    }
                }
            }
            return $class->get();
        };
    }
    # We never want to act like $class or self is passed in
    foreach my $existing_function (keys %{"$class" . "::"}) {
        my $old_function = \&{"$class" . "::" . "$existing_function"};
        *{"$class" . "::" . "$existing_function"} = sub {
            if( (ref($_[0]) eq $class) || ($_[0] eq $class)) {
                shift;
            }
            $old_function->(@_);
        }
    }
}

END
{
    foreach my $file_handler (@{$config->{file_handles}}) {
        close($file_handler) if $file_handler;
    }
}


1;
