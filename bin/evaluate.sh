#!/bin/bash

ID=$1
basedir=$2
ingroupfile=ingroup.txt
outgroupfile=outgroup.txt
cutoffingroup=2
cutoffoutgroup=2
maxavg=2
maxmed=2

>&2 echo -e "\n###\nprocessing ID: $ID"

#evaluate for how many ingroup samples the given BUSCO is missing or fragmented
misingroup=$(cat $(grep -f $ingroupfile <(find $basedir -name "full_table*")) | grep -v "#" | grep -P "$ID" | grep -e "Missing" -e "Fragmented" | cut -f 1| wc -l)
>&2 echo -e "Number of BUSCOs missing or fragmented in the ingroup: $misingroup"
#evaluate for how many outgroup samples the given BUSCO is missing or fragmented
misoutgroup=$(cat $(grep -f $outgroupfile <(find $basedir -name "full_table*")) | grep -v "#" | grep -P "$ID" | grep -e "Missing" -e "Fragmented" | cut -f 1| wc -l)
>&2 echo -e "Number of BUSCOs missing or fragmented in the outgroup: $misoutgroup"

if [ "$misingroup" -lt "$cutoffingroup" ] && [ "$misoutgroup" -lt "$cutoffoutgroup" ]
then
        >&2 echo distribution ok
else
        >&2 echo distribution not ok
        exit 1
fi

#evaluate the number of paralogs
#average
#avg=$(cat $(find ../../ -name "full_table*") | grep -v "#" | grep -P "$ID" | cut -f 1,2 | uniq -c | perl -ne 'chomp; @a=split(" "); if ($a[2] =~ /Duplicated/){push @array, $a[0]}else{for($i=0; $i<$a[0]; $i++){push @array, 1;}}; if (eof()){$sum=0; for($i=0; $i<scalar(@array); $i++){$sum = $sum + $array[$i]}; $avg = $sum / scalar(@array); print "$avg\n"}')
avg=$(for s in $(cat $ingroupfile $outgroupfile ); do cat $(find $basedir -name "full_table*" | grep -P "$s") | grep -v "#" | grep -P "$ID" | grep -v "Missing" | grep -v "Fragmented" | wc -l; done | perl -ne 'chomp; push @array, $_; if (eof()){$sum=0; for($i=0; $i<scalar(@array); $i++){$sum = $sum + $array[$i]}; $avg = $sum / scalar(@array); print "$avg\n"}')
>&2 echo -e "Average number of paralogs per sample: $avg"
if [ "$(echo $avg'<='$maxavg | bc -l)" -eq 1 ]
then
	>&2 echo average ok
else
	>&2 echo average not ok
	exit 2
fi

#median
med=$(for s in $(cat $ingroupfile $outgroupfile ); do cat $(find $basedir -name "full_table*" | grep -P "$s") | grep -v "#" | grep -P "$ID" | grep -v "Missing" | grep -v "Fragmented" | wc -l; done | grep -v "^0$" | perl -ne 'chomp; push @array, $_; if (eof()){$len=@array; @sorted = sort {$a <=> $b} @array; print "Length: $len\t".join(" ", @sorted)."\n"; if ($len%2){print "$sorted[int($len/2)]\n"}else{$med = ($sorted[int($len/2)] + $sorted[int($len/2)-1])/2; print "$med\n"}}' | tail -n 1)
>&2 echo -e "Median number of paralogs per sample: $med"
if [ "$(echo $med'<='$maxmed | bc -l)" -eq 1 ]
then
        >&2 echo median ok
else
        >&2 echo median not ok
        exit 3
fi

>&1 echo $ID
