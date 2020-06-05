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

Let's start by looking at a random gene, say `EOG090X00BY`. You can try to do it manually, i.e. go through all the full tables, search for the gene id and take a note of what the status was. For a 1000 genes that's a bit tedious so I wrote a script to do that: `evaluate.py`. It's in the `bin/` directory of this repository - go [here](https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/bin/evaluate.py), if you're interested in the code.

You can execute it like so:
```bash
(user@host)-$ ../../bin/evaluate.py
usage: evaluate.py [-h] -i IN_LIST [--max_mis_in INT] -o OUT_LIST
                   [--max_mis_out INT] [--max_avg INT] [--max_med INT] -f
                   TABLES [TABLES ...] [-B [IDs [IDs ...]]] [--outfile FILE]
```
Or, like this, if you want some more info:
```bash
(user@host)-$ ../../bin/evaluate.py -h
usage: evaluate.py [-h] -i IN_LIST [--max_mis_in INT] -o OUT_LIST
                   [--max_mis_out INT] [--max_avg INT] [--max_med INT] -f
                   TABLES [TABLES ...] [-B [IDs [IDs ...]]] [--outfile FILE]

Pre-filter BUSCO sets for phylogenomic analyses

optional arguments:
  -h, --help            show this help message and exit
  -i IN_LIST, --in_list IN_LIST
                        path to text file containing the list of ingroup taxa
  --max_mis_in INT      maximum number of samples without data in the ingroup,
                        default: 0, i.e. all samples have data
  -o OUT_LIST, --out_list OUT_LIST
                        path to text file containing the list of outgroup taxa
  --max_mis_out INT     maximum number of samples without data in the
                        outgroup, default: 0, i.e. all samples have data
  --max_avg INT         maximum average number of paralog
  --max_med INT         maximum median number of paralogs
  -f TABLES [TABLES ...], --files TABLES [TABLES ...]
                        full BUSCO results tables that should be evaluated
                        (space delimited), e.g. -f table1 table2 table3
  -B [IDs [IDs ...]], --BUSCOs [IDs [IDs ...]]
                        list of BUSCO IDs to be evaluated, e.g. -B EOG090X0IQO
                        EOG090X0GLS
  --outfile FILE        name of outputfile to write results to

```

Let's try it for our BUSCO `EOG090X00BY`. We can stitch together the command by following the info from the help (not showing the output here). Note that I specify tables I have deposited as backup data in the repo, for demonstration. If you actually ran BUSCO yourselve according to the instructions above, you should adjust the paths, to e.g. `../../genes/Achipteria_coleoptrata/full_table_A_coleoptrata.A_coleoptrata.GEXX01.1.tsv` and so forth.
```bash
(user@host)-$ ../../bin/evaluate.py \
-i ingroup.txt -o outgroup.txt --max_mis_in 1 --max_mis_out 1 \
--max_avg 2 --max_med 2 \
-B EOG090X00BY \
-f ../../data/checkpoints/BUSCO_results/Achipteria_coleoptrata/full_table_A_coleoptrata.A_coleoptrata.GEXX01.1.tsv \
../../data/checkpoints/BUSCO_results/Brevipalpus_yothersi/full_table_B_yothersi.B_yothersi.GCA_003956705.1_VIB_BreviYothersi_1.0.tsv \
../../data/checkpoints/BUSCO_results/Hermannia_gibba/full_table_H_gibba.H_gibba.GEYB01.1.tsv \
../../data/checkpoints/BUSCO_results/Hypochthonius_rufulus/full_table_H_rufulus.H_rufulus.GEYP01.1.tsv \
../../data/checkpoints/BUSCO_results/Nothurs_palustris/full_table_N_palustris.N_palustris.GEYJ01.1.tsv \
../../data/checkpoints/BUSCO_results/Platynothrus_peltifer/full_table_P_peltifer.P_peltifer.GEYZ01.1.tsv \
../../data/checkpoints/BUSCO_results/Steganacarus_magnus/full_table_S_magnus.S_magnus.GEYQ01.1.tsv \
../../data/checkpoints/BUSCO_results/Tetranychus_urticae/full_table_T_urticae.T_urticae.GCF_000239435.1_ASM23943v1.tsv
```

This BUSCO passes our filter criteria. No more than one sample missing for either the in- or the outgroup, average number of paralogs per sample <= 2 and median number of paralogs is <= 2 , as well. Great.
With some 'bash-magic' I don't even need to manually list all the tables (not showing the output here) - again, I am just pointing to my backup tables here, if you actually ran all of the above you'd need to adjust to `-f $(find ../../genes/ -name "full_table*")`.
```bash
(user@host)-$ ../../bin/evaluate.py \
-i ingroup.txt -o outgroup.txt --max_mis_in 1 --max_mis_out 1 \
--max_avg 2 --max_med 2 \
-B EOG090X00BY \
-f $(find ../../data/checkpoints/BUSCO_results/ -name "full_table*")
```

And finally, we can just run it across all BUSCO genes, by not specifying any partiular BUSCO Id. Note that I have provided the name for an output file that will receive the summary.
```bash
(user@host)-$ ../../bin/evaluate.py \
-i ingroup.txt -o outgroup.txt --max_mis_in 1 --max_mis_out 1 \
--max_avg 2 --max_med 2 \
--outfile evaluate.all.tsv \
-f $(find ../../data/checkpoints/BUSCO_results/ -name "full_table*") # or -f $(find ../../genes/ -name "full_table*")

# Ingroup taxa: ['Achipteria_coleoptrata', 'Nothurs_palustris', 'Platynothrus_peltifer', 'Hermannia_gibba', 'Steganacarus_magnus', 'Hypochthonius_rufulus']
# Outgroup taxa ['Brevipalpus_yothersi', 'Tetranychus_urticae']
# tables included: ['../../data/checkpoints/BUSCO_results/Nothurs_palustris/full_table_N_palustris.N_palustris.GEYJ01.1.tsv', '../../data/checkpoints/BUSCO_results/Hypochthonius_rufulus/full_table_H_rufulus.H_rufulus.GEYP01.1.tsv', '../../data/checkpoints/BUSCO_results/Tetranychus_urticae/full_table_T_urticae.T_urticae.GCF_000239435.1_ASM23943v1.tsv', '../../data/checkpoints/BUSCO_results/Achipteria_coleoptrata/full_table_A_coleoptrata.A_coleoptrata.GEXX01.1.tsv', '../../data/checkpoints/BUSCO_results/Brevipalpus_yothersi/full_table_B_yothersi.B_yothersi.GCA_003956705.1_VIB_BreviYothersi_1.0.tsv', '../../data/checkpoints/BUSCO_results/Steganacarus_magnus/full_table_S_magnus.S_magnus.GEYQ01.1.tsv', '../../data/checkpoints/BUSCO_results/Platynothrus_peltifer/full_table_P_peltifer.P_peltifer.GEYZ01.1.tsv', '../../data/checkpoints/BUSCO_results/Hermannia_gibba/full_table_H_gibba.H_gibba.GEYB01.1.tsv']
# maximum number of ingroup samples with missing data: 1
# maximum number of outgroup samples with missing data: 1
# maximum average number of paralogs: 2
# maximum median number of paralogs: 2
#
# found BUSCO table for taxon Nothurs_palustris -> ingroup
# found BUSCO table for taxon Hypochthonius_rufulus -> ingroup
# found BUSCO table for taxon Tetranychus_urticae -> outgroup
# found BUSCO table for taxon Achipteria_coleoptrata -> ingroup
# found BUSCO table for taxon Brevipalpus_yothersi -> outgroup
# found BUSCO table for taxon Steganacarus_magnus -> ingroup
# found BUSCO table for taxon Platynothrus_peltifer -> ingroup
# found BUSCO table for taxon Hermannia_gibba -> ingroup
# Evaluated 1043 BUSCOs - 940 (90.12 %) passed

```

For each of the BUSCOs that passed we want to:
 - bring together all sequences from all samples in one file
 - do multiple sequence alignment
 - filter the alignment, i.e. remove ambiguous/problematic positions
 - build a phylogenetic tree


Here are all steps for `EOG090X04G3` as an example. I have deposited the intiial fasta file in the data directory.
```bash
(user@host)-$ cd ../
(user@host)-$ mkdir per_gene
(user@host)-$ mkdir EOG090X04G3
(user@host)-$ cp ../../data/checkpoints/per_gene/EOG090X04G3/EOG090X04G3.fasta .
```

Now, step by step.
Specify the name of the BUSCO gene and the number of CPU cores to use for analyses in variables so you don't have to type it out every time.
```bash
(user@host)-$ ID=EOG090X04G3
(user@host)-$ threads=3
```

Perform multiple sequence alignment with [clustalo](http://www.clustal.org/omega/).
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/clustalo-docker:1.2.4 \
clustalo -i $ID.fasta -o $ID.clustalo.aln.fasta --threads=$threads
```

We can then look at the alignment result. There is a number of programs available to do that, e.g. MEGA, Jalview, Aliview, or you can do it online (thanks to [@HannesOberreiter](https://github.com/HannesOberreiter) for the tip). A link to the upload client for the NCBI Multiple Sequence Alignment Viewer is [here](https://www.ncbi.nlm.nih.gov/projects/msaviewer/?appname=ncbi_msav&openuploaddialog) (I suggest to open in new tab). Upload (`EOG090X04G3.clustalo.aln.fasta`), press 'Close' button, and have a look.

What do you think? It's actually quite messy.. 

Let's move on to score and filter the alignment, using [Aliscore](https://www.zfmk.de/en/research/research-centres-and-groups/aliscore) and [Alicut](https://github.com/PatrickKueck/AliCUT) programs. 
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 \
Aliscore.pl -N -r 200000000000000000 -i $ID.clustalo.aln.fasta &> aliscore.log
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 \
ALICUT.pl -s &> alicut.log
```
Try open the upload [dialog](https://www.ncbi.nlm.nih.gov/projects/msaviewer/?appname=ncbi_msav&openuploaddialog) for the Alignment viewer in a new tab and upload the new file (`ALICUT_EOG090X04G3.clustalo.aln.fasta`).
What do you think? The algorithm has removed some 1000 bp of the original alignment, reducing it to only ~500, but these look much better. 

Find best model of evolution for phylogenetic inference (first set up a new directory to keep things organized) using a script from [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/).
```bash
(user@host)-$ mkdir find_best_model
(user@host)-$ cd find_best_model
(user@host)-$ cp ../ALICUT_$ID.clustalo.aln.fasta .

(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 \
ProteinModelSelection.pl ALICUT_$ID.clustalo.aln.fasta > $ID.bestmodel

(user@host)-$ cd .. #move back to the base directory (if you forget the following will not work, because the location of the files will not fit to the command - happened to me before ;-)
```

Infer phylogenetic tree using [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/). The first line just reads the output from the previous command, i.e. the best model, reformats it and saves it in a variable. 

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

This runs for a while. RAxML produces a log file that we can inspect. Just looking at the last 15 lines with the `tail` command.
```bash
(user@host)-$ tail -n 15 RAxML_info.EOG090X04G3.clustalo.aln.ALICUT.LGF

Found 1 tree in File /cl_tmp/hahnc/Oribatid_2/analyses/test/test/EOG090X04G3/RAxML_bestTree.EOG090X04G3.clustalo.aln.ALICUT.LGF

Program execution info written to /cl_tmp/hahnc/Oribatid_2/analyses/test/test/EOG090X04G3/RAxML_info.EOG090X04G3.clustalo.aln.ALICUT.LGF
All 100 bootstrapped trees written to: /cl_tmp/hahnc/Oribatid_2/analyses/test/test/EOG090X04G3/RAxML_bootstrap.EOG090X04G3.clustalo.aln.ALICUT.LGF

Best-scoring ML tree written to: /cl_tmp/hahnc/Oribatid_2/analyses/test/test/EOG090X04G3/RAxML_bestTree.EOG090X04G3.clustalo.aln.ALICUT.LGF

Best-scoring ML tree with support values written to: /cl_tmp/hahnc/Oribatid_2/analyses/test/test/EOG090X04G3/RAxML_bipartitions.EOG090X04G3.clustalo.aln.ALICUT.LGF

Best-scoring ML tree with support values as branch labels written to: /cl_tmp/hahnc/Oribatid_2/analyses/test/test/EOG090X04G3/RAxML_bipartitionsBranchLabels.EOG090X04G3.clustalo.aln.ALICUT.LGF

Overall execution time for full ML analysis: 99.661946 secs or 0.027684 hours or 0.001153 days

```

And of course, we get our best scoring Maximum Likelihood tree.
```bash
(user@host)-$ cat RAxML_bipartitions.EOG090X04G3.clustalo.aln.ALICUT.LGF 
(Brevipalpus_yothersi:0.43039306117005621255,(Steganacarus_magnus:0.09680068148564281716,(Hypochthonius_rufulus:0.20675998146041871251,(Achipteria_coleoptrata:0.15727077153973773038,(Hermannia_gibba:0.10769294466691085865,(Platynothrus_peltifer:0.03340722062320617552,Nothurs_palustris:0.08095982609739513225)76:0.03142039453455876957)29:0.01750097415629610353)62:0.03268431994817945496)50:0.03513499598331231571)100:0.61901499059949005588,Tetranychus_urticae:0.59243976530101283284);
```
.. in the Newick tree format. There is a bunch of programs that allow you to view and manipulate trees in this format. You can only do it online, for example through [ETE3](http://etetoolkit.org/treeview/), [icytree](https://icytree.org/), or [trex](http://www.trex.uqam.ca/index.php?action=newick&project=trex). You can try it out.

Now, let's say we want to go over this process for each of our 900+ genes that passd our filtering criteria. A script that does all the above steps run for each BUSCO would do it. I've made a very simple one that also fetches the individual genes for each of the BUSCO ids. You could try e.g. the following, which assumes this:
  - you've run the BUSCO analyses for all datasets and they are in directories called like the name of the species in the `genes/` directory, so, e.g.: `genes/Achipteria_coleoptrata`
  - the directory where you are running the following contains the files `ingroup.txt` and `outgroup.txt` that list the taxa to be considered ingroup and outgroup, respectively. The taxon names need to correspond to the sample specific directories you ran the BUSCO analysis in. The below runs it for the first three BUSCOs that passed our criteria. If you want to run it for all, remove the `head -n 3`.


```bash
(user@host)-$ threads=3
(user@host)-$ for BUSCO in $(cat ../pre-filtering/evaluate.all.tsv | grep "pass$" | cut -f 1 | head -n 3)
do
	../../bin/per_BUSCO.sh $BUSCO $threads ../../genes/
done 
```
 
Next step is to concatenate all trimmed alignments into a single supermatrix. Let's do that in a new directory.
```bash
(user@host)-$ cd ../
(user@host)-$ cd post-filtering-concat
(user@host)-$ cd post-filtering-concat
```

I've made a simple script that finds the trimmed alignments given our data structure and only keeps alignemnts that are longer than 200 amino acids.
```bash
(user@host)-$ ../../bin/post-filter.sh ../../data/checkpoints/per_gene/OTHERS/
```

Now, let's concatenate all files into a single supermatrix using `FASconCAT-g` (see [here](https://www.zfmk.de/en/research/research-centres-and-groups/fasconcat-g)).
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/fasconcat-g:1.04 \
FASconCAT-G.pl -a -a -s > concat.log
#remove the indivdiual alignment files. We don't need them any more.
(user@host)-$ rm *.aln.fas

```

Took a few seconds. We can look at the logfile `concat.log` to get some info about our supermatrix. The info is also there in an excel table `FcC_info.xls`.
```bash
(user@host)-$ less concat.log
```

Now, we're ready to build our phylogenomic tree. First we need to put two more files in place. I'll do that in a new directory. First, I just copy the supermatrix from the previous step to here. Second, I create a so-called partition file `partitions.txt`, that contains the coordinates of the original genes in the supermatrix and specifies the best model of protein evolution we've determined before. I'll get this info from the output of FASconCAT and our individual gene analyses with some 'bash-magic'.
```bash
(user@host)-$ cd ..
(user@host)-$ mkdir phylogenomic-ML
(user@host)-$ cd phylogenomic-ML

#get supermatrix
(user@host)-$ cp ../post-filtering-concat/FcC_supermatrix.fas .

#create partitions file
(user@host)-$ for line in $(cat ../post-filtering-concat/FcC_info.xls | grep "ALICUT" | cut -f 1-3 | sed 's/\t/|/g')
do
	id=$(echo -e "$line" | cut -d "|" -f 1 | sed 's/ALICUT_//' | sed 's/.clustalo.*//')
	model=$(cat $(find ../per_gene/ -name "$id.bestmodel") | grep "Best" | cut -d ":" -f 2 | tr -d '[:space:]')
	echo -e "$model, $id = $(echo -e "$line" | cut -d "|" -f 2,3 | sed 's/|/-/')"
done > partitions.txt

```

Run RAxML.
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 \
raxml -f a -T 3 -m PROTGAMMAWAG -p 12345 -q ./partitions.txt -x 12345 -# 100 -s FcC_supermatrix.fas -n super
```

This will run for a relatively long time.

I've deposited the final tree under `data/checkpoints/phylogenomics_ML/RAxML_bipartitions.alignment_min6`.

We can inspect it in one of the above mentioned online tree viewers. 

__To be continued ..__
