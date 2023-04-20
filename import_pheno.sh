cd /groups/GENOECON/ukb/phenotype_files
mv ~/Downloads/$1.enc /groups/GENOECON/ukb/phenotype_files/$1.enc
/groups/GENOECON/ukb/software/ukbmd5 $1.enc
#compare that to your MD5--probably could put some tooling in here to do so automatically

/groups/GENOECON/ukb/software/ukbunpack $1.enc .ukbkey

#get the encoding file
wget  -nd  biobank.ndph.ox.ac.uk/ukb/ukb/utilx/encoding.dat

#unpack the dataset--i think this could be dropped in parqeut maybe? we'll see.
#also, the .tab file this produces might not be optimal
nohup /groups/GENOECON/ukb/software/ukbconv $1.enc_ukb r -eencoding.dat &
nohup /groups/GENOECON/ukb/software/ukbconv $1.enc_ukb docs &


declare -a arr=(
        '    '
        'library(arrow)'
        "write_parquet(bd, '$1.gz.parquet', compression = 'gzip', compression_level = 5)"
);

printf '%s\n' "${arr[@]}" >> $1.r

cp convert_to_parquet.slurm convert_to_parquet_$1.slurm

echo "Rscript $1.r" >> convert_to_parquet_$1.slurm

sbatch convert_to_parquet_$1.slurm


mkdir -p html_files
mkdir -p parquet_files
mkdir -p enc_files
mkdir -p log_files
mkdir -p r_files
mkdir -p slurm_files

mv $1.html ./html_files/$1.html

mv $1.parquet ./parquet_files/$1.enc_ukb

mv $1.enc ./enc_files/$1.enc
mv $1.enc_ukb ./enc_files/$1.enc_ukb

mv $1.log ./log_files/$1.log

mv $1.r ./r_files/$1.r
mv $1.tab ./r_files/$1.tab

mv convert_to_parquet_$1.slurm ./slurm_files/convert_to_parquet_$1.slurm
