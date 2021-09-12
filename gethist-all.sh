#!/bin/bash

browsers=("SM" "FF" "GC" "CH" "VV" "OP" "ED")
for BR in ${browsers[*]}; do
    Rscript gethist.r $BR -x mydevice "$BR"_hist.rds
done
histf=(`ls -d *_hist.rds`)
f0=${histf[0]}
echo $f0
for f in ${histf[*]}; do 
    if [ "$f" != "$f0" ] 
    then
	echo "Adding file $f"
	Rscript gethist.r NA -a $f $f0
	rm $f
    fi
done
mv $f0 ALL_hist.rds
Rscript gethist.r NA -c ALL_hist.rds ALL_hist.csv