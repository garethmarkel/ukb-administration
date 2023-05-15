/groups/GENOECON/ukb/software/plink2 --pmerge-list /groups/GENOECON/ukb/genetic_files/list_of_chromosome_files.txt --make-bed --out /groups/GENOECON/ukb/genetic_files/all_chrom
/groups/GENOECON/ukb/software/plink2 --pmerge-list /groups/GENOECON/ukb/genetic_files/temp/chrlist.txt --make-bed --out /groups/GENOECON/ukb/genetic_files/temp/all_chrom
cd /scratch/gmarkel/all_chrom/all_chrom/ && /groups/GENOECON/ukb/software/plink2 --bfile /scratch/gmarkel/all_chrom/all_chrom --make-bed --maj_ref --out /scratch/gmarkel/all_chrom/all_chrom2
