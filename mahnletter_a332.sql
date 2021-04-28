/******************************************************/
/* mahnletter_a332.sql                                */
/*                                                    */
/* Mahnungen in A332 feststellen                      */
/* Report-file: mahnletter_A332.rpt                   */
/*                                                    */
/* Stand: 20081029 - mesi     */
/******************************************************/

set echo off
set pause off
set heading off
set feedback off
set termout off

spool mahnletter_A332.rpt

select z36_sub_library, count(*)
from z36
where z36_letter_date = '&1'
and z36_sub_library = 'A332'
group by z36_sub_library;

spool off;
