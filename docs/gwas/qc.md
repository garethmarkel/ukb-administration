# Quality Control of Genetic data

This section provides information about the quality control of genetic data that is available to MINERVA users. We encourage users to use the ready-to use QCed files, as this would increase reproducibility across studies. 

For more details on how the quality control was performed, visit the ['For administrators section'](./../admin/master_generation.md). 

### QC criteria used:
- Filter out SNPs with high missing call rate (geno=0.02)
- Filter out samples using UK Biobank qc file
- Filter out samples for excessively high relatedness, missingness and heterozygosity rate as per UK Biobank central quality control
- European ancestry ascertainment: We performed 4 mean clustering on the first 2 PC
- Prunning: This step is done because sex check and heterozygosity are affected by LD.

	- windSize=200
	- windStep=50
	- r2=0.2
	- maxSize=10000


- Relatedness filtering using ['greedy relatedness'](https://gitlab.com/choishingwan/GreedyRelated) package (kinship=0.044)
- Filter out SNPs with low MAF, significant deviate from Hardy Weinberg Equailibrium and with high missing call rates
	- hwe=1e-8
	- maf=0.01

