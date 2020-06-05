#!/bin/bash

ID=$1
basedir="$(realpath $2)"
ingroup=$3
outgroup=$4

echo -n "" > $ID.fasta
for out in $(cat $outgroup)
do
	echo -ne "ID: $ID - sample: $out - "
	single=$(cat $(grep -P "$out" <(find $basedir -name "full_*")) | grep "Complete" | grep "$ID" | cut -f 1)
	if [ -s "$(grep -P "$out" <(find $basedir -name "single_copy*"))/$ID.faa" ]
	then
		echo -e "FOUND"
		echo -e ">$out" >> $ID.fasta
		cat $(grep -P "$out" <(find $basedir -name "single_copy*"))/$single.faa | tail -n 1 >> $ID.fasta
	else
		echo -e "MISSING"
#		echo -e ">$out\n-" >> $ID.fasta
	fi
done
for sample in $(cat $ingroup)
do
	echo -ne "ID: $ID - sample: $sample - "
	trans=$(grep -P "$ID" $(grep -P "$sample" <(find $basedir -name "full_*")) | sort -nr -k 4 | head -n 1 | cut -f 3)
	echo -ne "$trans - "
	if [ -s "$(find $basedir -name "translated_proteins" | grep -P "$sample")/$trans.faa" ]
	then
		echo -ne "FOUND - "
		cat $ID.fasta | grep "^[A-Z]" -B 1 | head -n 2 > $ID.$sample.subject.fasta
		cat $(find $basedir -name "translated_proteins" | grep -P "$sample")/$trans.faa > $ID.$sample.query.fasta
		cmd="blastp -query $ID.$sample.query.fasta -subject $ID.$sample.subject.fasta -evalue 1e-10 -outfmt 6 -out $ID.$sample.blastp.out"
		echo -e "\n$cmd"
		docker run -it --rm -v $(pwd):/in -w /in chrishah/ncbi-blast:v2.6.0 $cmd
		best=$(cat $ID.$sample.blastp.out | cut -f 1 | sort -n | uniq)

#		docker run -it --rm -v $(pwd):/in -w /in chrishah/ncbi-blast:v2.6.0 blastp
		if [ ! -z $best ]
		then
			echo -e "$best"
			echo -e ">$sample" >> $ID.fasta
			cat $(find $basedir -name "translated_proteins" | grep -P "$sample")/$trans.faa | grep -P ">$best" -A 1 | tail -n 1 >> $ID.fasta
		else
			echo -e "not good enough"
#			echo -e ">$sample\n-" >> $ID.fasta
		fi
	else
		echo -e "MISSING"
#		echo -e ">$sample\n-" >> $ID.fasta
	fi

done
