# URL: http://www.nicovideo.jp/watch/*

# ref: http://gist.github.com/407777

use strict;
use warnings;
#!/usr/bin/perl
# original: http://search.cpan.org/src/MIYAGAWA/WWW-NicoVideo-Download-0.01/eg/fetch-video.pl

use WWW::NicoVideo::Download;
use HTML::TreeBuilder::XPath;
use Config::Pit;
use Perl6::Say;

my $config = pit_get("nicovideo.jp", require => {
    "username" => "email of nicovideo.jp",
    "password" => "password of nicovideo.jp",
});

my $url = shift or die;

my ($video_id) = $url =~ qr|/([^/]+)$|;

my ($fh, $name);

my $client = WWW::NicoVideo::Download->new( email => $config->{username}, password => $config->{password} );
my $res = $client->user_agent->get($url);
if ($res->is_success) {
    my $tree = HTML::TreeBuilder::XPath->new_from_content($res->content);
    my $title = $tree->findvalue("//h1");
    say "# Title: $title";

    $title =~ s{[/:]}{_}g;

    $name = "$video_id - $title";
} else {
    say "# Unknown Title";
    $name = $video_id;
}


my $media_url = eval { $client->prepare_download($video_id) };
if (!$media_url && $@) {
    say "failed $@";
    exit 1;
}

my $is_low = ($media_url =~ /low/);
if ($is_low) {
    say  "# ! Low-Mode";
}

my $filename;
my $total;
my $received = 0;

my $media_res = $client->user_agent->request( HTTP::Request->new( GET => $media_url ), sub {
    my ($data, $res, $proto) = @_;

    unless ($total) {
        $total = $res->header('Content-Length');
    }

    unless ($fh) {
        my $ext = (split '/', $res->header('Content-Type'))[-1] || "flv";
        $ext = "swf" if $ext =~ /flash/;

        $filename = $is_low ? "$name.low.$ext" : "$name.$ext";
        $filename =~ s/:/_/g;

        # if (-e $filename && !$opts->{force}) {
        #     say STDERR "File already exists";
        #     exit 0;
        # }

        open $fh, ">", $filename or die $!;
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
