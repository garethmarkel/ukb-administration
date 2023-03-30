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

cd ..
