use strict;

my $usage = "perl $0 QueryLabel SubjectLabel < blast-table.txt > edges.txt";
my $qlab = shift(@ARGV) or die("Usage: $usage");
my $hlab = shift(@ARGV) or die("Usage: $usage");

while(my $line = <STDIN>)
{
  my @values = split(/\t/, $line);
  printf("%s_%s\t%s_%s\t%s\n", $qlab, $values[0], $hlab, $values[1], $values[10]);
}
