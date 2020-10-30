# Generate SQL and "Pick up and go" data
In this section, we will go through how to construct the phenotype SQL database and the "pick up and go" data where a standard set of quality controls (QC) were performed. 


## All in one pipeline
We have implemented an all in one pipeline that will perform the standard QC and generate the UK Biobank phenotype database. 
You can find the script under `<ukb root>/scripts/QC/prepare_ukb.nf`

!!! note
    Our pipeline is arranged in modules. You can find scripts of the individual modules under `<ukb root>/scripts/QC/module`

### Before you start
You need to ensure that you have `nextflow` installed. You will also need the following files

 <table class="others">
  <tr>
    <th>File Name</th>
    <th>Location</th>
    <th>How to obtain</th>
  </tr>
  <tr>
    <td>Genotype file</td>
    <td>Within genotyped folder of the application folder</td>
    <td>`ukbgene`</td>
  </tr>
  <tr>
    <td>Eve</td>
    <td>Jackson</td>
    <td>94</td>
  </tr>
</table> 

4. Sample dropout sample (download from notification email)

You will also need the following files, which should have automatically downloaded if you setup the UK Biobank root and application folder with our scripts

1. UK Biobank genotype file (Whole genome)
2. `encode.ukb`: UK Biobank encoding file, can be found in `<root>/reference` or you can download it [here](https://biobank.ctsu.ox.ac.uk/crystal/util/encoding.ukb)
3. `Data_Dictionary_Showcase.csv`: Data showcase file, can be found in `<root>/reference` or you can download it [here](https://biobank.ctsu.ox.ac.uk/~bbdatan/Data_Dictionary_Showcase.csv)
4. `Codings.csv`: Coding information file, can be found in `<root>/reference` or you can download it [here](https://biobank.ctsu.ox.ac.uk/~bbdatan/Codings.csv)
5. `ukb<application ID>_rel_s488282.dat`: file contains relatedness information. Or you can download using 
    ```
    ukbgene rel -a<key file>
    ```
6. `ukbunpack`: executable provided by uk biobank. Can be found in `<root>/software/bin` or you can download it [here](https://biobank.ctsu.ox.ac.uk/showcase/util/ukbunpack)
7. `ukbconv`: executable provided by uk biobank. Can be found in `<root>/software/bin` or you can download it [here](https://biobank.ctsu.ox.ac.uk/showcase/util/ukbcov)
8. `GreedyRelated`: software for greedily select related samples. Can be found in `<root>/software/bin` or you can download and compile it from [here](https://gitlab.com/choishingwan/GreedyRelated)
9. `ukb_sql`: software for generating the UK Biobank SQL database. Can be found in `<root>/software/bin` or you can download and compile it from [here](https://gitlab.com/choishingwan/ukb_process)

### Run the pipeline

nextflow run /sc/arion/projects/data-ark/ukb/scripts/QC/prepare_ukb.nf --bfile ../applications/kcl/ukb18177 --code /sc/arion/projects/data-ark/ukb/references/Codings.csv --conv /sc/arion/projects/data-ark/ukb/software/bin/ukbconv --data /sc/arion/projects/data-ark/ukb/references/Data_Dictionary_Showcase.csv --drop ../applications/kcl/dropout/w18177_20200204.csv --drug ../applications/kcl/gp_scripts.txt --encoding /sc/arion/projects/data-ark/ukb/references/encoding.ukb --encrypt encrypted/ --gp ../applications/kcl/gp_clinical.txt --greed /sc/arion/projects/data-ark/ukb/software/bin/GreedyRelated --rel ../applications/kcl/ukb18177_rel_s488282.dat --key key/ --unpack /sc/arion/projects/data-ark/ukb/software/bin/ukbunpack --sql ukb_process/bin/ukb_sq
