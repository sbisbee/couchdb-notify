#!/usr/bin/perl

use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use Gtk2::Notify -init, "couchdb-notify";
use CouchNotify::Utils;

# Used so we only display one notification per run.
my $notified = 0;

sub onError {
  my $msg = "Error: $_[0]\n";

  if($_[1]) {
    die $msg;
  }
  else {
    print $msg;
  }
}

sub notify {
  if(!$notified) {
    my $guiNote = Gtk2::Notify->new('couchdb-notify', $_[0]);
    $guiNote->show;

    $notified = 1;
  }
}

# Parse in the config file
my $conf = CouchNotify::Utils::getConf('/home/sbisbee/.couchdb-notify');
my $baseURL = CouchNotify::Utils::buildURL($conf->{server});

my $ua = LWP::UserAgent->new;
$ua->agent('couchdb-notify-consumer/0.1');

my $req = HTTP::Request->new(
  'GET' => $baseURL . '/_changes?include_docs=true&filter=app/unseen&client=' . $conf->{clientID}
);

$req->content_type('application/json');

my $res = $ua->request($req);

onError($res->status_line, 1) if $res->{_rc} >= 300;

my $data = decode_json($res->decoded_content);
my $rows = $data->{results};

my $updates = [];

foreach my $row (@$rows) {
  $row = $row->{doc};
  notify("[" . $row->{server} . "] " . $row->{msg});

  $row->{clientsSeen} = [] if !$row->{clientsSeen};
  push(@{$row->{clientsSeen}}, $conf->{clientID});

  push(@$updates, $row);
}

if(scalar(@$updates)) {
  $req = HTTP::Request->new(
    'POST' => $baseURL . '/_bulk_docs'
  );

  $req->content_type('application/json');

  $req->content(encode_json({ 
    'docs' => $updates
  }));

  $res = $ua->request($req);

  onError($res->status_line, 1) if $res->{_rc} >= 400;
}
