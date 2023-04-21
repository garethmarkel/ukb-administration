/groups/GENOECON/ukb/software/plink2 --pmerge-list /groups/GENOECON/ukb/genetic_files/list_of_chromosome_files.txt --make-bed --out /groups/GENOECON/ukb/genetic_files/all_chrom
/groups/GENOECON/ukb/software/plink2 --pmerge-list /groups/GENOECON/ukb/genetic_files/temp/chrlist.txt --make-bed --out /groups/GENOECON/ukb/genetic_files/temp/all_chrom
/groups/GENOECON/ukb/software/plink2 --bfile /groups/GENOECON/ukb/gmarkel/vischer/all_chrom.bed --make-bed --maj_ref --out /groups/GENOECON/ukb/genetic_files/temp/all_chrom
