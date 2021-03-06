#!/usr/bin/perl -w
# u_path/dsv51/scripts/mahnstatistik/mahn-statistik.pl
# 12.02.2002/Andres von Arx
#
# - auswertung von dsv51.z36
# - anzahl mahnungen, sortiert nach (1) sublib, (2) letter_nr
# - wird taeglich nach dem backup ausgefuehrt
# - schreibt (mit append) in eine Datei, die 'aleph' gehoert,
#   sollte daher als root ausgefuehrt werden.
# - die daten werden durch mahn-statistik-format.pl aufbereitet.
# rev. 19.09.2005, blu: Auswertung auf heutige Mahnungen, da Mahnjobs in V16 nach Backup laufen 
#                       Umstellung auf ALEPH V16, Oracle 9
# rev. 21.09.2005, blu: DBI-Aufruf new style
#                       Tageszeile in mahn-statistik.txt geaendert
# rev. 14.03.2007, blu: Zusaetzlich wird splitMail.log ausgewertet
# rev. 30.11.2007, blu: V18
# rev. 24.05.2010, blu: V20
# rev. 30.03.2013, blu: V21
# rev. 11.09.2013, ava: parsen von SplitMailLog korrigiert
# rev. 04.11.2014, blu: V22, Pfade Outfile, SplitMaillog, Oracle-Zugriff variablengesteuert
# rev. 26.04.2018, fbo: Anpassungen an die virtuelle Umgebung unter RedHat
# rev. 04.07.2018, ssch: Aenderungen aus aleph prod uebernommen
# rev. 04.07.2018, ssch: Anpassungen fuer neuen Pfad

use strict;
use DBI;
use DBD::Oracle;
use POSIX qw/strftime/;
use locale;

my $ADM          = 'DSV51';
my $u_path       = $ENV{dsv51_dev};
my $Outfile      = "$u_path/dsv51/scripts/mahnstatistik/mahn-statistik.txt";
#my $Outfile      = '-';
my $SplitMailLog = "$u_path/dsv51/dod/logs/splitMail";
my $MaxMahnstufe = 4;

my $Today = format_day(time);
my $Yesterday = format_day(time - 60*60*24);
my $Logdate = strftime("-%Y-%b-%d", localtime);

my %SplitMailLine=();
my $Result={};
my $dbh = Connect();
my $sth = $dbh->prepare(
    "select Z36_SUB_LIBRARY, Z36_LETTER_NUMBER " .
    "from $ADM.Z36 " .
    "where Z36_LETTER_DATE = '$Today'"
    );
$sth->execute;

while ( my ($subl,$lett) = $sth->fetchrow_array ) {
    $Result->{$subl}->{$lett}++;
}
$sth->finish;
$dbh->disconnect;

$Today =~ s/^(....)(..)(..)$/$1-$2-$3/;
$Yesterday =~ s/^(....)(..)(..)$/$1-$2-$3/;

system "sort -k3 -o SplitMailLog$Logdate.tmp $SplitMailLog$Logdate.log"; 

open(OUT, ">>$Outfile") or die "cannot append to $Outfile: $!";
open(IN, "<SplitMailLog$Logdate.tmp") or die "can't open SplitMailLog$Logdate.tmp: $!";

while (<IN>) {                                   # Auswertung SplitMail-Log
   if ( /^\d{2}:\d{2}:\d{2} - (....).* - email: (\d{1,5}) - print: (\d{1,5})$/) {
     my $up_sublib = uc($1)." ";                 # da z36_sub_library 5-stellig ist
     $SplitMailLine{$up_sublib}{email} += $2;
     $SplitMailLine{$up_sublib}{print} += $3;
   }
}
close IN;

# print out results
foreach my $lib ( sort keys %$Result ) {
    local $^W = 0;
    my $today_sublib_total = 0;
    print OUT $Today, "\t", $lib;
    for ( my $i=1 ; $i <= $MaxMahnstufe ; $i++ ) {
        printf OUT "\t%d", $Result->{$lib}->{"$i"};
        $today_sublib_total += $Result->{$lib}->{"$i"};
    }
    printf OUT "\t%d", $today_sublib_total;
    if ( $SplitMailLine{$lib} ) {
       printf OUT "\t%d\t%d", $SplitMailLine{$lib}->{email}, $SplitMailLine{$lib}->{print};
    }
    else {
       printf OUT "\t%s\t%s", ("nop", "nop");
    }
    print OUT "\n";
}
# -- print a daily foot line, so we know the program did run
print OUT $Today, "\t*** did run ***\n";
close OUT;

sub Connect {
    $ENV{ORACLE_SID} or die 'ORACLE_SID ???';
    $ENV{ORACLE_HOME} or die 'ORACLE_HOME ???';
    my $dbh = DBI->connect('dbi:Oracle:', 'DSV51', 'DSV51',
         { RaiseError => 1, AutoCommit => 0 })
       or die "$DBI::errstr\n";
    return $dbh;
}

sub format_day {
    my @a = localtime($_[0]);
    sprintf ( "%4.4d%2.2d%2.2d", $a[5]+1900, $a[4]+1, $a[3]);
}

__END__

select Z36_SUB_LIBRARY, Z36_LETTER_NUMBER
from DSV51.Z36
where Z36_LETTER_DATE = '20020207';


select z36_sub_library, z36_letter_number, count(*)
from z36
where z36_letter_date = '20020207'
group by z36_sub_library, z36_letter_number;

