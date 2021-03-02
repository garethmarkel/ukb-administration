# Available pre-QC'ed data  

This section provides information about the quality control (QC) of genetic data that is available to MINERVA users. We encourage users to use the ready-to use pre-QC'ed data, as this would increase reproducibility across studies. 

For more details on how the quality control was performed, visit the ['For administrators section'](./../admin/master_generation.md). 

The Quality Control criteria used and number of SNPs/samples removed were as follows:

1. Exclude samples with excessively high relatedness, missingness and heterozygosity rate as per UK Biobank central quality control.
2. Exclude samples that withdrawn their consent.
3. European ancestry ascertainment: Ascertain Europeans using 4-mean clustering on the first 2 principal components provided by UK Biobank. 
4. Exclude SNPs with high missing call rate (geno=0.02).
5. Exclude SNPs failing the Hardy-Weinberg exact test (hwe=1E-8).
6. Exclude SNPs with low minor allele frequency (maf=0.01).
7. Exclude samples with mismatch sex information (3 sd from mean) after performing prunning with:
	- windSize=200
	- windStep=50
	- r2=0.2
	- maxSize=10000
8. Exclude related samples (Kinship > 0.044) using ['greedy relatedness'](https://gitlab.com/choishingwan/GreedyRelated) package (kinship=0.044)

!!! Note

	Our pipeline will automatically generate a QC summary with the number of samples and SNPs filtered per step