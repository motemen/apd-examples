# URL: http://soundcloud.com/*/*
use strict;
use warnings;
use LWP::Simple qw($ua);
use Perl6::Say;
use HTTP::Request;

my $url = shift or die;
my $res = $ua->get($url);
$res->is_success or do {
    say 'failed ' . $res->message;
    exit 1;
};

my ($media_url) = $res->content =~ m<"streamUrl":"([^"]+)">
    or do {
        say 'failed Could not find stream URL';
        exit 1;
    };

my ($title) = $res->content =~ m{<h1>(.+?)</h1>}s;
$title =~ s{<.+?>}{}g;
$title =~ s<[\n\r]+><>g;

my $received = 0;
my $total;
my ($filename, $fh);

my $media_res = $ua->request(HTTP::Request->new(GET => $media_url), sub {
    my ($data, $res, $proto) = @_;

    unless ($total) {
        $total = $res->header('Content-Length');
    }

    unless ($fh) {
        $filename = "$title.soundcloud.mp3"; # TODO ext
        open $fh, '>', $filename or die $!;
    }

    print $fh $data;
    
    $received += length $data;
    say "$received/$total" if $total;
});

if ($media_res->is_success) {
    say "completed $filename";
} else {
    say 'failed ' . $media_res->message;
    exit 1;
}
