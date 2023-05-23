# USING UKB DATA AT GMU
## IMPORT PROCESS

### Genotype Data

Import scripts for the UKB data are contained at https://github.com/garethmarkel/ukb-administration. I have already run these, but I have it set up so you could in theory run `sh ukb_download.sh <path-to-your-basket-key>` after pulling and get all your genetic files. Please review before doing this since I put it together from the less-clean scripts I used to create this. This will also download a bunch of software (though not ALL important software--I'll put info on how to get that on hopper later in this guide). You need the `parallel` package to do this (see General Software).

### Phenotype Data
UKB phenotype data is downloaded in baskets. It's almost impossible to get everything you want in one basket, so this process is more complicated. First, you download your basket from the UKB showcase, *using the Hopper Desktop GUI*. This will put a file called something like `ukb12345.enc` in your download directory. You can then run the import_pheno.sh file with the argument `ukb12345` to import your basket. This file will do several things.
1. Decode the data, generate a tab seperated file, an HTML page of variable definitions, and an R file to process the raw tab file
2. Run a script that converts the giant tab file to a parquet file (which is much easier to work with)
3. Organizes all the resulting files into subfolders and cleans up after itself

Run this anytime you download a new basket of data.

## Working with UKB Data

### Loading Phenotype Data into R

Using data.table, parquet, and 10 cores, we can load 500k rows into R in just over 1 second.

```R
rm(list = ls())
library(arrow)
library(data.table)
setDTthreads(10) ### Hopper interactive RStudio gives you 12 max
schema <- open_dataset(sources = "/groups/GENOECON/ukb/phenotype_files/parquet_files/ukb12345.gz.parquet")$schema
names <- schema$names

ukb = setDT(read_parquet("/groups/GENOECON/ukb/phenotype_files/parquet_files/ukb12345.gz.parquet",
                         col_select = c("f.eid", "f.6138.0.0","f.50.0.0","f.21001.0.0","f.738.0.0", "f.31.0.0", "f.34.0.0","f.845.0.0")))

colnames(ukb) <- c("eid", "EA_cat", "hei","bmi", "fam_inc_cat", "sex", "byear", "age_fte")

```

### Running Plink
To run PLINK, you need to:
1. copy all the bed/bim/fam files from `ukb/genetic_files` to your `/scratch/$user` directory, which has unlimited space
2. rename them to something else (maybe just `chrom#.bed/bim/fam`)
3. Create a mapping text file, seperated by tabs, with the name of each chromosome's bed/bim/fam file on each line
4. Combine them into one file using plink. This can and should be run from your R script with `system("/groups/GENOECON/ukb/software/plink2 <flags>")`, for reproduceability

After step 4, run any analysis you normally would (subset individuals, SNPs, etc) making sure to put any genetic files you create into `/scratch/$USER`, which has unlimited space.


## SOFTWARE

### User Installed Packages

There are two steps to user installed packages. The first is to install the package to your user directory.

```Bash
wget <tarball-url>
tar xvfz <package-tarball>
cd <the-new-tarball-directory>
mkdir -p /home/$USER/packages/<package>
./configure prefix=/home/$USER/packages/<package>
make
make install
```

The second is to make it visible to Hopper's `module` software, basically by registering it.

```Bash
mkdir -p ~/privatemodules
nano <package-name>
#insert the required details--see the file priv_parallel on the UKB admin github
module load use-own
module load <package-name>
```

Some packages may not need all this (e.g. plink2), and just have an executable you can drop somewhere. Some do need this, and it's kind of trial and error.

### Parallel

Parallel needs to be installed as a user installed package. The tarball is located at http://ftp.gnu.org/gnu/parallel/parallel-latest.tar.bz2.

### Parquet
We're using Parquet to store UKB data. The big advantage of this format is that we can query specific columns without pulling the whole row (this isn't unique to parquet, but it's imo the easiest to work with and has the workflow most similar to just usign a CSV). To use parquet, you need the `arrow` package in R. This takes trial and error (I had to do different things for different versions of R on Hopper). Here's what's most likely to work, from either command line `R` or the Rstudio console.
```R
Sys.setenv(ARROW_S3="ON")
Sys.setenv(NOT_CRAN="true")
install.packages("arrow", repos = "https://arrow-r-nightly.s3.amazonaws.com")
```

### SINGULARITY
Singluarity containers are like "clean rooms" for software. You can specify a list of dependency versions and install software without having to untangle a bunch of different configurations on your real computer. A more famous kind is Docker, which we can't run on the cluster because of something to do with the way docker uses root privileges. Luckily, it's easy to pull docker containers to singularity. Here is the command pattern for that (see the SAIGE section for an example).

```Bash
cd /containers/dgx/UserContainers
mkdir -p $USER
cd /containers/dgx/UserContainers/$USER
module load singularity
singularity build <NAME>.sif docker://<CONTAINER>:<VERSION>
```

To run these in a batch script, you also need a little bit of a different pattern in your slurm file.

```
SINGULARITY_BASE=/containers/dgx/UserContainers/$USER
CONTAINER=${SINGULARITY_BASE}/<path_to_sif_file>
SINGULARITY_RUN="singularity run --nv -B ${PWD}:/host_pwd --pwd /host_pwd"

SCRIPT=<script name>
${SINGULARITY_RUN} ${CONTAINER} ${SCRIPT} | tee ${SCRIPT}.log
```

The GMU help link is here: https://wiki.orc.gmu.edu/mkdocs/Containerized_jobs_on_Hopper/. It claims you need GPU access to run these but I really don't think that's true, their example is just tensorflow.

### SAIGE
Not great documentation on how to build this--after a lot of trial and error, the best way seems to be to just pull the docker image and convert it to a singularity image. I wanted to follow the same convention and drop it in the `software` dir so this is suboptimal, but here are the commands for that.

```Bash
cd /containers/dgx/UserContainers
mkdir -p $USER
cd /containers/dgx/UserContainers/$USER
module load singularity
singularity build SAIGE.sif docker://wzhou88/saige:1.1.9
```


### PLINK
Downloaded as part of the github import script. Located in `ukb/software/plink2`.

### KING
Downloaded as part of the github import script. Located in `ukb/software/king`.

### MERLIN
Currently having some trouble building it, so we don't have it. The error I'm running into has to do with differences in C++; for later reference, the search term for the error is "wnarrowing error c++".

### GCTA

```Bash
wget https://yanglab.westlake.edu.cn/software/gcta/bin/gcta-1.94.1-linux-kernel-3-x86_64.zip
unzip gcta-1.94.1-linux-kernel-3-x86_64.zip
mv gcta-1.94.1-linux-kernel-3-x86_64 gcta_dir
rm gcta-1.94.1-linux-kernel-3-x86_64.zip
```

## Tips and Tricks

### Public Githubs
There's not a lot of great documentation on how to use the UK Biobank with most genetic tools (at least, relative to the million stackoverflows you can consult for anything else). One thing you can do, though, is plug tool specific search terms into the Github search bar in double quotes, and it'll search for exact matches. For example, if you wanted an example of code calculating the GRM for the full UKB sample, you could search "make-grm" "uk" "biobank" and it would find code files containing all 3 of those exact terms (the first is a flag used in GCTA).

### Job Arrays

Sometimes (for example when computing the GRM for the UKB) it's convenient to submit an array of jobs. This will create a bunch of jobs with ids like `1234567_1` where the number after the underscore is the array id, and the number before is like the job id. To check the status of the array, you can run this command with the long number.

```Bash
sacct -n -X -j 885881 -o state%20 | sort | uniq -c
```

### phaseIBD

```Bash
git clone https://github.com/23andMe/phasedibd.git

make
python setup.py install --user
#pip install pandas==1.5.3
python tests/unit_tests.py
```

### Bash

Note, `sh <command>` runs differently on the RStudio server terminal than your ssh terminal. This is because it points to dash in the singularity container Rstudio runs in. On your normal ssh terminal, it points to bash, and some commands will run differently. A good debugging step (if you're running stuff from the RStudio terminal) is to try running `bash <script>` instead of `sh <script>`.
