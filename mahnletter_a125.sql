/******************************************************/
/* mahnletter_a125.sql                                */
/*                                                    */
/* Mahnungen in A125 feststellen                      */
/* Report-file: mahnletter_A125.rpt                   */
/*                                                    */
/* Stand: 2005/10/25 - Bernd Luchner                  */
/******************************************************/

set echo off
set pause off
set heading off
set feedback off
set termout off

spool mahnletter_A125.rpt

select z36_sub_library, count(*)
from z36
where z36_letter_date = '&1'
and z36_sub_library = 'A125'
group by z36_sub_library;

spool off;
