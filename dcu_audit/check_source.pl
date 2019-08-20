#!/usr/bin/perl

use HTFeed::DBTools qw(get_dbh);

my $dbh = get_dbh();
my $sth = $dbh->prepare("select a.name, r.name, s.name from rights_current rc join attributes a on rc.attr = a.id join reasons r on rc.reason = r.id join sources s on rc.source = s.id where namespace = 'mdp' and rc.id = ?");

while(my $objid = <>) {
  chomp $objid;
  if($objid =~ /(\d{14}).zip$/) {
      $objid = $1;
  }
  $sth->execute($objid);
  my ($attr,$reason,$source) = $sth->fetchrow_array;
  print "$objid $attr $reason $source\n" if $source ne 'lit-dlps-dc';
}
