# AMEB2020_Phylogenomics_demo

We will be reconstructing the phylogenetic relationships of some oribatid mites based on previously published whole genome / transcriptome data. The list of species we will be including in the analyses, a reference to the original publication and the URL for the data download can be found in this <a href="https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/data/samples.csv" title="Sample table" target="_blank">table</a>.

All software used in the demo is deposited in Docker containers (see <a href="https://github.com/chrishah/AMEB2020_Phylogenomics_demo/blob/master/data/software.csv" title="software table" target="_blank">here</a>) and all data is freely and publicly available.

To follow the demo and make the most of it, it helps if you have some basic skills with running software tools and manipulating files using the Unix shell command line.

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
```
mkdir assemblies
cd assemblies
wget https://sra-download.ncbi.nlm.nih.gov/traces/wgs03/wgs_aux/GE/XX/GEXX01/GEXX01.1.fsa_nt.gz
..
..
..
cd .. 
```

