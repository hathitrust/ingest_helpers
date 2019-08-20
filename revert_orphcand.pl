#!/usr/bin/perl

# Create a rights file that overrides any volumes whose GRIN viewability is
# VIEW_FULL but is ic or und in the rights database. 

use strict;
use HTFeed::DBTools qw(get_dbh);
use Mail::Mailer;

# find the ones to update
my $dbh = get_dbh();

foreach my $row (@{$dbh->selectall_arrayref("select r.namespace, r.id from mdp.rights_current r where r.attr='16'")}) {
    my ($namespace, $id, $attrname) = @$row;
    print join("\t","$namespace.$id\n");
#get next most recent for this barcode
    my ($oldattr, $oldreason, $oldsource) = $dbh->selectrow_array("select attr, reason, source from mdp.rights_log where id = '$id' and namespace = '$namespace' and attr != '16' order by time desc limit 1");
    print("replace into mdp.rights_current (namespace, id, attr, reason, source, user, note) values ('$namespace','$id','$oldattr','$oldreason','$oldsource','$ENV{USER}','Remove from orphan candidate list')","\n");
    $dbh->do("replace into mdp.rights_current (namespace, id, attr, reason, source, user, note) values ('$namespace','$id','$oldattr','$oldreason','$oldsource','$ENV{USER}','Remove from orphan candidate list')");
}

