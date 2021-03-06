#!/usr/bin/perl 
# u_path/dsv51/scripts/mahnstatistik/mahn-statistik-format.pl

# formatiere mahn-statistik.txt und schreibe eine html-seite
# fuer jede bibliothek.
# 13-02-2002/ava
# 19-09-2005/blu: Anpassung an V16
# 16-03-2007/blu: Erweiterung um SplitMail-Output
# 30-11-2007/blu: V18
# 24-05-2010/blu: V20
# 30-03-2013/blu: V21
# 26.10.2014/blu: V22
# 26.04.2018/fbo: Anpassungen fuer die virtuelle Umgebung unter RedHat
# 04.07.2018/ssch: Aenderungen aus Script auf Aleph prod uebernommen
# 04.07.2018/ssch: Skript verschoben nach u_path/dsv51/scrips/mahnstatistik; Anpassung Pfade

use strict;

my $u_path     = $ENV{dsv51_dev};
my $infile     = "$u_path/dsv51/scripts/mahnstatistik/mahn-statistik.txt";
my $htmlfile   = 'mahn-statistik-%%SUBLIB%%.html';
my $indexfile  = 'mahn-statistik.html';
my $templfile  = 'mahn-statistik-template.html';
my $targetdir  = "$u_path/local/statistik";
my $spalten = 7;

chdir "$u_path/dsv51/scripts/mahnstatistik";

my @monate = qw (Jaguar Januar Februar M&auml;rz April Mai Juni Juli August September Oktober November Dezember);
my $today = localtime(time);
my $template = read_template();

# statistikdaten in @lines einlesen
open(F,"<$infile") or die "cannot read $infile: $!";
my @lines = <F>;
close F;

# list der gefundenen sublibs
my %sublibs;
for ( my $i=0 ; $i <= $#lines ; $i++ ) {
    next if ( $lines[$i] =~ /^#/ );
    my ( undef, $sublib ) = split(/\s+/, $lines[$i]);
    ( $sublib =~ /^\w/ ) and $sublibs{$sublib} = 1;
}
my @sublibs = sort keys %sublibs;

# daten filtern und bearbeiten
foreach my $sublib ( @sublibs ) {
    my $oldmonth;
    my @liblines;
    my @tmp = grep { /$sublib/ } @lines;
    while ( @tmp ) {
        my $line = shift @tmp;
        $_ = $line;
        s/\t.*$//;
        my($year,$month)=split /-/;
        $month=$monate[$month];
        if ( $month ne $oldmonth ) {
            push(@liblines, "=$month $year");
            $oldmonth = $month;
        }
        push(@liblines, $line);
    }
    push(@liblines, "=");
    print_page($sublib, \@liblines);
}
write_index();

# zeilen einer sublib formatieren und ausgeben
sub print_page {
    my($sublib, $aref) = @_;
    local($_,*F);
    my($rows,$table,$total,$mtotal,$prevmonth,$outfile);
    my($date1,$date2);
    while ( @$aref ) {
        $_ = shift @$aref;
        if ( s/^=// ) {
            # neuer monat oder letzte zeile
            my $monat = $_;
            if ( $rows ) {
                # monatstotal
                $_ = $template->{row};
                s/%%DATUM%%/total/;
                for( my $i=1 ; $i <= $spalten; $i++ ) {
                    s/%%M$i%%/sprintf("%d",$mtotal->{$i})/e;
                }
                $rows .= $_;
                # monat als tabelle ausgeben
                $_ = $template->{table};
                s/%%MONAT%%/$prevmonth/g;
                s/%%START_ROW%%.*%%END_ROW%%/$rows/s;
                $table .= $_;
            }
            $rows='';
            $mtotal={};
            $prevmonth=$monat;
        }
        else {
            # datenzeile formatieren
            my ($date, undef, @mahn) = split;
            $date1 ||= $date;
            $date2 = $date;
            $_ = $template->{row};
            s/%%DATUM%%/$date/;
            unshift(@mahn,'');
            for( my $i=1 ; $i <= $spalten; $i++ ) {
                $mtotal->{$i} += $mahn[$i];
                $total->{$i} += $mahn[$i];
                s/%%M$i%%/sprintf("%d",$mahn[$i])/e;
            }
            $rows .= $_;
        }
    }
    # am schluss eine tabelle fuer das gesamttotal anhaengen
    $_ = $template->{row};
    s/%%DATUM%%/$date1<br>bis<br>$date2/;
    my $sum;
    for( my $i=1 ; $i <= $spalten; $i++ ) {
        s/%%M$i%%/sprintf("%d",$total->{$i})/e;
        $sum += $total->{$i};
    }
    $rows .= $_;
    $_ = $template->{table};
    $sum=format_int($sum);
    s/%%MONAT%%/Total: &nbsp;&nbsp;&nbsp; $sum/g;
    s/%%START_ROW%%.*%%END_ROW%%/$rows/s;
    $table .= $_;
    
    # seitentemplate mit daten fuellen und html schreiben
    $_ = $template->{page};
    s/%%TODAY%%/$today/;
    s/%%SUBLIB%%/$sublib/g;
    s/%%START_TABLE%%(.*)%%END_TABLE%%/$table/s;
    ($outfile = "$targetdir/$htmlfile") =~ s/%%SUBLIB%%/$sublib/g;
    open(F, ">$outfile") or die "cannot write $outfile: $!";
    print F $_;
    close F;
}

sub read_template {
    # abschnitte 'page', 'table' und 'row' aus template extrahieren
    my $href = {};
    local(*F,$_,$/);
    open(F,"<$templfile") or die "cannot read $templfile: $!";
    $_ = <F>;
    close F;
    $href->{page}=$_;
    /%%START_TABLE%%(.*)%%END_TABLE%%/s;
    $href->{table}=$1;
    /%%START_ROW%%(.*)%%END_ROW%%/s;
    $href->{row}=$1;
    $href;
}

sub write_index {
    # links auf einzelne bibliotheksseiten im index aktualisieren
    local($_,*F);
    open(F,"<$targetdir/$indexfile") or die "cannot read $indexfile: $!";
    { local $/; $_ = <F>; }
    close F;
    my($index,$link);
    foreach my $sublib ( @sublibs ) {
        ($link = $htmlfile) =~ s/%%SUBLIB%%/$sublib/g;
        $index .= "<li><a href=\"$link\">$sublib</a></li>\n";
    }
    s/(<!-- START_LISTE -->)(.*)(<!-- END_LISTE -->)/$1\n$index$3/s;
    s/(<!-- START_DATUM -->)(.*)(<!-- END_DATUM -->)/$1\n$today$3/s;
    open(F,">$targetdir/$indexfile") or die "cannot write $indexfile: $!";
    print F $_;
    close F;
}

sub format_int {
    local $_ = shift;
    while ( /\d{4}/ ) {
        s|(\d+)(\d\d\d)|$1'$2|;
    }
    $_;
}

