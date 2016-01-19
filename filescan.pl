#!/usr/bin/env perl

use Modern::Perl;
use autodie;
use Digest::MD5;
use File::Find;
use File::stat;
use Time::Piece;

my $SKIP_HEADERS = 0;
my @dirs         = @ARGV;
my @HEADERS      = qw/
    MD5SUM
    MTIME
    SIZE
    FILENAME
    PATH
/;

find(\&wanted, @dirs);

sub wanted {
    my %file_properties = ();

    if (-f) {  # skip over non-files
      $file_properties{FILENAME} = $_;
      $file_properties{PATH}     = $File::Find::dir;
      $file_properties{MD5SUM}   = md5sum($_);

      my $st = stat($_);
      $file_properties{SIZE}     = $st->size;
      $file_properties{MTIME}    = iso8601($st->mtime);

      print_report_headers() unless $SKIP_HEADERS++;
      print_report_line(\%file_properties);
    }
}

sub md5sum {
    my $filename = shift;
    open(my $fh, '<', $filename) or die "Can't open '$filename': $!";
    binmode($fh);
    my $md5sum = Digest::MD5->new->addfile($fh)->hexdigest;
    close($fh);
    return $md5sum;
}

sub iso8601 {
    my $dt = shift;
    return Time::Piece->new($dt)->datetime;
}

sub print_report_headers {
    say join("\t", @HEADERS);
}

sub print_report_line {
    my $href            = shift;
    my %file_properties = %{$href};
    say join("\t", @file_properties{@HEADERS});
}
