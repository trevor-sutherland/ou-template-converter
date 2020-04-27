#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use utf8;

use Data::Dumper;
use Data::Validate::URI qw(is_uri);
use File::Path qw(make_path remove_tree);
use LWP::UserAgent;
use Path::Tiny;
use Pod::Usage;
use URI::Find;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;



### COMMAND LINE ARGS
my $help = 0;
my $man = 0;
my $mapfile;
my $tmpl;
my $output_dir = "./out";
my $image_dir = "";
my $debug = 0;
my $ignore_pattern = '^$';

GetOptions(
    'help|?' => \$help,
    'man' => \$man,
    'map|m=s' => \$mapfile,
    'tmpl|t=s' => \$tmpl,
    'out|o=s' => \$output_dir,
    'images-out|i:s' => \$image_dir,
    'verbose|v:1' => \$debug,
    'ignore=s' => \$ignore_pattern
) or pod2usage(2);
pod2usage(2) if !@ARGV;
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

my @filelist = @ARGV;
say "Debug: $debug" if $debug;
print Dumper(@filelist) if $debug;


## HTTP SERVICE
my $httpclient = LWP::UserAgent->new;


## SET UP MAP
if (is_uri($mapfile)) {
    say "MAP is URI: $mapfile" if $debug;
    $mapfile = slurpURL($mapfile);
} else {
    path($mapfile)->exists or die("MAP File does not exist: $mapfile");
    $mapfile = path($mapfile)->slurp;
    say $mapfile if $debug > 1;
}

my %map;

foreach my $line (split /\n/, $mapfile) {
    my @args = split ',', $line;
    $map{$args[0]} = $args[1];
}
if ($debug) {
    say "Map:";
    foreach my $key (keys %map) {
        say "\t$key => $map{$key}"
    }
}

## SET UP TMPL
if (is_uri($tmpl)) {
    say "TMPL is URI: $tmpl" if $debug;
    $tmpl = slurpURL($tmpl);
} else {
    path($tmpl)->exists or die("TMPL File does not exist: $tmpl");
    $tmpl = path($tmpl)->slurp;
}

# say $tmpl if $debug > 1;


## OUTPUT

$output_dir = path($output_dir);
$output_dir->remove_tree;
# $image_dir = path($image_dir);
# $image_dir->remove_tree;

foreach my $pcf (@filelist) {
    if ($pcf =~ qr/$ignore_pattern/) {
        say "ignored: $pcf";
        next;
    }
    say $pcf if $debug;
    my $dom = XML::LibXML->load_xml(location => $pcf);
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs('ouc',  'http://omniupdate.com/XSL/Variables');
    my $output = $tmpl;
    my $outfile = $output_dir->child($pcf)->touchpath;
    foreach my $xpath (keys %map) {
        my $var = trim($map{$xpath});
        say $var if $debug > 1;
        my $scalar = $xpc->findnodes('/document//' . $xpath)->to_literal();
        $output =~ s/\<!--%echo var="$var" ?-->/$scalar/;
        my @nodeset = $xpc->findnodes("/document/" . $xpath . "/node()[not(self::comment() and contains(., 'com.omniupdate'))][not(self::ouc:editor)]");
        next if @nodeset eq 0;
        say "Nodes: " . @nodeset if $debug > 1;
        my $content ='';
        foreach my $node (@nodeset) {
            $content .= $node->toString();
        }
        $output =~ s/\<!--%echo var="$var" encoding="none" ?-->/$content/;
        $output =~ s/$var/$var$content/ if $var =~ /^</;
    }
    # Replace all other vars that didn't get values
    $output =~ s/<!--%echo var=.*-->//g;
    $outfile->spew_utf8($output);

}


sub slurpURL {
    my $uri = shift;
    my $req = HTTP::Request->new(GET => $uri);

    my $response = $httpclient->request($req);;
    $response->is_success or die("$uri: $response->message");
    return $response->decoded_content;
}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

__END__

=head1 Convert Between OmniUpdate Templates

=head1 SYNOPSIS

Usage: ou-convert --map file.map --tmpl file.tmpl [options] files

=over 2
-map file            file containing CSV mapping
-tmpl file           TMPL file of TARGET template
[-out dir]          Output directory, defaults to ./out/
[-images-out dir] [-i]   Process non-DM images and save to specified directory
[-v [n] ]            Turn on verbose/debug output

=head1 OPTIONS

=over 8

=item B<-map>

File containing CSV mapping of XPATH nodes to TMPL vars,
relative to /document

Example:
maincontent,maincontent
config/parameter[@name='numcols'],numcols
metadata/meta[@name='Description'],description

=item B<-tmpl>

TMPL file or URL used by OmniUpdate to create new pages. Variables will be replaced
as if we were running the Page Creation Wizard.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut

