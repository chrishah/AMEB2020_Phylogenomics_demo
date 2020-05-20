
ID=$1
threads=$2
basedir=/home/monogen/Desktop/Oribatid_2/genes

echo -e "\n###\nprocessing ID: $ID"


if [ ! -d "$ID" ]
then
	mkdir $ID
fi

cd $ID
echo -n "" > $ID.fasta
for out in $(cat ../outgroup.txt)
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
for sample in $(cat ../ingroup.txt)
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
		echo "$cmd"
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


#alignment
#echo -e "\n[$(date)]\tLoading cluster's singularity modules"
#module load go/1.11 singularity/3.4.1

echo -e "\n[$(date)]\tAignment with clustalo"
cmd="clustalo -i $ID.fasta -o $ID.clustalo.aln.fasta --threads=$threads"
echo -e "[Running .. ] $cmd"
#singularity exec -B /cl_tmp/hahnc docker://chrishah/clustalo-docker:1.2.4 \

docker run --rm -v $(pwd):/in -w /in chrishah/clustalo-docker:1.2.4 clustalo -i $ID.fasta -o $ID.clustalo.aln.fasta --threads=$threads

#aliscore and alicut
echo -e "\n[$(date)]\tEvaluating (Aliscore) and trimming alignment (ALICUT)"
#cd $ID
cmd="Aliscore.pl -N -r 200000000000000000 -i $ID.clustalo.aln.fasta &> aliscore.log"
echo -e "[Running .. ] $cmd"
#singularity exec -B /cl_tmp/hahnc docker://chrishah/alicut-aliscore-docker:2.31 \

docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 Aliscore.pl -N -r 200000000000000000 -i $ID.clustalo.aln.fasta &> aliscore.log

cmd="ALICUT.pl -s &> alicut.log"
echo -e "[Running .. ] $cmd"
#singularity exec -B /cl_tmp/hahnc docker://chrishah/alicut-aliscore-docker:2.31 \
docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 ALICUT.pl -s &> alicut.log

#find best model for RAxml
echo -e "\n[$(date)]\tFinding best model for RAxML"
mkdir find_best_model
cd find_best_model
cp ../ALICUT_$ID.clustalo.aln.fasta .
cmd="ProteinModelSelection.pl ALICUT_$ID.clustalo.aln.fasta"
echo -e "[Running .. ] $cmd"
#singularity exec -B /cl_tmp/hahnc docker://chrishah/raxml-docker:8.2.12 \

docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 $cmd > $ID.bestmodel
cd ..

#run RAxML
echo -e "\n[$(date)]\tRunning RAxML"
RAxMLmodel=$(cat find_best_model/$ID.bestmodel | grep "Best" | cut -d ":" -f 2 | tr -d '[:space:]')
bs=100
cmd="raxml -f a -T $threads -m PROTGAMMA$RAxMLmodel -p 12345 -x 12345 -# $bs -s ALICUT_$ID.clustalo.aln.fasta -n $ID.clustalo.aln.ALICUT.$RAxMLmodel &> raxml.log"
echo -e "[Running .. ] $cmd"

#singularity exec -B /cl_tmp/hahnc docker://chrishah/raxml-docker:8.2.12 \
docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 $cmd


echo -e "\n[$(date)]\tDone! \n"
#cd ..



