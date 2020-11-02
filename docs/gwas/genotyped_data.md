# Running GWAS on Genotyped data
In this section we will go over how to run a basic GWAS on UK Biobank.

!!! important
    Before you start, make sure you have the [post-QC SNP list and sample list](../admin/master_generation.md#expected-result) and have extracted your phenotype either from the [SQL database](../pheno/understand_sql.md#using-the-sql-database) or from the [text files](../pheno/tradition.md#step-by-step-guide). 

When using the UK Biobank data, the genotyping batch (Field ID: [22000](https://biobank.ctsu.ox.ac.uk/showcase/field.cgi?id=22000)) is usually included as one of the covariate. In addition, we recommend including at least 15 PCs to adjust for population stratification. 

You can run a GWAS on the genotyped UK Biobank data using PLINK 1.9 as follow

=== "Binary Trait"
```bash hl_lines="4"
plink   --bfile <genotype file prefix> \
        --keep <post-QC sample list> \
        --extract <post-QC SNP list> \
        --logistic hide-covar \
        --pheno <Phenotype file> \
        --pheno-name <name of phenotype> \
        --covar <covariate file> \
        --covar-name  <name of covariates> \
        --out <output name>
```
=== "Continuous Trait"

```bash hl_lines="4" 
plink   --bfile <genotype file prefix> \
        --keep <post-QC sample list> \
        --extract <post-QC SNP list> \
        --linear hide-covar \
        --pheno <Phenotype file> \
        --pheno-name <name of phenotype> \
        --covar <covariate file> \
        --covar-name  <name of covariates> \
        --out <output name>
```


!!! Note:
    You can igore `--covar-name` if your covariate file only contain covariates you want to included in the analysis.
    Similarly, if your phenotype file only contain the phenotype of interest, you can ignore `--pheno-name`