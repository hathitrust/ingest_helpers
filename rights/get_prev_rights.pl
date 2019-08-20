#!/usr/bin/perl

use HTFeed::DBTools qw(get_dbh);
my $dbh = get_dbh();
my $sth = $dbh->prepare("select a.name, r.name from ht.rights_log l join attributes a on l.attr = a.id join reasons r on l.reason = r.id where namespace = ? and l.id = ? order by time desc");
my $user = `whoami`;
chomp $user;

while(my $line = <>) {
    chomp $line;
    my ($namespace, $id) = split("\t",$line);
    $sth->execute($namespace,$id);
    # skip the first row
#    my ($attr,$reason) = $sth->fetchrow_array();
     $sth->fetchrow_array();
#    print join("\t","CURRENT",$namespace,$id,$attr,$reason,$user), "\n";
    my ($attr,$reason) = $sth->fetchrow_array();
    unless (defined $attr and defined $reason) {
        warn("No previous rights for $namespace $id") ;
        next;
    }
    print join("\t","OLD",$namespace,$id,$attr,$reason,$user), "\n";
}

