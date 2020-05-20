# AMEB2020_Phylogenomics_demo

We will be reconstructing the phylogenetic relationships of some oribatid mites based on previously published whole genome / transcriptome data. The list of species we will be including in the analyses, a reference to the original publication and the URL for the data download can be found in this <a href="https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/data/samples.csv" title="Sample table" target="_blank">table</a>.

All software used in the demo is deposited in Docker containers (see <a href="https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/data/software.csv" title="software table" target="_blank">here</a>) and all data is freely and publicly available. 

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

First you'll need to download the reference data for BUSCO - pick and choose on their <a href="https://busco-archive.ezlab.org/v3/" title="GEXX01" target="_blank">webpage</a>. We go for 'Arthropoda odb9'.

```bash
#download
wget https://busco-archive.ezlab.org/v3/datasets/arthropoda_odb9.tar.gz

#decompress
tar xvfz arthropoda_odb9.tar.gz
```

Running BUSCO will take a few hours for each assembly, depending on the computational resources you have available. I'll start with one transcriptome to give you an example.
```bash
mkdir genes
cd genes
mkdir Achipteria_coleoptrata
cd Achipteria_coleoptrata

docker run --rm \
-v $(pwd)/../../assemblies/:/assemblies -v $(pwd)/../../arthropoda_odb9:/BUSCOs -v $(pwd):/in -w /in \
chrishah/busco-docker:v3.1.0 \
run_BUSCO.py \
--in /assemblies/GEXX01.1.fsa_nt \
--out A_coleoptrara.A_coleoptrata.GEXX01.1 \
-l /BUSCOs \
--mode transcriptome -c 4 -f -sp fly --long --augustus_parameters='--progress=true'
```

For genome assemblies you would do it slightly differently:
```bash
mkdir Brevipalpus_yothersi
cd Brevipalpus_yothersi

docker run --rm \
-v $(pwd)/../../assemblies/:/assemblies -v $(pwd)/../../arthropoda_odb9:/BUSCOs -v $(pwd):/in -w /in \
chrishah/busco-docker:v3.1.0 \
run_BUSCO.py \
--in /assemblies/GCA_003956705.1_VIB_BreviYothersi_1.0_genomic.fna \
--out B_yothersi.B_yothersi.GCA_003956705.1_VIB_BreviYothersi_1.0 \
-l /BUSCOs \
--mode genome -c 4 -f -sp fly --long --augustus_parameters='--progress=true'

```

__To be continued ..__
