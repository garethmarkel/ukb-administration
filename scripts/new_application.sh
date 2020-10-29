#!/usr/bin/env bash

OPTIND=1         # Reset in case getopts has been used previously in the shell.

usage()
{
   # Display Usage
   echo "new_application.sh is responsible to generate"
   echo "new application folder within the UK Biobank"
   echo "directory"
   echo
   echo "Usage: new_application.sh -k <key file> -i <application ID> [options]"
   echo "parameters:"
   echo "    -k    UK Biobank key file, for data access"
   echo "    -i    Application ID name. Will be used as folder name"
   echo "    -r    UK Biobank root directory. Application will be stored here"
   echo "    -h    Print this Help."
   echo "    -v    Print software version and exit."
   echo
}


key=""
id=""
root=""
version=false
help=false
version="0.0.1"

# Initialize our own variables:
output_file=""
verbose=0
root="."
while getopts "h?vk:i:r:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    v)  echo "${version}"
        exit 0
        ;;
    k)  key=$OPTARG
        ;;
    r)  root=$OPTARG
        ;;
    i)  id=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift
echo ""
echo "new_application.sh ${version} (2020-10-29)"
echo "(C) 2020 Shing Wan (Sam) Choi"
echo "MIT License"
echo ""
echo ""

ukbgene=${root}/software/bin/ukbgene
error=false
# Check if user provided the required key file
if [ -z "${key}" ]; then
    error=true;
    echo "Error: You must submit the key file";
elif [[ ! -f "${key}" ]]; then
    error=true;
    echo "Error: Key file: ${key} does not exist";
fi
# Check if we have the ukbgene software 
# Use to obtain fam file and check for 
# permission
if [[ ! -f "${ukbgene}" ]]; then
    error=true;
    echo "Error: ukbgene binary not found";
    echo "Please make sure you have correctly specified the root directory";
fi
if [[ "${error}" == "true" ]]; then
    exit -1
fi

prefix="ukb${id}"
# Now build the directory structure
dir=${root}/application/${prefix}
mkdir -p ${dir}
# Start working in the directory
mv ${dir}
# First, check if we have access to genotype data
has_genotype="no"
ln -s ${key} .
keyName="$(basename -- ${key})"
{ # try
    ukbgene cal -c1 -m -a${keyName}  &&
    #save your output
    has_genotype="yes"

} || { # catch
    # save log for exception 
}

echo "Has access right to genotype: ${has_genotype}"
mkdir -p ${dir}/genotyped
mkdir -p ${dir}/imputed