# This file was created by configpm when Perl was built. Any changes
# made to this file will be lost the next time perl is built.

# for a description of the variables, please have a look at the
# Glossary file, as written in the Porting folder, or use the url:
# http://perl5.git.perl.org/perl.git/blob/HEAD:/Porting/Glossary

package Config;
use strict;
use warnings;
use vars '%Config', '$VERSION';

$VERSION = "5.020002";

# Skip @Config::EXPORT because it only contains %Config, which we special
# case below as it's not a function. @Config::EXPORT won't change in the
# lifetime of Perl 5.
my %Export_Cache = (myconfig => 1, config_sh => 1, config_vars => 1,
		    config_re => 1, compile_date => 1, local_patches => 1,
		    bincompat_options => 1, non_bincompat_options => 1,
		    header_files => 1);

@Config::EXPORT = qw(%Config);
@Config::EXPORT_OK = keys %Export_Cache;

# Need to stub all the functions to make code such as print Config::config_sh
# keep working

sub bincompat_options;
sub compile_date;
sub config_re;
sub config_sh;
sub config_vars;
sub header_files;
sub local_patches;
sub myconfig;
sub non_bincompat_options;

# Define our own import method to avoid pulling in the full Exporter:
sub import {
    shift;
    @_ = @Config::EXPORT unless @_;

    my @funcs = grep $_ ne '%Config', @_;
    my $export_Config = @funcs < @_ ? 1 : 0;

    no strict 'refs';
    my $callpkg = caller(0);
    foreach my $func (@funcs) {
	die qq{"$func" is not exported by the Config module\n}
	    unless $Export_Cache{$func};
	*{$callpkg.'::'.$func} = \&{$func};
    }

    *{"$callpkg\::Config"} = \%Config if $export_Config;
    return;
}

die "$0: Perl lib version (5.20.2) doesn't match executable '$^X' version ($])"
    unless $^V;

$^V eq 5.20.2
    or die sprintf "%s: Perl lib version (5.20.2) doesn't match executable '$^X' version (%vd)", $0, $^V;


sub relocate_inc {
  my $libdir = shift;
  return $libdir unless $libdir =~ s!^\.\.\./!!;
  my $prefix = $^X;
  if ($prefix =~ s!/[^/]*$!!) {
    while ($libdir =~ m!^\.\./!) {
      # Loop while $libdir starts "../" and $prefix still has a trailing
      # directory
      last unless $prefix =~ s!/([^/]+)$!!;
      # but bail out if the directory we picked off the end of $prefix is .
      # or ..
      if ($1 eq '.' or $1 eq '..') {
	# Undo! This should be rare, hence code it this way rather than a
	# check each time before the s!!! above.
	$prefix = "$prefix/$1";
	last;
      }
      # Remove that leading ../ and loop again
      substr ($libdir, 0, 3, '');
    }
    $libdir = "$prefix/$libdir";
  }
  $libdir;
}

sub FETCH {
    my($self, $key) = @_;

    # check for cached value (which may be undef so we use exists not defined)
    return exists $self->{$key} ? $self->{$key} : $self->fetch_string($key);
}

sub TIEHASH {
    bless $_[1], $_[0];
}

sub DESTROY { }

sub AUTOLOAD {
    require 'Config_heavy.pl';
    goto \&launcher unless $Config::AUTOLOAD =~ /launcher$/;
    die "&Config::AUTOLOAD failed on $Config::AUTOLOAD";
}

# tie returns the object, so the value returned to require will be true.
tie %Config, 'Config', {
    archlibexp => relocate_inc('.../../lib/perl5/5.20.2/x86_64-linux'),
    archname => 'x86_64-linux',
    cc => 'cc',
    d_readlink => 'define',
    d_symlink => 'define',
    dlext => 'none',
    dlsrc => 'dl_none.xs',
    dont_use_nlink => undef,
    exe_ext => '',
    inc_version_list => ' ',
    intsize => '4',
    ldlibpthname => 'LD_LIBRARY_PATH',
    libpth => '/usr/local/lib /usr/lib/gcc/x86_64-linux-gnu/5/include-fixed /usr/include/x86_64-linux-gnu /usr/lib /lib/x86_64-linux-gnu /lib/../lib /usr/lib/x86_64-linux-gnu /usr/lib/../lib /lib',
    osname => 'linux',
    osvers => '4.4.0-190-generic',
    path_sep => ':',
    privlibexp => relocate_inc('.../../lib/perl5/5.20.2'),
    scriptdir => '.../',
    sitearchexp => relocate_inc('.../../lib/perl5/site_perl/5.20.2/x86_64-linux'),
    sitelibexp => relocate_inc('.../../lib/perl5/site_perl/5.20.2'),
    so => 'so',
    useithreads => undef,
    usevendorprefix => undef,
    version => '5.20.2',
};
