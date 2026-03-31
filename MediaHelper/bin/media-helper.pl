#!/usr/bin/perl
use strict;
use warnings;

# Usage: /usr/bin/perl media-helper.pl /path/to/MediaHelper.framework get
# Usage: /usr/bin/perl media-helper.pl /path/to/MediaHelper.framework send <CMD>
#
# This script runs under /usr/bin/perl which has com.apple.perl5 bundle ID,
# granting access to MediaRemote framework on macOS 15.4+.

my $framework_path = shift or die "Usage: $0 <framework_path> <command> [args]\n";
my $command = shift or die "Usage: $0 <framework_path> <command> [args]\n";

# Find the dylib
my $dylib = "$framework_path/MediaHelper";
$dylib = "$framework_path/Versions/A/MediaHelper" unless -f $dylib;
die "Library not found in $framework_path\n" unless -f $dylib;

# Load the framework using DynaLoader
require DynaLoader;
my $handle = DynaLoader::dl_load_file($dylib, 0);
die "Failed to load: " . DynaLoader::dl_error() . "\n" unless $handle;

if ($command eq "get") {
    my $sym = DynaLoader::dl_find_symbol($handle, "MediaHelperPrintNowPlaying");
    die "Symbol not found: MediaHelperPrintNowPlaying\n" unless $sym;
    my $func = DynaLoader::dl_install_xsub("_get", $sym, __FILE__);
    _get();
} elsif ($command eq "send") {
    my $cmd_id = shift or die "send requires command ID\n";
    my $sym = DynaLoader::dl_find_symbol($handle, "MediaHelperSendCommand");
    die "Symbol not found: MediaHelperSendCommand\n" unless $sym;
    my $func = DynaLoader::dl_install_xsub("_send", $sym, __FILE__);
    _send(int($cmd_id));
} else {
    die "Unknown command: $command\n";
}
