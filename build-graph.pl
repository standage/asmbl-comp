use strict;
use Graph;
use Data::Dumper;
use Getopt::Long;

sub print_usage
{
  my $outstream = shift(@_);
  print $outstream "
Usage: perl build-graph.pl [options] EdgeFile1 [EdgeFile2, ...]
  Options:
    -h|--help          print this help message and quit
    --xlabel=STRING    label corresponding to one assembly; default is 'X'
    --ylabel=STRING    label corresponding to the other assembly; default is 'Y'
";
}

sub print_connected_component
{
  my($cc, $xlab, $ylab) = @_;
  my @xnodes = ();
  my @ynodes = ();
  
  foreach my $node(@$cc)
  {
    if($node =~ s/^$xlab\_//)
    {
      push(@xnodes, $node);
    }
    elsif($node =~ s/^$ylab\_//)
    {
      push(@ynodes, $node)
    }
    else
    {
      die("Renegade node '$node' $!");
    }
  }
  
  my $type;
  my $nx = scalar(@xnodes);
  my $ny = scalar(@ynodes);
  my $x = join(",", @xnodes);
  my $y = join(",", @ynodes);
  
  if($nx == 1 and $ny == 1)
  {
    $type = "OneToOne";
  }
  elsif($nx == 1 and $ny > 1)
  {
    $type = "OneToMany";
  }
  elsif($nx > 1 and $ny == 1)
  {
    $type = "ManyToOne";
  }
  elsif($nx > 1 and $ny > 1)
  {
    $type = "ManyToMany";
  }
  else
  {
    die("Renegade cc: x=[$x], y=[$y] $!");
  }
  
  print join("\t", $type, $nx, $ny, $x, $y), "\n";
}

my $xlab = "X";
my $ylab = "Y";
GetOptions
(
  "h|help"   => sub{ print_usage(\*STDOUT); exit(0); },
  "xlabel=s" => \$xlab,
  "ylabel=s" => \$ylab,
);

my $g = Graph->new();
foreach my $file(@ARGV)
{
  printf(STDERR "Reading and storing edges from input file '%s'...", $file);
  open(my $IN, "<", $file) or die("cannot open '$file'");
  my $start = time();
  while(my $line = <$IN>)
  {
    chomp($line);
    my($source, $target, $edge_label) = split(/\t/, $line);
    $g->add_edge($source, $target);
  }
  close($IN);
  my $elapsed = time() - $start;
  printf(STDERR "done! (%d seconds)\n", $elapsed);
}

printf(STDERR "Finding connected components...");
my $start = time();
my @ccs = $g->weakly_connected_components();
my $elapsed = time() - $start;
printf(STDERR "done! (%s seconds)\n", $elapsed);

foreach my $cc(@ccs)
{
  print_connected_component($cc, $xlab, $ylab);
}
