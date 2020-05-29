#!/bin/bash

searchdir=$1

for fasta in $(find $searchdir -name 'ALICUT_*' | grep -v "best_model" | grep -v "reduced")
do
        count=$(cat $fasta | grep ">" | wc -l)
        length=$(head -n 2 $fasta | tail -n 1 | wc | perl -ne 'chomp; @a=split(" "); print "$a[-1]\n"')
        echo -en "$fasta\t$count\t$length"
        if [ "$count" -gt 5 ] && [ "$length" -ge 200 ]
        then
                echo -e "\tpass"
                new=$(echo -e "$fasta" | perl -ne 'chomp; @a=split("/"); $a[-1] =~ s/fasta/fas/; print "$a[-1]\n"')
                cp $fasta $new
        else
                echo -e "\tfilter"
        fi
done

