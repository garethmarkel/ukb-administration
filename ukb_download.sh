#this file can be run with the first argument ($1) as the path to the keyfile and $2 as the UKB dataset name (e.g. ukb672242 for ukb672242.enc)
sh download_software.sh $1
sh download_reference_files.sh

echo -e "cp $1 .ukbkey \n$(cat download_genetic_files.sh)" > download_genetic_files.sh

#if you don't have gnu parallel installed, install it into a directory in your home directory
#then uncomment the following line to make it visible to the Hopper cluster
#cp priv_parallel /home/$USER/privatemodules/parallel

sbatch get_genetic_files.slurm

##download UKB data--has to be manually, which is a pain
mkdir phenotype_files
cd /groups/GENOECON/ukb
cp ./genetic_files/.ukbkey ./phenotype_files/.ukbkey
