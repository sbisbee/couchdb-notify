#!/usr/bin/perl

use strict;
use warnings;

use Irssi;
use LWP::UserAgent;
use JSON;
use CouchNotify::Utils;

our $ua = LWP::UserAgent->new;
my $conf = CouchNotify::Utils::getConf('/home/sbisbee/.couchdb-notify');
our $baseURL = CouchNotify::Utils::buildURL($conf->{server});

sub extractServerName {
  my ($server) = @_;

  if($server->{tag}) {
    return $server->{tag};
  }
  elsif($server->{address}) {
    return $server->{address};
  }
  else {
    return "unknown";
  }
}

sub notify {
  my ($server, $msg) = @_;

  my $req = HTTP::Request->new(
    POST => $baseURL
  );

  $req->content_type('application/json');

  $req->content(encode_json({
    msg => $msg,
    server => $server,
    timestamp => time
  }));

  my $res = $ua->request($req);

  if(!$res->is_success) {
    print "ERROR: ", $res->status_line, "\n";
  }
}

sub onPM {
  my ($server, $msg, $nick, $address, $target) = @_;

  $server = extractServerName($server);

  notify($server, "PM from $nick on $server");
}

sub onHighlight {
  my ($dst, $text, $stripped) = @_;

  if($dst->{level} & MSGLEVEL_HILIGHT) {
    notify(extractServerName($dst->{server}), $stripped);
  }
}

Irssi::signal_add_last({
  "message private" => \&onPM,
  "print text" => \&onHighlight
});
