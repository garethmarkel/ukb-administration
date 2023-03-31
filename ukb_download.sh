sh download_software.sh $1
sh download_reference_files.sh

echo -e "cp $1 .ukbkey \n$(cat download_genetic_files.sh)" > download_genetic_files.sh

sbatch get_genetic_files.slurm
