mkdir software
cd software

cp $1 .ukbkey

curl -o ukbmd5 https://biobank.ctsu.ox.ac.uk/crystal/util/ukbmd5
chmod 755 ukbmd5
curl -o ukbconv https://biobank.ctsu.ox.ac.uk/crystal/util/ukbconv
chmod 755 ukbconv
curl -o ukbunpack https://biobank.ctsu.ox.ac.uk/crystal/util/ukbunpack
chmod 755 ukbunpack
curl -o ukbfetch https://biobank.ctsu.ox.ac.uk/crystal/util/ukbfetch
chmod 755 ukbfetch
curl -o ukblink https://biobank.ctsu.ox.ac.uk/crystal/util/ukblink
chmod 755 ukblink
curl -o gfetch https://biobank.ctsu.ox.ac.uk/crystal/util/gfetch
chmod 755 gfetch

wget https://s3.amazonaws.com/plink2-assets/plink2_linux_amd_avx2_20230417.zip
chmod 755 plink2

wget https://www.kingrelatedness.com/Linux-king.tar.gz
tar -xzvf Linux-king.tar.gz
rm Linux-king.tar.gz

# wget http://code.enkre.net/bgen/tarball/release/bgen.tgz
# tar zxvf bgen.tgz

#ml load python/3.8.6-ff

# ./waf configure
# ./waf
# # test it
# ./build/test/unit/test_bgen
# ./build/apps/bgenix -g example/example.16bits.bgen -list

# Merlin doesn't work rn because c++ wnarrowing error
# wget https://csg.sph.umich.edu/abecasis/merlin/download/merlin-1.1.2.tar.gz
# tar -xzvf merlin-1.1.2.tar.gz
# cd merlin-1.1.2
# mkdir merlin
# ./configure prefix=/groups/GENOECON/ukb/software/merlin





cd ..
