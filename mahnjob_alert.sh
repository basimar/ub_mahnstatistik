#! /bin/csh -f
# mahnjob_alert.sh
# Script, das ein Mail ueber den Stand der Mahnletter z36 verschickt.
# Derzeit fuer A125 A332
# Erweitern: neue mail_addr_sublib mit Adressdaten anlegen. 
#            neuen mail_body_sublib.text anlegen
#            neue mahnletter_sublib.sql anlegen und in SQL-Abfrage einbinden
#            Liste der foreach-Schleife ergaenzen
# Mit V16 laufen die Mahnjobs nach dem Backup und mahn-statistik.pl selektiert Today.
# blu, 25.10.2005, 20070531 ergänzt, mesi
# blu, 30.11.2007: V18
# mesi 02.07.2008, Text Betreff angepasst
# blu, 12.04.2010: Oracle 11, V20
# blu, 30.03.2013: V21
# blu, 01.07.2014: Absender blu
# blu, 26.10.2014: V22
# fbo, 26.04.2018: Mail-Adresse angepasst
# ssch, 04.07.2018: Aktueller Stand von alprod integriert; obsolete Zweigstellen entfernt
# ssch, 04.07.2018: Pfade angepasst

# Pfad zwischenspeichern und wechseln
set current_dir = `pwd`
cd $dsv51_dev/dsv51/scripts/mahnstatistik

# Allgemeine Mailadressen - die Adressatenmails sind in ext. Dateien
set mail_addr_admin = ""
set return_addr = ""

# Datum
set date = `date +%d.%m.%y`
set sql_date = `date +%Y%m%d`

# SQL-Abfragen auf z36
/exlibris/app/oracle/product/11r2/bin/sqlplus << END_SQL
       DSV51/DSV51
       @mahnletter_a125.sql $sql_date
       @mahnletter_a332.sql $sql_date
exit
END_SQL

# Mail-Zuordnungen
foreach f (A125 A332)
if (-e mahnletter_$f.rpt) then
   set nachricht = `cat mahnletter_$f.rpt`
   set mail_addr = `cat mail_addr_$f`
else
   echo "mahnletter_$f.rpt oder mail_addr_$f checken" | mailx -s "Mahnletter-Fehler" $mail_addr_admin   
endif


# Mails verschicken
if (! -z mahnletter_$f.rpt) then
   (cat mail_body_$f.txt) | mailx -r $return_addr -s "Am $date gibt es fuer $nachricht Nachrichten" $mail_addr
else
   (cat mail_body_$f.txt) | mailx -r $return_addr -s "Am $date gibt es fuer $f keine Nachrichten" $mail_addr
endif
end

ende:
cd $current_dir
exit
