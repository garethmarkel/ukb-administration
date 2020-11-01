# Generate SQL and "Pick up and go" data
In this section, we will go through how to construct the phenotype SQL database and the "pick up and go" data where a standard set of quality controls (QC) were performed. 


## All in one pipeline
We have implemented an all in one pipeline that will perform the standard QC and generate the UK Biobank phenotype database. 
You can find the script under `<ukb root>/scripts/QC/prepare_ukb.nf`

!!! note
    Our pipeline is arranged in modules. You can find scripts of the individual modules under `<ukb root>/scripts/QC/module`

### Before you start
You need to ensure that you have `nextflow` installed. You will also need the following files

| File Name | Description| Location | How to obtain | 
| :--: | :-- | :--| :--|
|  | Sample dropout file | preferred `<application folder>/withdrawn` | Attachment of UK Biobank notification email|
|  | Decryption key | preferred `<application folder>/phenotype/keys/` | Attachment of UK Biobank notification email|
|  | Encrypted phenotype files | preferred `<application folder>/phenotype/encrypted/` | See [previous section](init_application.md#downloading-phentype-files)|
| `ukb<id>.{bed,bim,fam}` | UK Biobank genotype file| `<application folder>/genotyped/`| Manually download using `ukbgene`. See [here](https://biobank.ctsu.ox.ac.uk/crystal/crystal/docs/ukbgene_instruct.html) for more information|
| `encode.ukb` | UK Biobank encoding file. Required for phenotype extraction | `<root>/reference` | Download [here](https://biobank.ctsu.ox.ac.uk/crystal/util/encoding.ukb)|
| `Data_Dictionary_Showcase.csv`| File contain details about phenotype in the UK Biobank | `<root>/reference` | Download [here](https://biobank.ctsu.ox.ac.uk/~bbdatan/Data_Dictionary_Showcase.csv)]|
| `Codings.csv`| File contain details about phenotype coding in the UK Biobank | `<root>/reference` | Download [here](https://biobank.ctsu.ox.ac.uk/~bbdatan/Codings.csv)|
| `ukb<application ID>_rel_*.dat`| Sample Relatedness file | `<application folder>/genotyped` |  Download with `ukbgene rel -a<key file>`|
| `ukbunpack` | Executable provided by UK Biobank for data decryption| `<root>software/bin` | Download [here](https://biobank.ctsu.ox.ac.uk/showcase/util/ukbunpack)|
| `ukbconv` | Executable provided by UK Biobank for data conversion| `<root>software/bin` | Download [here](https://biobank.ctsu.ox.ac.uk/showcase/util/ukbconv)|
| `GreedyRelated` | Software for greedily selecting related samples| `<root>software/bin` | Download and compile from [here](https://gitlab.com/choishingwan/GreedyRelated)|
| `ukb_sql` | Software generating the UK Biobank SQL database | `<root>software/bin` | Download and compile from [here](https://gitlab.com/choishingwan/ukb_process)|

!!! Important
    The encrypted files and key files should be stored in a separted folder. Each key and encrypted file pair should have the same file prefix

### Run the pipeline
Assuming you have constructed the UK Biobank folder as instructed. 
You can run the pipeline **in your application folder** as follow
```
id=<application ID>
root=<path to ukb root>
application=${root}/application/ukb${id}
nextflow run \
    ${root}/scripts/QC/prepare_ukb.nf \
    --bfile ${application}/genotyped/ukb \
    --code ${root}/references/Codings.csv \
    --conv ${root}/software/bin/ukbconv \
    --data ${root}/references/Data_Dictionary_Showcase.csv \
    --drug ${application}/phenotype/raw/gp_scripts.txt \
    --encoding ${root}/references/encoding.ukb \
    --encrypt ${application}/phenotype/raw/encrypted/ \
    --gp ${application}/phenotype/raw/gp_clinical.txt \
    --greed ${root}/software/bin/GreedyRelated \
    --key ${application}/phenotype/raw/keys/ \
    --unpack ${root}/software/bin/ukbunpack 
    --sql ${root}/software/bin/ukb_sq \
    --drop ${application}/withdrawn/<name to withdrawn file> \
    --rel ${application}/genotyped/<relatedness file> \
    --out ukb${id}
```

!!! note
    Change all field with <> to the correct files.
    If you have manually organized / downloaded your files, please replace the fields accordingly. 

After the script complete, your application folder should have the following files and structures

```
ukb<ID>
  |
  |-- genotyped 
  |    |
  |    |-- ukb<ID>.bed
  |    |
  |    |-- ukb<ID>.bim
  |    |
  |    |-- ukb<ID>.bed
  |    |
  |    |-- ukb<ID>-qc.snplist # File containing SNPs that passed filtering
  |    |
  |    |-- ukb<ID>-qc.fam # File containing EUR Samples that passed filtering
  |    |
  |    |-- ukb<ID>-qc.parents # Parents of samples in ukb<ID>-qc.fam that also passed filtering (except relatedness)
  |    |
  |    |-- ukb<ID>-qc.sibs # Siblings of samples in ukb<ID>-qc.fam that also passed filtering (except relatedness)
  |    |
  |    |-- ukb<ID>-4mean-EUR # European samples determined via 4 mean clustering
  |
  |-- plots
  |    |
  |    |-- ukb<ID>-kinship.png # Kinship plot
  |    |
  |    |-- ukb<ID>-pca.png # PCA population plot with 4 mean clustering colors
  |
  |-- imputed
  |
  |-- exome
  |    |   
  |    |-- PLINK
  |
  |-- phenotype
  |    |
  |    |-- raw
  |    |    |
  |    |    |-- encrypted
  |    |    |
  |    |    |-- keys
  |    |    |
  |    |    |-- *.tab # Plain text phenotype files
  |    |    |
  |    |    |-- *.field_finders # helper file indicating phenotype column number in the plain text files
  |    |
  |    |-- withdrawn
  |    |
  |    |-- ukb<ID>_rel_s488251.dat # This is the relatedness file
  |    |
  |    |-- ukb<ID>.sex # Samples with mismatch sex information
  |    |
  |    |-- ukb<ID>.invalid # Samples with high missingness, excessive relatedness or high heterozygousity
  |    |
  |    |-- ukb<ID>.covar # File contains UK Biobank genotyping batch and 40 PCs. Useful for downstream analyses
  |    |
  |    |-- ukb<ID>.db # Phenotype database
  |
  |-- ukb<ID>_init.log
```

### Pipeline breakdown
We will briefly go through the steps performed in the pipeline. 

!!!note
    You can customize some of the filtering threshold in the pipeline by providing different parameters. For more information, please read the help message from the pipeline `nextflow run prepare_ukb.nf --help`

#### Quality Control
1. Filter SNPs with high missing call rates (default: 0.02)
2. Perform 4 mean clustering on the first 2 principal components (PC) to extract samples with European ancestry
3. Filter out samples with excessively high relatedness, missingness, heterozygosity rate as indicated by UK Biobank, and samples who withdrawn their consent.
4. Filter SNPs with low MAF (default: 0.01), significant deviate from Hardy Weinberg Equailibrium (default: 1e-8) and with high missing call rates (default 0.02)
5. Perform prunning. High LD regions are excluded. 
6. Perform sex mismatch check. Samples with F-statistics 3 SD away from their gender's mean are removed by default.
7. Use `GreedyRelated` to remove related samples. 

#### Phenotype Database generation
1. Automatically decrypt the encrypted data
2. Convert the decrypted data to R format
3. Generate SQL using `ukb_sql`

## Manually Building the SQL 
Here are the breakdown of how to generate the SQL database manually

1. Decrypt the encrypted data using `ukbunpack`
    ```
    ukbunpack <encrypted file> <key>
    ```
2. Convert the decrypted data to R format using `ukbconv` and `encode.ukb`
    ```
    ukbconv <decrypted file> r -eencode.ukb
    ```

    !!! note
        No space between the parameter and input

3. Run `ukb_sql`
    ```
     ukb_sql \
        -d Data_Dictionary_Showcase.csv \
        -c Codings.csv \
        -p <comma delimited list of phenotype files> \
        --out <id>.db \
        -g <Clinical event records > \
        -u <Prescription records> \
        -D \
        -w <withdrawn samples>
    ```

    !!! note
        Clinical event records and Prescription records are optional
