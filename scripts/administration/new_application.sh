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
####################################################
#                                                  #
#              Input sanity check                  #
#                                                  #
####################################################
if [ "${root}" == "." ]; then
    root=`pwd`
fi
ukbgene=${root}/software/bin/ukbgene
gfetch=${root}/software/bin/gfetch
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
if [[ ! -f "${gfetch}" ]]; then
    error=true;
    echo "Error: gfetch binary not found";
    echo "Please make sure you have correctly specified the root directory";
fi
if [[ "${error}" == "true" ]]; then
    exit -1
fi

key=` readlink -f ${key}`
keyName="$(basename -- ${key})"
prefix="ukb${id}"
# Now build the directory structure
dir=${root}/application/${prefix}

####################################################
#                                                  #
#             Obtain Genotyped data                #
#                                                  #
####################################################
mkdir -p ${dir}/genotyped
cd ${dir}/genotyped

ln -s ${key} .  2> /dev/null
has_genotype="no"
{ # try to download fam file. Can only download if we have permission
    ${ukbgene} cal -c1 -m -a${keyName}  &&
    has_genotype="yes"
}
rm ${keyName}
if [ "${has_genotype}" == "yes" ]; then
    ln -s ${root}/.genotype/genotyped/ukb.bed ukb${id}.bed
    ln -s ${root}/.genotype/genotyped/ukb.bed ukb${id}.bim
    mv *.fam ukb${id}.fam
    ln -s ${root}/.genotype/genotyped/ukb_snp_qc.txt . 2> /dev/null
else
    cd ${dir}
    rm -rf genotyped
fi
####################################################
#                                                  #
#      Function for linking multiple files         #
#                                                  #
####################################################
link_files(){
    reference=$1
    fileSuffix=$2
    idxSuffix=$3 # Or bim for plink
    type=$4
    for f in ${reference}/ukb_${type}{*${fileSuffix},*${idxSuffix}};do
        name="$(basename -- ${f})"
        name="${name/ukb_${type}/ukb${id}_${type}}"
        ln -s ${f} ${name} 2> /dev/null
    done
}
####################################################
#                                                  #
#             Obtain Imputed data                  #
#                                                  #
####################################################
has_imputed="no"
mkdir -p ${dir}/imputed
cd ${dir}/imputed
ln -s ${key} . 2> /dev/null
{  # try to download sample file. Can only download if we have permission
    ${ukbgene} imp -c1 -m -a${keyName}  &&
    has_imputed="yes"
}
rm ${keyName}
if [ "${has_imputed}" == "yes" ]; then
    link_files ${root}/.genotype/imputed/ bgen bgi imp 
    ln -s ${root}/.genotype/imputed/*mfi* . 2> /dev/null
else
    cd ${dir}
    rm -rf imputed
fi
####################################################
#                                                  #
#             Obtain Haplotype data                #
#                                                  #
####################################################
has_haplotype="no"
mkdir -p ${dir}/imputed
cd ${dir}/imputed
ln -s ${key} . 2> /dev/null
{  # try to download sample file. Can only download if we have permission
    ${ukbgene} hap -c1 -m -a${keyName}  &&
    has_haplotype="yes"
}
rm ${keyName}
if [ "${has_haplotype}" == "yes" ]; then
    link_files ${root}/.genotype/imputed/ bgen bgi hap
elif [ "${has_imputed}" != "yes" ]; then
    cd ${dir}
        rm -rf imputed
    fi
fi
####################################################
#                                                  #
#         Obtain Exome Sequencing data             #
#                                                  #
####################################################
has_exome="no"
mkdir -p ${dir}/exome/PLINK
cd ${dir}/exome/PLINK
ln -s ${key} . 2> /dev/null
{
    ${gfetch} 23155 -c1 -m -a${keyName} &&
    has_exome="yes"
}

if [ "${has_exome}" == "yes" ]; then
    for f in ${root}/.exome/PLINK/UKBexomeOQFE{*bed,*bim};do
        name="$(basename -- ${f})"
        name="${name/UKBexomeOQFE/ukb${id}}"
        ln -s ${f} ${name} 2> /dev/null
    done
    fam=`ls *.fam`
    mv ${fam} ukb${id}_chr1.fam
    fam="ukb${id}_chr1.fam"
    for ((i=2; i<=22; i++));
    do
        ln -s ${fam} ukb${id}_chr${i}.fam 2> /dev/null
    done
    misc=( "X" "Y" )
    for i in ${misc[@]};
    do
        ln -s ${fam} ukb${id}_chr${i}.fam 2> /dev/null
    done
else
    cd ${dir}
    rm -rf exome/PLINK
fi
####################################################
#                                                  #
#             Add Phenotype folder                 #
#                                                  #
####################################################
mkdir -p ${dir}/phenotype/raw
mkdir -p ${dir}/phenotype/raw/encrypted
mkdir -p ${dir}/phenotype/raw/keys
mkdir -p ${dir}/phenotype/withdrawn

####################################################
#                                                  #
#         Get relatedness information              #
#                                                  #
####################################################
cd ${dir}/genotyped
ln -s ${key} . 2> /dev/null
${ukbgene} rel -a${keyName}
rm ${keyName}
cp ${key} ${dir}/phenotype/raw/keys

####################################################
#                                                  #
#                   Print log                      #
#                                                  #
####################################################
date=`date`
cd ${dir}
log=${dir}/ukb${id}_init.log
echo "Application ${id} built on ${date}" | tee ${log}
echo "with new_application.sh ${version} ${date} " | tee -a ${log}
echo "Has access to genotyped data: ${has_genotype}" | tee -a ${log}
echo "Has access to imputed data: ${has_imputed}" | tee -a ${log}
echo "Has access to haplotype data: ${has_haplotype}" | tee -a ${log}
echo "Has access to exome sequencing data: ${has_exome}" | tee -a ${log}
echo "Please download the access keys and put it into"
echo ""
echo "${dir}/phenotype/raw/keys"
echo ""
echo "and put the encrypted UK Biobank phenotype file into "
echo ""
echo "${dir}/phenotype/raw/encrypted"
echo ""
