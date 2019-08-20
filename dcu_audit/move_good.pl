use File::Basename qw(dirname);

my $move = shift @ARGV or die("Need move dest");

while(<>) {
    chomp;
    my $dirname = dirname($_);
    print "mkdir -pv \"$move/$dirname\"\n";
    print "mv -v '$_' \"$move/$dirname\"\n";
}
