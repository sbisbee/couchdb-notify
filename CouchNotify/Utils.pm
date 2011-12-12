package CouchNotify::Utils;

use strict;
use warnings;

use JSON;

sub getConf {
  my $conf = '';

  open(FILE, "<", $_[0]) or die $!;

  while(<FILE>) {
    $_ =~ s/\015?\012?$//;
    $conf .= $_ unless $_ eq '';
  }

  close(FILE);

  return decode_json($conf);
}

# based on $conf->{server} structure in config
sub buildURL {
  my ($server, $url) = ($_[0], "");

  onError('Invalid server protocol.', 1)
    if $server->{proto} ne 'http' && $server->{proto} ne 'https';

  $url .= $server->{proto} . "://";

  if($server->{user}) {
    onError("User specified but no password", 1) if !$server->{pass};

    $url .= $server->{user} . ":" . $server->{pass} . "@";
  }

  $url .= $server->{host};

  $url .= ":" . $server->{port} if $server->{port};

  $url .= "/" . $server->{db};

  return $url;
}

1;
