

mkdir /groups/GENOECON/ukb/genetic_files
cd /groups/GENOECON/ukb/genetic_files

echo "*****************************************************"
echo "********GENOTYPE CALLS (.bed)*********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22418 -c{} -a.ukbkey'


wget -nd  biobank.ctsu.ox.ac.uk/ukb/ukb/auxdata/ukb_snp_bim.tar
tar -xvf ukb_snp_bim.tar

echo "*****************************************************"
echo "********GENOTYPE CALLS (.fam)*********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22418 -c{} -m -a.ukbkey'

wget  -nd  biobank.ctsu.ox.ac.uk/ukb/ukb/auxdata/ukb_snp_qc.txt

/groups/GENOECON/ukb/software/gfetch rel

echo "*****************************************************"
echo "********GENOTYPE IMPUTATION (.bgen)*********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22828 -c{} -a.ukbkey'

wget  -nd  biobank.ctsu.ox.ac.uk/ukb/ukb/auxdata/ukb_imp_bgi.tgz
tar -zxvf ukb_imp_bgi.tgz

wget  -nd  biobank.ctsu.ox.ac.uk/ukb/ukb/auxdata/ukb_imp_mfi.tgz
tar -zxvf ukb_imp_mfi.tgz

echo "*****************************************************"
echo "******** IMPUTATION SAMPLE                  *********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22828 -c{} -m -a.ukbkey'


echo "*****************************************************"
echo "******** HAPLOTYPES BGEN                    *********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22438 -c{} -a.ukbkey'

wget  -nd  biobank.ctsu.ox.ac.uk/ukb/ukb/auxdata/ukb_hap_bgi.tgz
tar -zxvf ukb_hap_bgi.tgz

echo "*****************************************************"
echo "******** INTENSITIES                    *********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22430 -c{} -a.ukbkey'

echo "*****************************************************"
echo "******** CONFIDENCES                    *********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22419 -c{} -a.ukbkey'

echo "*****************************************************"
echo "******** CNV LOG2                    *********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22431 -c{} -a.ukbkey'

echo "*****************************************************"
echo "******** CNV BALLELLE                    *********"
echo "*****************************************************"

for i in {1..22} "X" "Y" "XY" "MT"; do echo $i; done | parallel '/groups/GENOECON/ukb/software/gfetch 22437 -c{} -a.ukbkey'

wget  -nd  biobank.ctsu.ox.ac.uk/ukb/ukb/auxdata/ukb_snp_posterior.tar
tar -xvf ukb_snp_posterior.tar

wget  -nd  biobank.ctsu.ox.ac.uk/ukb/ukb/auxdata/ukb_snp_posterior.batch

cd ..
