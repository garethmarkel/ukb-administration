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
if [ "${root}" == "." ]; then
    root=`pwd`
fi
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

# First, check if we have access to genotype data
mkdir -p ${dir}/genotyped
cd ${dir}/genotyped
has_genotype="no"
ln -s ${key} . 2> /dev/null
keyName="$(basename -- ${key})"
{ # try to download fam file. Can only download if we have permission
    ${ukbgene} cal -c1 -m -a${keyName}  &&
    has_genotype="yes"
}
if [ "${has_genotype}" == "yes" ]; then
    for f in ${root}/.genotype/genotyped/{*bed,*bim};do
        name="$(basename -- ${f})"
        name="${name/ukb_cal/ukb${id}}"
        ln -s ${f} ${name} 2> /dev/null
    done
    fam=`ls *.fam`
    mv ${fam} ukb${id}_chr1_v2.fam
    fam="ukb${id}_chr1_v2.fam"
    for ((i=2; i<=22; i++));
    do
        ln -s ${fam} ukb${id}_chr${i}_v2.fam
    done
    misc=( "X" "XY" "Y" "MT" )
    for i in ${misc[@]};
    do
        ln -s ${fam} ukb${id}_chr${i}_v2.fam
    done
    ln -s ${root}/.genotype/genotyped/ukb_snp_qc.txt .
    rm ${keyName}
else
    cd ${dir}
    rm -rf genotyped
fi
# Next we work with imputed data
has_imputed="no"
mkdir -p ${dir}/imputed
cd ${dir}/imputed
ln -s ${key} . 2> /dev/null
keyName="$(basename -- ${key})"
{  # try to download sample file. Can only download if we have permission
    ${ukbgene} imp -c1 -m -a${keyName}  &&
    has_imputed="yes"
}
if [ "${has_imputed}" == "yes" ]; then
    for f in ${root}/.genotype/genotyped/{*bed,*bim};do
        name="$(basename -- ${f})"
        name="${name/ukb_cal/ukb${id}}"
        ln -s ${f} ${name} 2> /dev/null
    done
    fam=`ls *.fam`
    mv ${fam} ukb${id}_chr1_v2.fam
    fam="ukb${id}_chr1_v2.fam"
    for ((i=2; i<=22; i++));
    do
        ln -s ${fam} ukb${id}_chr${i}_v2.fam
    done
    misc=( "X" "XY" "Y" "MT" )
    for i in ${misc[@]};
    do
        ln -s ${fam} ukb${id}_chr${i}_v2.fam
    done
    ln -s ${root}/.genotype/genotyped/ukb_snp_qc.txt .
    rm ${keyName}
else
    cd ${dir}
    rm -rf imputed
fi