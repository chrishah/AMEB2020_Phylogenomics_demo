# AMEB2020_Phylogenomics_demo

We will be reconstructing the phylogenetic relationships of some oribatid mites based on previously published whole genome / transcriptome data. The list of species we will be including in the analyses, a reference to the original publication and the URL for the data download can be found in this <a href="https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/data/samples.csv" title="Sample table" target="_blank">table</a>.

All software used in the demo is deposited as Docker images on <a href="https://hub.docker.com/" title="Dockerhub" target="_blank">Dockerhub</a> (see <a href="https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/data/software.csv" title="software table" target="_blank">here</a>) and all data is freely and publicly available. 

To follow the demo and make the most of it, it helps if you have some basic skills with running software tools and manipulating files using the Unix shell command line. It assumes you have Docker installed on your computer (tested with Docker version 18.09.7, build 2d0083d; on Ubuntu 18.04). 

The workflow we will demonstrate is as follows:
- Download genomes / transcriptomes from Genbank
- Identifying complete BUSCO genes in each of the transcriptomes/genomes
- pre-filtering of orthology/BUSCO groups
- For each BUSCO group:
  - build alignment
  - trim alignment
  - identify model of protein evolution
  - infer phylogenetic tree (ML)
- post-filter orthology groups
- construct supermatrix from individual gene alignments
- infer phylogenomic tree with paritions corresponding to the original gene alignments using ML
- map internode certainty (IC) onto the phylogenomic tree

__1.) Download data from Genbank__

Let's start with the transcriptomes. These were published in Brandt et al. 2017. Effective purifying selection in ancient asexual oribatid mites. Nature Communications (very nice <a href="https://www.nature.com/articles/s41467-017-01002-8" title="Brandt et al. 2017" target="_blank">paper</a>). The authors have depsited their transcriptomes under NCBI Bioproject PRJNA339058. Let's surf to <a href="https://www.ncbi.nlm.nih.gov/" title="Genbank" target="_blank">NCBI Genbank</a>) and find it. Searching for the Bioproject gets us <a href="https://www.ncbi.nlm.nih.gov/bioproject/?term=PRJNA339058" title="PRJNA339058" target="_blank">here</a>).

After some more clicking we find a download page, like <a href="https://www.ncbi.nlm.nih.gov/Traces/wgs/?val=GEXX01" title="GEXX01" target="_blank">this</a>, for each assembly.

I'll make a new directory and download the assemblies to it, e.g. for _Achipteria coleoptrata_ - Note that the `(user@host)-$` part of the code below just mimics a command line prompt. This will look differently on each computer. The command you actually need to exectue is the part after that, so only, e.g. `mkdir assemblies`:
```bash
(user@host)-$ mkdir assemblies
(user@host)-$ cd assemblies
(user@host)-$ wget https://sra-download.ncbi.nlm.nih.gov/traces/wgs03/wgs_aux/GE/XX/GEXX01/GEXX01.1.fsa_nt.gz
```
You can use the links in the above mentioned table to download the rest. Then leave the directory.
```bash
(user@host)-$ cd .. 
```

__2.) Run BUSCO on each assembly__

First you'll need to download the reference data for BUSCO - pick and choose on their <a href="https://busco-archive.ezlab.org/v3/" title="BUSCO v3" target="_blank">webpage</a>. We go for 'Arthropoda odb9'.

```bash
(user@host)-$ wget https://busco-archive.ezlab.org/v3/datasets/arthropoda_odb9.tar.gz
```
I comes compressed, so we need to decompress:
```bash
(user@host)-$ tar xvfz arthropoda_odb9.tar.gz
```

Now we want to run BUSCO to identify the set of core genes in our transcriptome. This will take a few hours for each assembly, depending on the computational resources you have available. I'll start with one transcriptome to give you an example. I suggest you just copy paste and hit enter for now, while it is running we will talk about some details of the command.
```bash
(user@host)-$ mkdir genes
(user@host)-$ cd genes
(user@host)-$ mkdir Achipteria_coleoptrata
(user@host)-$ cd Achipteria_coleoptrata

(user@host)-$ docker run \
-v $(pwd):/in -v $(pwd)/../../assemblies/:/assemblies -v $(pwd)/../../arthropoda_odb9:/BUSCOs \
-w /in --rm \
chrishah/busco-docker:v3.1.0 \
run_BUSCO.py \
--in /assemblies/GEXX01.1.fsa_nt \
--out A_coleoptrata.A_coleoptrata.GEXX01.1 \
-l /BUSCOs \
--mode transcriptome -c 4 -f \
-sp fly --long --augustus_parameters='--progress=true'
```

Here's some more details, as promised:
If you're new to the command line the above probably looks a bit confusing. What you have here is one long command that is wrapped across several lines to make it a bit more readable. You notice that each line ends with a `\` - this tells the shell that the command is not done and will continue in the next line. You could write everything in one line. Now, the first three call the actual program that we're running `run_BUSCO.py`. This calls a number of other software tools that would all need to be installed on your system. In order to avoid that we use a Docker container, that has everything included. So, before calling the actual program we tell the program `docker` to `run` a container `chrishah/busco-docker:v3.1.0` and within it we call the program `run_BUSCO.py`. There is a few other options specified which I will come to soon, but that's the bare minimum - give it a try.
```bash
(user@host)-$ docker run chrishah/busco-docker:v3.1.0 run_BUSCO.py
ERROR	The parameter '--in' was not provided. Please add it in the config file or provide it through the command line
```
We get and error and it tells us that we have not provided a certain parameter. The question is which parameters are available. Command line programs usually have an option to show you which parameters are available to the user. This __help__ can in most be cases be called by adding a `-h` flag to the software call. There can be variations around that: sometimes it's `--help`, sometimes it's `-help`, but something like that exists for almost every command line program,s o this is a very important thing to take home from this exercise. Give it a try. 
```bash
(user@host)-$ docker run chrishah/busco-docker:v3.1.0 run_BUSCO.py -h
usage: python BUSCO.py -i [SEQUENCE_FILE] -l [LINEAGE] -o [OUTPUT_NAME] -m [MODE] [OTHER OPTIONS]

Welcome to BUSCO 3.1.0: the Benchmarking Universal Single-Copy Ortholog assessment tool.
For more detailed usage information, please review the README file provided with this distribution and the BUSCO user guide.

optional arguments:
  -i FASTA FILE, --in FASTA FILE
                        Input sequence file in FASTA format. Can be an assembled genome or transcriptome (DNA), or protein sequences from an annotated gene set.
  -c N, --cpu N         Specify the number (N=integer) of threads/cores to use.
  -o OUTPUT, --out OUTPUT
                        Give your analysis run a recognisable short name. Output folders and files will be labelled with this name. WARNING: do not provide a path
  -e N, --evalue N      E-value cutoff for BLAST searches. Allowed formats, 0.001 or 1e-03 (Default: 1e-03)
  -m MODE, --mode MODE  Specify which BUSCO analysis mode to run.
                        There are three valid modes:
                        - geno or genome, for genome assemblies (DNA)
                        - tran or transcriptome, for transcriptome assemblies (DNA)
                        - prot or proteins, for annotated gene sets (protein)
  -l LINEAGE, --lineage_path LINEAGE
                        Specify location of the BUSCO lineage data to be used.
                        Visit http://busco.ezlab.org for available lineages.
  -f, --force           Force rewriting of existing files. Must be used when output files with the provided name already exist.
  -r, --restart         Restart an uncompleted run. Not available for the protein mode
  -sp SPECIES, --species SPECIES
                        Name of existing Augustus species gene finding parameters. See Augustus documentation for available options.
  --augustus_parameters AUGUSTUS_PARAMETERS
                        Additional parameters for the fine-tuning of Augustus run. For the species, do not use this option.
                        Use single quotes as follow: '--param1=1 --param2=2', see Augustus documentation for available options.
  -t PATH, --tmp_path PATH
                        Where to store temporary files (Default: ./tmp/)
  --limit REGION_LIMIT  How many candidate regions (contig or transcript) to consider per BUSCO (default: 3)
  --long                Optimization mode Augustus self-training (Default: Off) adds considerably to the run time, but can improve results for some non-model organisms
  -q, --quiet           Disable the info logs, displays only errors
  -z, --tarzip          Tarzip the output folders likely to contain thousands of files
  --blast_single_core   Force tblastn to run on a single core and ignore the --cpu argument for this step only. Useful if inconsistencies when using multiple threads are noticed
  -v, --version         Show this version and exit
  -h, --help            Show this help message and exit
```

Now for the extra Docker parameters: 
 - `--rm`: each time you run a docker container it will be stored on your system, which after a while eats up quite a bit of space, so this option tells docker to remove the container after it's finished for good.
 - `-v`: This specifies so-called mount points, i.e. the locations where the docker container and your local computer are connected. I've actually specified three of them in the above command. For example `-v $(pwd):/in` tells docker to connect the present working directory on my computer (this will be returned by a command call $(pwd)) and a place in the container called `/in`. Then I also mount the place where the assemblies and the BUSCO genes that we've just downloaded are located into specific places in the container which I will point BUSCO to later on.
 - `-w`: specifies the working directory in the container where the command will be exectued - I'll make it `/in` - remember that `/in` is connected to my present working directory, so essentially the programm will run and write all output to my present working directory.
BTW, docker has a help function too:
```bash
#For the main docker program
(user@host)-$ docker --help
#For the run subprogram
(user@host)-$ docker run --help
```
Then I specify a number of parameters for BUSCO (you can double check with the information from the `-h` above), like:
 - the input fasta file, via `--in`
 - where the output should be written, via `--out`
 - where it can find the BUSCO set I have downloaded, via `-l`
 - that I am giving it a transcriptome, via `-mode transcriptome`
 - that I want to use 4 CPUs, via `-c 4`
 - that I want it to force overwrite any existing data, in case I ran it before in the same place, via `-f`
 - and finally a few parameters for one of the gene predictors BUSCO uses, it's called `augustus`

For genome assemblies you would do it slightly differently (the below assumes that you've downloaded the assembly and put it in the assemblies directory):
```bash
(user@host)-$ mkdir Brevipalpus_yothersi
(user@host)-$ cd Brevipalpus_yothersi

(user@host)-$ docker run /
-v $(pwd)/../../assemblies/:/assemblies -v $(pwd)/../../arthropoda_odb9:/BUSCOs -v $(pwd):/in \
--rm -w /in \
chrishah/busco-docker:v3.1.0 \
run_BUSCO.py \
--in /assemblies/GCA_003956705.1_VIB_BreviYothersi_1.0_genomic.fna \
--out B_yothersi.B_yothersi.GCA_003956705.1_VIB_BreviYothersi_1.0 \
-l /BUSCOs \
--mode genome -c 4 -f /
-sp fly --long --augustus_parameters='--progress=true'

```

Now, let's have a look at BUSCO's output. If you followed the steps above BUSCO will have created lots of files for Achipteria coleoptrata. Let's move to there and list the files:
```bash
(user@host)-$ cd genes/Achipteria_coleoptrata/run_A_coleoptrata.A_coleoptrata.GEXX01.1/
(user@host)-$ ls -1
blast_output
full_table_A_coleoptrata.A_coleoptrata.GEXX01.1.tsv
hmmer_output
missing_busco_list_A_coleoptrata.A_coleoptrata.GEXX01.1.tsv
short_summary_A_coleoptrata.A_coleoptrata.GEXX01.1.txt
translated_proteins
``` 

Usually the most interesting for people is the content of the short summary, which gives an indication of how complete your genome/transcriptome is.
```bash
(user@host)-$ cat short_summary_A_coleoptrata.A_coleoptrata.GEXX01.1.txt
# BUSCO version is: 3.1.0 
# The lineage dataset is: arthropoda_odb9 (Creation date: 2017-02-07, number of species: 60, number of BUSCOs: 1066)
# To reproduce this run: python /usr/bin/run_BUSCO.py -i /cl_tmp/hahnc/Oribatid/transcriptomes/GEXX01.1.fsa_nt -o A_coleoptrata.A_coleoptrata.GEXX01.1 -l /usr/people/EDVZ/hahnc/BUSCOS/arthropoda_odb9/ -m transcriptome -c 8 --long
#
# Summarized benchmarking in BUSCO notation for file /cl_tmp/hahnc/Oribatid/transcriptomes/GEXX01.1.fsa_nt
# BUSCO was run in mode: transcriptome

	C:95.5%[S:60.7%,D:34.8%],F:1.3%,M:3.2%,n:1066

	1018	Complete BUSCOs (C)
	647	Complete and single-copy BUSCOs (S)
	371	Complete and duplicated BUSCOs (D)
	14	Fragmented BUSCOs (F)
	34	Missing BUSCOs (M)
	1066	Total BUSCO groups searched

```

We're also interested in which BUSCO genes it actually found. Note that I am only showing the first 20 lines of the file below - it actually has 1000+ lines.
```bash
(user@host)-$ head -n 20 full_table_A_coleoptrata.A_coleoptrata.GEXX01.1.tsv
# BUSCO version is: 3.1.0 
# The lineage dataset is: arthropoda_odb9 (Creation date: 2017-02-07, number of species: 60, number of BUSCOs: 1066)
# To reproduce this run: python /usr/bin/run_BUSCO.py -i /cl_tmp/hahnc/Oribatid/transcriptomes/GEXX01.1.fsa_nt -o A_coleoptrata.A_coleoptrata.GEXX01.1 -l /usr/people/EDVZ/hahnc/BUSCOS/arthropoda_odb9/ -m transcriptome -c 8 --long
#
# Busco id	Status	Sequence	Score	Length
EOG090X0007	Duplicated	GEXX01051777.1	1627.0	3624
EOG090X0007	Duplicated	GEXX01051778.1	1638.2	3655
EOG090X002Z	Missing
EOG090X005G	Complete	GEXX01092998.1	2792.4	1909
EOG090X005Q	Complete	GEXX01108369.1	1307.2	1218
EOG090X0064	Complete	GEXX01123152.1	3094.6	1509
EOG090X00BV	Complete	GEXX01007605.1	1187.0	943
EOG090X00BY	Complete	GEXX01098713.1	2667.0	1646
EOG090X00DN	Complete	GEXX01092204.1	1502.4	1043
EOG090X00E0	Complete	GEXX01111543.1	654.9	873
EOG090X00FC	Duplicated	GEXX01070625.1	997.3	715
EOG090X00FC	Duplicated	GEXX01070626.1	997.5	715
EOG090X00GC	Duplicated	GEXX01004621.1	1920.5	863
EOG090X00GC	Duplicated	GEXX01004622.1	1920.3	863
EOG090X00GO	Complete	GEXX01034805.1	2210.6	1030
```
So, you get the status for all BUSCO genes, wheter it was complete, duplicated etc., on which sequence in your assembly it was found, how good the match was, length, etc.

Now, what we're going to do is select us a bunch of BUSCO genes to be included in our analyses. First we're just going to filter by presence/absence of data. Let's do this in a new directory.
```bash
(user@host)-$ cd ../../../
(user@host)-$ mkdir analyses
(user@host)-$ cd analyses
(user@host)-$ mkdir pre-filtering
(user@host)-$ cd pre-filtering
```

We'd want for example to identify all genes that are not missing data for more than one sample. I have grouped my species into ingroup taxa (the focal group) and outgroup taxa and I've written them to files accordingly. Note that for all of the below to work the names need to fit with the names you gave during the BUSCO run and the download.
```bash
(user@host)-$ cat ingroup.txt 
Achipteria_coleoptrata
Nothurs_palustris
Platynothrus_peltifer
Hermannia_gibba
Steganacarus_magnus
Hypochthonius_rufulus

(user@host)-$ cat outgroup.txt 
Brevipalpus_yothersi
Tetranychus_urticae
```

Let's start by looking at a random gene, say `EOG090X00BY`. You can try to do it manually, i.e. go through all the full tables, search for the gene id and take a note of what the status was. For a 1000 genes that's a bit tedious so I wrote a script to do that: `evaluate.sh`. It's in the `bin/` directory of this repository. I'll just show the first few lines of the code to give you an idea, don't worry about the details for now.
```bash
(user@host)-$ cat bin/evaluate.sh
#!/bin/bash

ID=$1
ingroupfile=ingroup.txt
outgroupfile=outgroup.txt
cutoffingroup=2
cutoffoutroup=2
maxavg=2
maxmed=2

>&2 echo -e "\n###\nprocessing ID: $ID"

#evaluate for how many ingroup samples the given BUSCO is missing or fragmented
misingroup=$(cat $(grep -f $ingroupfile <(find ../../../genes/ -name "full_table*")) | grep -v "#" | grep -P "$ID" | grep -e "Missing" -e "Fragmented" | cut -f 1| wc -l)
>&2 echo -e "Number of BUSCOs missing or fragmented in the ingroup: $misingroup"
#evaluate for how many outgroup samples the given BUSCO is missing or fragmented
misoutgroup=$(cat $(grep -f $outgroupfile <(find ../../../genes/ -name "full_table*")) | grep -v "#" | grep -P "$ID" | grep -e "Missing" -e "Fragmented" | cut -f 1| wc -l)
>&2 echo -e "Number of BUSCOs missing or fragmented in the outgroup: $misoutgroup"

if [ "$misingroup" -lt "$cutoffingroup" ] && [ "$misoutgroup" -lt "$cutoffoutgroup" ]
then
        >&2 echo distribution ok
else
        >&2 echo distribution not ok
        exit 1
fi


```

Let's try for our BUSCO `EOG090X00BY`.
```bash
(user@host)-$ ../../bin/evaluate.sh EOG090X00BY

###
processing ID: EOG090X00BY
Number of BUSCOs missing or fragmented in the ingroup: 0
Number of BUSCOs missing or fragmented in the outgroup: 0
distribution ok
Average number of paralogs per sample: 1.25
average ok
Median number of paralogs per sample: 1
median ok
EOG090X00BY
```

This passes our filter criteria. No genes missing, average number of paralogs per sample < 2 and median number of paralogs is < 2 , as well. Great.

Now, the idea is to run this for all of the BUSCO genes. I would do that as follows - let's build us a complex command. First we need to find a way of getting a list of all BUSCO IDs - Note that I am only showing the first 10 lines of the output.
```bash
(user@host)-$ cat ../../genes/Achipteria_coleoptrata/run_A_coleoptrara.A_coleoptrata.GEXX01.1/full_table_A_coleoptrara.A_coleoptrata.GEXX01.1.tsv | grep -v "#" | cut -f 1 | head
```
Then, I wrap a for loop around this list.
```bash
(user@host)-$ for B in $(cat ../../genes/Achipteria_coleoptrata/run_A_coleoptrara.A_coleoptrata.GEXX01.1/full_table_A_coleoptrara.A_coleoptrata.GEXX01.1.tsv | grep -v "#" | cut -f 1)
do
	echo $B
done
```

Now I run the script from before for each of the BUSCO ids. We just add one line in the for loop. For this test I also limit the number of ids to be processed to 10, this is what the `head` at the end of line one is doing. If we're satisified we can remove the `head` to get it done for the full list.

```bash
(user@host)-$ for B in $(cat ../../genes/Achipteria_coleoptrata/run_A_coleoptrara.A_coleoptrata.GEXX01.1/full_table_A_coleoptrara.A_coleoptrata.GEXX01.1.tsv | grep -v "#" | cut -f 1 | head )
do
	../../bin/evaluate.sh $B
done
```
Command line programs can output to two different channels, the so-called standard-out (STDOUT) and standard-error (STDERR). I've designed the script to output different information to different channels. Spefically, I made it that it ouptuts the summary to STDERR and to STDOUT it sends just the IDs of BUSCO genes that pass our filters.
```bash
(user@host)-$ for B in $(cat ../../genes/Achipteria_coleoptrata/run_A_coleoptrara.A_coleoptrata.GEXX01.1/full_table_A_coleoptrara.A_coleoptrata.GEXX01.1.tsv | grep -v "#" | cut -f 1 | head )
do
	../../bin/evaluate.sh $B
done 1> list.txt
```

Have a look at the list.
```bash
(user@host)-$ cat list.txt 
EOG090X005G
EOG090X005Q
EOG090X0064
EOG090X00BV
EOG090X00BY
EOG090X00DN
EOG090X00E0
```

I could also write the list and at the same time the summaries to a different file.

```bash
(user@host)-$ for B in $(cat ../../genes/Achipteria_coleoptrata/run_A_coleoptrara.A_coleoptrata.GEXX01.1/full_table_A_coleoptrara.A_coleoptrata.GEXX01.1.tsv | grep -v "#" | cut -f 1 | head )
do
	../../bin/evaluate.sh $B
done 1> list.txt 2> summaries.txt
```

Have a look at the summaries (just showing the first few lines here).
```bash
(user@host)-$ cat summaries.txt

###
processing ID: EOG090X0007
Number of BUSCOs missing or fragmented in the ingroup: 0
Number of BUSCOs missing or fragmented in the outgroup: 0
distribution ok
Average number of paralogs per sample: 2.375
average not ok

###
processing ID: EOG090X0007
Number of BUSCOs missing or fragmented in the ingroup: 0
Number of BUSCOs missing or fragmented in the outgroup: 0
distribution ok
Average number of paralogs per sample: 2.375
average not ok


```

For each one that ends up on our list, we want to:
 - bring together all sequences from all samples in one file
 - do multiple sequence alignment
 - filter the alignment, i.e. remove ambiguous/problematic positions
 - build a phylogenetic tree


Here are all steps for `EOG090X0007` as an example.

Specify the name of the BUSCO gene and the number of CPU cores to use for analyses.
```bash
(user@host)-$ ID=EOG090X0007
(user@host)-$ threads=3
```

Perform multiple sequence alignment with [clustalo](http://www.clustal.org/omega/).
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/clustalo-docker:1.2.4 \
clustalo -i $ID.fasta -o $ID.clustalo.aln.fasta --threads=$threads
```

We can then look at the alignment result. There is a number of programs available to do that, e.g. MEGA, Jalview, Aliview, or you can do it online (thanks to @HannesOberreiter for the tip). A link to the upload client for the NCBI Multiple Sequence Alignment Viewer is [here](https://www.ncbi.nlm.nih.gov/projects/msaviewer/?appname=ncbi_msav&openuploaddialog) (I suggest to open in new tab). Upload (`EOG090X0007.clustalo.aln.fasta`), press 'Close' button, and have a look.

What do you think? It's actually quite messy.. 

Let's move on to score and filter the alignment, using [Aliscore](https://www.zfmk.de/en/research/research-centres-and-groups/aliscore) and [Alicut](https://github.com/PatrickKueck/AliCUT) programs. 
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 \
Aliscore.pl -N -r 200000000000000000 -i $ID.clustalo.aln.fasta &> aliscore.log
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 \
ALICUT.pl -s &> alicut.log
```
Try open the upload [dialog](https://www.ncbi.nlm.nih.gov/projects/msaviewer/?appname=ncbi_msav&openuploaddialog) for the Alignment viewer in a new tab and upload the new file (`ALICUT_EOG090X0007.clustalo.aln.fasta`).
What do you think? The algorithm has removed some 9000 bp of the original alignment, reducing it to only ~500, but these look much better. 

Find best model of evolution for phylogenetic inference (first set up a new directory to keep things organized) using a script from [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/).
```bash
(user@host)-$ mkdir find_best_model
(user@host)-$ cd find_best_model
(user@host)-$ cp ../ALICUT_$ID.clustalo.aln.fasta .

(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 \
ProteinModelSelection.pl ALICUT_$ID.clustalo.aln.fasta > $ID.bestmodel

(user@host)-$ cd .. #move back to the base directory (if you forget the following will not work, because the location of the files will not fit to the command - happened to me before ;-)
```

Infer phylogenetic tree using [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/). The first line just reads the output from the previous command, i.e. the best model, reformats it and writes it and saves it in a variable. 

The RAxML command in a nutshell:
 - `-f a` - use rapid bootstrapping mode (search for the best-scoring ML tree and run bootstrap in one analysis)
 - `-T` - number of CPU threads to use
 - `-m` - model of protein evolution - note that we add in the content of our variable `$RAxMLmodel`
 - `-p 12345` - Specify a random number seed for the parsimony inferences (which give will become the basis for the ML inference, which is much more computationally intensive). The number doesn't affect the result, but it allows you to reproduce your analyses, so run twice with the same seed, should give the exact same tree.
 - `-x 12345` - seed number for rapid bootstrapping. For reproducibility, similar to above.
 - `-# $bs` - number of bootstrap replicates - note that we put the variable `$bs` here that we've defined above
 - `-s` - input fasta file (the filtered alignemnt)
 - `-n` - prefix for output files to be generated

```bash
(user@host)-$ RAxMLmodel=$(cat find_best_model/$ID.bestmodel | grep "Best" | cut -d ":" -f 2 | tr -d '[:space:]') #this line reads in the file that countains the output from the best model search, reformats it and saves it to a variable
(user@host)-$ bs=100 #set the number of bootstrap replicates
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 \
raxml -f a -T $threads -m PROTGAMMA$RAxMLmodel \
-p 12345 -x 12345 -# $bs \
-s ALICUT_$ID.clustalo.aln.fasta -n $ID.clustalo.aln.ALICUT.$RAxMLmodel &> raxml.log
```

__To be continued ..__
