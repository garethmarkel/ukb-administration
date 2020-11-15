# Available pre-QC'ed data  

This section provides information about the quality control (QC) of genetic data that is available to MINERVA users. We encourage users to use the ready-to use pre-QC'ed data, as this would increase reproducibility across studies. 

For more details on how the quality control was performed, visit the ['For administrators section'](./../admin/master_generation.md). 

The Quality Control criteria used and number of SNPs/samples removed were as follows:

1. Exclusion of 1806 samples with excessively high relatedness, missingness and heterozygosity rate as per UK Biobank central quality control.
2. Exclusion of 136 samples that withdrawn their consent.
3. European ancestry ascertainment: 461,944 individuals were ascertained as Europeans using 4-mean clustering on the first 2 principal components provided by UK Biobank. 
4. Exclusion of 104718 SNPs due to high missing call rate (geno=0.02).
5. Exclusion of 43011 SNPs due to Hardy-Weinberg exact test (hwe=1E-8).
6. Exclusion of 100334 SNPs due to minor allele threshold (maf=0.01).
7. Exclusion of 0 samples with mismatch sex information (3 sd from mean) after performing prunning with:
	- windSize=200
	- windStep=50
	- r2=0.2
	- maxSize=10000
8. Exclusion of 72851 samples due to relatedness (Kinship > 0.044) using ['greedy relatedness'](https://gitlab.com/choishingwan/GreedyRelated) package (kinship=0.044)
	- 5180 parent(s) extracted
	- 18295 sibling(s) extracted


After QC:

- **387,414 sample(s)** remaining

- **557,363 snp(s)** remaining
