# Running GWAS on Imputed Data

!!! important
	Before you start, make sure you have the [post-QC SNP list and sample list](../admin/master_generation.md#expected-result) and have extracted your phenotype either from the [SQL database](./../pheno/understand_sql.md#using-the-sql-database) or from the [text files](../pheno/tradition.md#step-by-step-guide).


## Using BOLT-LMM

The [BOLT-LMM algorithm](https://alkesgroup.broadinstitute.org/BOLT-LMM/downloads/BOLT-LMM_v2.3.4_manual.pdf) computes statistics for testing association between phenotype and genotypes using a linear mixed model. By default, BOLT-LMM assumes a Bayesian mixture-of-normals prior for the random effect attributed to SNPs other than the one being tested. This model generalizes the standard infinitesimal mixed model used by previous mixed model association methods, providing an opportunity for increased power to detect associations while controlling false positives. Additionally, BOLT-LMM applies algorithmic advances to compute mixed model association statistics much faster than eigen decomposition-based methods, both when using the Bayesian mixture model and when specialized to standard mixed model association.

We encourage users to [check the official BOLT-LMM documentation](https://alkesgroup.broadinstitute.org/BOLT-LMM/downloads/BOLT-LMM_v2.3.4_manual.pdf) for a full list of available commands. If you do not have BOLT installed, you can [download the latest version here](http://data.broadinstitute.org/alkesgroup/BOLT-LMM/downloads/).

*Reference:* Loh P-R, Tucker G, Bulik-Sullivan BK, Vilhjálmsson BJ, Finucane HK, Salem RM, Chasman DI, Ridker PM, Neale BM, Berger B, Patterson N, and Price AL. *Efficient Bayesian mixed model analysis increases association power in large cohorts*. Nature Genetics, 2015.

!!! Important
	BOLT-LMM is recommended for analyses of human genetic data sets containing more than 5,000 samples. Also, association test statistics are valid for quantitative traitsand for (reasonably) balanced case-control traits. For unbalanced case-control traits, the [SAIGE](https://github.com/weizhouUMICH/SAIGE) or [REGENIE](https://github.com/rgcgithub/regenie) software packages may be more appropiate.  

### Example:

Running a GWAS using BOLT-LMM can be divided in two sections:

1. Using PLINK, select a group of model SNVs from the genotyped SNPs, required for the subsequent GWAS.
2. Run BOLT-LMM using the estimated heritability and the group of model SNPs.

#### 1. Select a group of model SNVs from the genotyped SNPs using PLINK.

	plink
		--bfile <path to genotype files> \
		--keep  <path to post-QC .fam file> \
		--extract <path to post-QC .snplist> \ 
		--make-bed \
		--out <model_genotypedSNPs>
	
#### 2. Run BOLT-LMM using the estimated heritability and the group of model SNPs.

	bolt	
		--bfile=model_genotypedSNPs \ 
		--bgenFile=ukbXXXXX_imp_chr${LSB_JOBINDEX}_v3.bgen \ 
		--LDscoresMatchBp \ 
		--sampleFile=ukbXXXX_imp_chr1_v3_s487283.sample \ 
		--lmmForceNonInf \ 
		--covarUseMissingIndic \ 
		--LDscoresFile=LDSCORE.1000G_EUR.tab.gz \ 
		--numThreads=${LSB_JOBINDEX} \ 
		--phenoFile=Phenofile> \ 
		--phenoCol=<Name> \ 
		--covarFile=<ukbXXXXX.covariates \ 
		--covarCol=<Colnames> \ 
		--covarMaxLevels 1000 \
		--verboseStats \ 
		--h2gGuess= \ 
		--statsFile=chr${LSB_JOBINDEX}_non_imputed_<job_name>.stats \ 
		--statsFileBgenSnps=${output}/chr${LSB_JOBINDEX}_imputed_<job_name>.stats \ 
		--numLeaveOutChunks 2 \
		--bgenMinMAF=0.01 \ 
		--bgenMinINFO=0.3 \
		2>&1 | tee ${output}/chr${LSB_JOBINDEX}_BOLT2_date.log

!!! Note
	In Minerva, ${LSB_JOBINDEX} specifies the index of the job when submitting a job array. For more information about the MSSM Minerva Scientific Computing Environment visit the [documentation.](https://labs.icahn.mssm.edu/minervalab/wp-content/uploads/sites/342/2019/11/2017-09-26_MInerva-User-Group-Meeting.pdf)
	
| Argument | Explanation |
|---|---|
| bolt | Path to bolt executable file | 
| --noBgenIDcheck |  Flag to speed up |
| --bfile | Filtered genotyped SNPs used to build the model in bolt |
| --bgenFile | Path to Bgen file per Chr |
| --LDscoresMatchBp | Flag to match the LD calculations to the base pairs | 
| --sampleFile | Application-specific sample file (format the application-specific fam file to match the sample file - as input for SNPtest) | 
| --lmmForceNonInf | Flag to run BOLT-LMM | 
| --covarUseMissingIndic | Flag to use covariates ignoring missing data |
| --LDscoresFile | LD file |
| --numThreads | Number of computational threads | 
| --phenoFile | Path to phenotype file. Header required; FID IID must be first two columns |
| --phenoCol | Phenotype column name | 
| --covarFile | Path to covariate file |
| --covarCol | Continuous (qCovarCol) and categorical (covarCol) covariates | 
| --verboseStats | Flag to Output statistics |
| --h2gGuess | Estimated heritability (with BOLT-REML) | 
| --statsFile | Path output file for assoc stats at PLINK genotypes (not imputed) |
| --statsFileBgenSnps | Path to stats output file (main results) |
| --bgenMinMAF | MAF threshold on Oxford BGEN-format genotypes; lower-MAF SNPs will be ignored | 
| --bgenMinINFO | INFO threshold on Oxford BGEN-format genotypes; lower-INFO SNPs will be ignored |
| 2>&1 tee /chr${LSB_JOBINDEX}_BOLT2_date.log | Path to log output file |

<br>

