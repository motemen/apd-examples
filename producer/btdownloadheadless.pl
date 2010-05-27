# URL: *.torrent
# or Content-Type: application/x-bittorrent

use strict;
use warnings;
use Perl6::Say;

my $target = shift or die;

my $pid = open my $fh, '-|', 'btdownloadheadless', $target or die $!;
my $filename;

while (<$fh>) {
    chomp;

    if (/^ERROR:/) {
        say "failed $_";
        exit 1;
    }

    if (/^saving:\s+(.+)/ && !defined $filename) {
        $filename = $1;
        $filename =~ s/\s*\([^()]+\)\s*$//;
    }

    if (/^time left:\s+Download Succeeded!/) {
        say "completed $filename";
        sleep 3;
        kill 'HUP', $pid;
        close $fh;
        exit 0;
    }

    if (/^percent done:\s+(\d+(?:\.\d+))\s*$/) {
        say $1;
    }
}

say "failed child process exited with code $?";
exit 1;
