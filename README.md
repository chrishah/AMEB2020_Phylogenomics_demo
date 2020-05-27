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

I'll make a new directory and download the assemblies to it, e.g. for _Achipteria coleoptrata_:
```bash
mkdir assemblies
cd assemblies
wget https://sra-download.ncbi.nlm.nih.gov/traces/wgs03/wgs_aux/GE/XX/GEXX01/GEXX01.1.fsa_nt.gz

# You can use the links in the above mentioned table to download the rest

cd .. 
```

__2.) Run BUSCO on each assembly__

First you'll need to download the reference data for BUSCO - pick and choose on their <a href="https://busco-archive.ezlab.org/v3/" title="BUSCO v3" target="_blank">webpage</a>. We go for 'Arthropoda odb9'.

```bash
#download
wget https://busco-archive.ezlab.org/v3/datasets/arthropoda_odb9.tar.gz

#decompress
tar xvfz arthropoda_odb9.tar.gz
```

Running BUSCO will take a few hours for each assembly, depending on the computational resources you have available. I'll start with one transcriptome to give you an example. I suggest you just copy paste and hit enter for now, while it is running we will talk about some details of the command.
```bash
mkdir genes
cd genes
mkdir Achipteria_coleoptrata
cd Achipteria_coleoptrata

docker run \
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

If you're new to the command line the above probably looks a bit confusing. What you have here is one long command that is wrapped across several lines to make it a bit more readable. You notice that each line ends with a `\` - this tells the shell that the command is not done and will continue in the next line. You could write everything in one line. Now, the first three call the actual program that we're running `run_BUSCO.py`. This calls a number of other software tools that would all need to be installed on your system. In order to avoid that we use a Docker container, that has everything included. So, before calling the actual program we tell the program `docker` to `run` a container `chrishah/busco-docker:v3.1.0` and within it we call the program `run_BUSCO.py`. There is a few other options specified which I will come to soon, but that's the bare minimum - give it a try.
```bash
docker run chrishah/busco-docker:v3.1.0 run_BUSCO.py
RROR	The parameter '--in' was not provided. Please add it in the config file or provide it through the command line
```
We get and error and it tells us that we have not provided a certain parameter. The question is which parameters are available. Command line programs usually have an option to show you which parameters are available to the user. This __help__ can in most be cases be called by adding a `-h` flag to the software call. There can be variations around that: sometimes it's `--help`, sometimes it's `-help`, but something like that exists for almost every command line program,s o this is a very important thing to take home from this exercise. Give it a try. 
```bash
docker run chrishah/busco-docker:v3.1.0 run_BUSCO.py -h
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
docker --help
#For the run subprogram
docker run --help
```
Then I specify a number of parameters for BUSCO (you can double check with the information from the `-h` above), like:
 - the input fasta file, via `--in`
 - where the output should be written, via `--out`
 - where it can find the BUSCO set I have downloaded, via `-l`
 - that I am giving it a transcriptome, via `-mode transcriptome`
 - that I want to use 4 CPUs, via `-c 4`
 - that I want it to force overwrite any existing data, in case I ran it before in the same place, via `-f`
 - and finally a few parameters for one of the gene predictors BUSCO uses, it's called `augustus`

For genome assemblies you would do it slightly differently:
```bash
mkdir Brevipalpus_yothersi
cd Brevipalpus_yothersi

docker run /
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

Now, let's have a look at BUSCO's output. 
__To be continued ..__
