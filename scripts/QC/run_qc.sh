#BSUB -L /bin/sh
#BSUB -n 1
#BSUB -J UKB
#BSUB -R "span[hosts=1]"
#BSUB -q premium               # target queue for job execution
#BSUB -W 24:00                # wall clock limit for job
#BSUB -P acc_psychgen             # project to charge time
#BSUB -o ukb.o
#BSUB -eo ukb.e
#BSUB -M 30000
id=18177
root=/sc/arion/projects/data-ark/ukb/
application=${root}/application/ukb${id}
withdrawn=${application}/withdrawn/w18177_20181016.csv
related=${application}/genotyped/ukb18177_rel_s488250.dat
module load java
nextflow run \
    ${root}/scripts/QC/prepare_ukb.nf \
    --bfile ${application}/genotyped/ukb${id} \
    --code ${root}/references/Codings.csv \
    --conv ${root}/software/bin/ukbconv \
    --data ${root}/references/Data_Dictionary_Showcase.csv \
    --drug ${application}/phenotype/raw/gp_scripts.txt \
    --encoding ${root}/references/encoding.ukb \
    --encrypt ${application}/phenotype/raw/encrypted/ \
    --gp ${application}/phenotype/raw/gp_clinical.txt \
    --greed ${root}/software/bin/GreedyRelated \
    --key ${application}/phenotype/raw/keys/ \
    --unpack ${root}/software/bin/ukbunpack \
    --sql ${root}/software/bin/ukb_sql \
    --drop ${withdrawn} \
    --rel ${related} \
    --out ukb${id} \
    -resume
