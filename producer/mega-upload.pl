# URL: http://www.megaupload.com/?d=*
use strict;
use warnings;
use WWW::Mechanize;
use Perl6::Say;

my $url = shift or die;
my $mech = WWW::Mechanize->new;

$mech->get($url);

while (1) {
    unless ($mech->res->is_success) {
        say 'failed ' . $mech->res->message;
        exit 1;
    }

    my ($filename) = $mech->res->decoded_content =~ m!<font style="font-family:arial; color:#FF6700; font-size:22px; font-weight:bold;">(.+)</font><br>!;
    say "# file: $filename";

    my ($captcha_image) = $mech->res->decoded_content =~ m#<img src="(.+?/gencap\.php\?.+?)"# or do {
        say 'failed Could not find captcha';
        exit 1;
    };

    say "# read $captcha_image";

    my $input = <STDIN>;
    chomp $input;
    $mech->submit_form(
        fields => { captcha => $input },
    );

    if (scalar @{$mech->forms} == 0) {
        if (my $link = $mech->find_link(url_abs_regex => qr(^http://www\d+\.megaupload\.com/files/[[:xdigit:]]+/))) {
            sleep 2;
            my $len = 0;
            open my $fh, '>', $filename;
            $mech->get($link->url, ':content_cb' => sub {
                my ($data, $res) = @_;
                my $content_length = $res->header('content-length');
                print $fh $data;
                $len += length $data;
                say "$len/$content_length";
            });
            say "completed $filename";
            last;
        } else {
            warn $mech->res->decoded_content;
            say '# download link not found';
        }
    }

    sleep 2;

    $mech->get($url);
}
