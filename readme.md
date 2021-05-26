gethist 0.0.1: Web history database extractor and manager

Usage: Rscript gethist.r BR -option [devicename] [origin] output

Browser (BR) names:

SM	SeaMonkey
FF	Firefox
MZ	Mozilla generic (SM or FF), only with options -f or -fa
GC	Google Chrome
CH	Chromium
VV	Vivaldi
OP	Opera
ED	Microsoft Edge
NA	None; not applicable

Options:

-x	Extract history from default location into RDS file
-f	Extract history from a given history file into RDS file
-a	Add an extracted RDS file to an existing RDS database
-xa	Extract history from default location and add it to RDS database
-fa	Extract history from a given history file and add it to RDS database
-c	Convert an RDS file to a CSV file
-h	View this help

devicename is any name you give to mark your device in the database
Options -a, -c and -h have no devicename parameter

Database format

The table with columns "date", "url", "title", "device". 
Date is UTC.

Examples:

Rscript gethist.r SM -x desktop xfile.rds
 - extracts SeaMonkey history into file xfile.rds
Rscript gethist.r MZ -f laptop path/to/places.sqlite xfile.rds
 - extracts Mozilla (FF or SM or other) history from file places.sqlite 
into file xfile.rds
Rscript gethist.r NA -a xfile.rds dbfile.rds
 - adds file xfile.rds to database dbfile.rds
Rscript gethist.r GC -xa desktop2 dbfile.rds
 - extracts Google Chrome history and adds it to database dbfile.rds
Rscript gethist.r FF -fa laptop2 /path/to/places.sqlite dbfile.rds
 - extracts Firefox history from file places.sqlite and adds it to database
dbfile.rds
Rscript gethist.r NA -c rdsfile.rds csvfile.csv
 - converts an RDS file to a CSV file

For options -a, -xa, -fa, old main database is overwritten by the new one!

R packages required: DBI, RSQLite
Install them from R: install.packages(c("DBI", "RSQLite"))
