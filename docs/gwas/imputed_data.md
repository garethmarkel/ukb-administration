# Running GWAS on Imputed Data

## Using BOLT-REML and BOLT-LMM

### Overview:

Running a GWAS using BOLT-LMM can be divided in three sections:

1. Using PLINK, select a group of model SNVs from the genotyped SNPs, required for the subsequent GWAS.
2. Estimate the heritability of your trait using BOLT-REML and the group of model SNPs.
3. Run BOLT-LMM using the estimated heritability and the group of model SNPs.

#### 1. Using PLINK, select a group of model SNVs from the genotyped SNPs, required for the subsequent GWAS

	plink
		--bfile <path to genotype files> \
		--keep  <path to post-QC .fam file> \
		--extract <path to post-QC .snplist> \ 
		--make-bed \
		--out <model_genotypedSNPs>

#### 2. Estimate the heritability of your trait using BOLT-REML and the group of model SNPs

	bolt
		--noBgenIDcheck \
		--bfile=model_genotypedSNPs \
		--bgenFile=ukbXXXXX_imp_chr${LSB_JOBINDEX}_v3.bgen \
		--LDscoresMatchBp \
		--sampleFile=ukbXXXX_imp_chr1_v3_s487283.sample \
		--reml \
		--covarUseMissingIndic \
		--LDscoresFile=LDSCORE.1000G_EUR.tab.gz \
		--numThreads=1 \
		--phenoFile=Phenofile> \
		--phenoCol=<Name> \
		--covarFile=<ukbXXXXX.covariates \
		--covarCol=<Colnames> \
		--verboseStats \
		--h2gGuess= \
		--statsFile=chr${LSB_JOBINDEX}_non_imputed_<job_name>.stats \
		--statsFileBgenSnps=${output}/chr${1}_imputed_<job_name>.stats \
		--bgenMinMAF=0.01 \
		--bgenMinINFO=0.3 \
		2>&1 | tee ${output}/chr${1}_BOLT2_date.log # log output written to stdout and stderr

###### Line-by-line explanation: 
*(Credit: Dr Julia Ramirez - QMUL)*

bolt: Path to bolt executable file

--noBgenIDcheck: Flag to speed up

--bfile: Filtered genotyped SNPs used to build the model in Bolt

--bgenFile: Path to Bgen file per Chr

--LDscoresMatchBp: Flag to match the LD calculations to the BP

--sampleFile: Application-specific sample file (format the application-specific fam file to match the sample file - as input for SNPtest)

--reml: Flag to run BOLT-REML

--covarUseMissingIndic: Flag to use covariates ignoring missing data

--LDscoresFile: LD file 

--numThreads: Num of threads

--phenoFile: Path to phenotype file 

--phenoCol: Phenotype column name

--covarFile: Path to covariate file 

--covarCol: Continuous (qCovarCol) and categorical (covarCol) covariates 

--verboseStats: Flag to Output statistics 

--h2gGuess: Estimated heritability (with BOLT-REML)

--statsFile: Path to stats output file (not imputed)

--statsFileBgenSnps: Path to stats output file (main results)

--bgenMinMAF: Filter MAF

--bgenMinINFO: Filter INFO

2>&1 | tee <Path>: Path to log output file

#### 3. Run BOLT-LMM using the estimated heritability and the group of model SNPs.
