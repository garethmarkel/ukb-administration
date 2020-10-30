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
    --rel ${application}/genotyped/<relatedness file> 
```

!!! note
    Change all field with <> to the correct files.
    If you have manually organized / downloaded your files, please replace the fields accordingly. 

After the script complete, you will obtain the following:
```

```