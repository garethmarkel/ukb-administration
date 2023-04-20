This is a template repository for downloading UKBiobank data.

To set up your repository, and download genetic files, run:

sh ukb_download.sh <path-to-your-basket-key>

Phenotype data has to be downloaded through the web GUI. Assuming you drop it
in downloads, once this is done you can run:

sh import_pheno.sh <id, e.g. ukb12345 if your file is ukb12345.enc>

to import the dataset, which will generate the html docs file,
decrypt it and convert it to the .tab format to run through R,
and then compress/reformat that as a parquet file after recoding (parquet
files scale especially well with larger datasets).
