use strict;
use warnings;
use Furl;
use Test::TCP;
use Plack::Loader;
use Test::More;

use Plack::Request;
my $n = shift(@ARGV) || 3;
test_tcp(
    client => sub {
        my $port = shift;
        my $furl = Furl->new(bufsize => 10);
        for (1 .. $n) {
            my ( $code, $msg, $headers, $content ) =
                $furl->request(
                    port       => $port,
                    path_query => '/foo',
                    host       => '127.0.0.1',
                    headers    => [ "X-Foo" => "ppp" ]
                );
            is $code, 200, "request()/$_";
            is $msg, "OK";
            is Furl::Util::header_get($headers, 'Content-Length'), 4, 'header'
                or diag(explain($headers));
            is $content, '/foo'
                or do{ require Devel::Peek; Devel::Peek::Dump($content) };
        }

        for (1..3) {
            my $path_query = '/foo/bar?a=b;c=d&e=f';
            my ( $code, $msg, $headers, $content ) =
                $furl->get("http://127.0.0.1:$port$path_query");
            is $code, 200, "get()/$_";
            is $msg, "OK";
            is Furl::Util::header_get($headers, 'Content-Length'),
                length($path_query), 'header';
            is $content, $path_query;
        }
        done_testing;
    },
    server => sub {
        my $port = shift;
        Plack::Loader->auto(port => $port)->run(sub {
            my $env = shift;
            #note explain $env;
            my $req = Plack::Request->new($env);
            is $req->header('X-Foo'), "ppp" if $env->{REQUEST_URI} eq '/foo';
            like $req->header('User-Agent'), qr/\A Furl /xms;
            return [ 200,
                [ 'Content-Length' => length($env->{REQUEST_URI}) ],
                [$env->{REQUEST_URI}]
            ];
        });
    }
);

