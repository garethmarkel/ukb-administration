# Initialize UK Biobank directory
In this section, we will go through how to initialize the UK Biobank directory. 
After this section, you should have got the master UK Biobank directory setup.

## Before you start
Make sure you have the following

1. `nextflow`

    !!! note
        You can install nextflow with 

        `curl -s https://get.nextflow.io | bash`

        Java 8 or later is required
2. `git` to download the current repository
3. A md5 key file for one UK Biobank application
    - This is required so that we can download the genetic files.
4. Internet connection.

## Step by step guide

1. First, clone the current repository to where you want to put your UK Biobank directory

    ```bash
    git clone https://gitlab.com/choishingwan/ukb-administration.git
    ```
    This should generate the `ukb-administration` folder. 
    You can rename it with `mv ukb-administration <desired name>`
    
2. Move into the ukb folder
    ``` bash
        mv ukb-administration
    ```

    !!! tips
        `docs` contain code generating this website. If that isn't required, you can simply delete it

3. Run the following command
    ```bash
    nextflow run scripts/administration/init_structure.nf \
        --key <your key file> \
        --id <application id> \
        -c scripts/download.config
    ```

    !!! tips
        You can change the `download.config` file to cater to the settings of your server. For example, you can change the executor to `lsf`, `slum` etc. For more information, please visit [nextflow documentation](https://www.nextflow.io/docs/latest/executor.html)

4. Once the pipeline successfully complete, you can remove the intermediate folder `work`
    ```bash
    rm -rf work
    ```

## Final structure
After running the script, your directory should look like the following
```
<root>
  |
  |- .genotype
  |    |
  |    |-- genotyped # Folder contain whole genome bed and bim file
  |    |
  |    |-- imputed # Folder contain per chromosome bgen and bgi files
  |
  |- .exome
  |    |
  |    |-- PLINK # Folder contain plink format exome sequencing data
  |
  |- references # Folder contain UK Biobank related references
  | 
  |- software # Folder contain UK Biobank related software and some utility tools
  |    |
  |    |-- bin # Where the software executable locates
  | 
  |- scripts # Contain all scripts related to UK Biobank management
       |
       |-- administration
       |
       |-- QC
       |
       |-- examples
```

!!! Warning "Important"
    Once all data are downloaded, remove the `work` folder which contains all intermediate files. 
    Most importantly, the per-chromosome plink genotyped data are included. 
    If you want to keep a copy of the per-chromosome plink files, you can find the bed and bim file
    with `ls <root>/work/*/*/*{*bed,*bim}`
