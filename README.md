# AMEB2020_Phylogenomics_demo

We will be reconstructing the phylogenetic relationships of some oribatid mites based on previously published whole genome / transcriptome data. The list of species we will be including in the analyses, a reference to the original publication and the URL for the data download can be found in this <a href="https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/data/samples.csv" title="Sample table" target="_blank">table</a>.

All software used in the demo is deposited in Docker containers (see <a href="https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/data/software.csv" title="software table" target="_blank">here</a>) and all data is freely and publicly available.

To follow the demo and make the most of it, it helps if you have some basic skills with running software tools and manipulating files using the Unix shell command line.

The workflow we will demonstrate is as follows:
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

##__Let's get started!!__

__1.) Download data from Genbank__







