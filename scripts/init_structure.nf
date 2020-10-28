#!/usr/bin/env nextflow
nextflow.preview.dsl=2
params.version=false
params.help=false
version='0.0.1'
timestamp='2020-10-27'

if(params.version) {
    System.out.println("")
    System.out.println("Initialize UK Biobank directory - Version: $version ($timestamp)")
    exit 1
}
if(params.help) {
    System.out.println("")
    System.out.println("Initialize UK Biobank directory - Version: $version ($timestamp)")
    System.out.println("Usage: ")
    System.out.println("    nextflow run init_structure.nf [options]")
    System.out.println("Mandatory arguments:")
    System.out.println("    --key    UK Biobank md5 key file")
    System.out.println("    --id     ID of current UK Biobank application number")
    exit 1
}

id = Channel.from("${params.id}")
key = Channel.fromPath("${params.key}")
workflow{
    // First, we need to download all required software into desired directory
    download_software()
    // We then download the required reference files
    download_references()
    // now start downloading the genotype files 
    download_genotypes(download_software.out)
    download_imputed(download_software.out)
    download_exome(download_software.out)
}

workflow download_software{
    // Link to all UK Biobank executables
    ukb = Channel.from(
        ["ukbmd5", "https://biobank.ctsu.ox.ac.uk/crystal/util/ukbmd5"],
        ["ukbconv","https://biobank.ctsu.ox.ac.uk/crystal/util/ukbconv"],
        ["ukbunpack","https://biobank.ctsu.ox.ac.uk/crystal/util/ukbunpack"],
        ["ukbfetch","https://biobank.ctsu.ox.ac.uk/crystal/util/ukbfetch"],
        ["ukblink","https://biobank.ctsu.ox.ac.uk/crystal/util/ukblink"],
        ["gfetch","https://biobank.ctsu.ox.ac.uk/crystal/util/gfetch"],
        ["ukbgene","https://biobank.ndph.ox.ac.uk/showcase/util/ukbgene"]
    ) 
    ukb \
        | download_executables
    // also download greedy related, which is required for the QC script
    download_greedy_related()
    emit:
        download_executables.out

}

workflow download_references{
    ukb = Channel.from(
        ["encoding.ukb", "https://biobank.ctsu.ox.ac.uk/crystal/util/encoding.ukb"],
        ["Data_Dictionary_Showcase.csv","https://biobank.ctsu.ox.ac.uk/~bbdatan/Data_Dictionary_Showcase.csv"],
        ["Codings.csv","https://biobank.ctsu.ox.ac.uk/~bbdatan/Codings.csv"]
    )
    ukb \
        | download_files
}

workflow download_genotypes{
    take: software
    main:
        chr = Channel.of(1..22,"X","Y","XY","MT")
        ukbgene=software.filter{it.baseName == "ukbgene"}
        // download the genotype bed file
        obtain_genotype_data(chr, ukbgene, key)
        // download the bim file
        obtain_bim_files()
        // download the SNP QC files
        obtain_snp_qc()
}

workflow download_imputed{
    take: software
    main:
        chr = Channel.of(1..22,"X","XY")
        type = Channel.of( "imp")
        ukbgene=software.filter{it.baseName == "ukbgene"}
        // download the bgen files (both imputation and haplotypes)
        chr \
            | combine(type) \
            | filter{ !(it[0]=="XY" && it[2]=="hap")} \
            | combine(ukbgene) \
            | combine(key) \
            | obtain_imputed_data
        // download the index and the file containing the maf and info score
        // maf and info score only available for imputation data
        type \
            | combine(Channel.of("bgi","mfi")) \
            | filter{!(it[0] == "hap" && it[1] == "mfi")} \
            | obtain_imp_extra
            
}
workflow download_exome{
    take: software
    main:
        chr = Channel.of(1..22, "X", "Y")
        gfetch=software.filter{it.baseName == "gfetch"}
        // there are 4 types of exome sequencing data, 
        // population level: PLINK + pVCF
        // individual level: VCF + CRAM
        // for now, we only download PLINK format data (as pVCF isn't available as of yet)
        //obtain_exome_plink(chr, gfetch, key)
        obtain_exome_bim()
}
/*
 * This section contains the actual code for each processes
 *
 */

process obtain_exome_plink{
    publishDir ".exome/PLINK", mode: 'symlink'
    input:
        each chr
        path(gfetch)
        path(key)
    output:
        path("UKBexomeOQFE_chr${chr}.bed")
    script:
    """
    ./${gfetch} 23155 -c${chr} -a${key}
    mv ukb23155_c${chr}_b0_v1.bed UKBexomeOQFE_chr${chr}.bed
    """
}


process obtain_exome_bim{
    publishDir ".exome/PLINK", mode: 'symlink'
    output:
        path("*")
    script:
    """
    curl -o UKBexomeOQFEbim.zip https://biobank.ctsu.ox.ac.uk/crystal/crystal/auxdata/UKBexomeOQFEbim.zip
    unzip UKBexomeOQFEbim.zip
    # rename the files to ensure consistency
    rm UKBexomeOQFEbim.zip
    """
}

process obtain_bim_files{
    publishDir ".genotype/genotyped", mode: 'symlink'
    output:
        path("*")
    script:
    """
    curl -o ukb_snp_bim.tar https://biobank.ctsu.ox.ac.uk/crystal/crystal/auxdata/ukb_snp_bim.tar
    tar -xvf ukb_snp_bim.tar
    # rename the files to ensure consistency
    ls *bim  | awk '{a=\$1; gsub("snp","cal",\$1); print "mv "a,\$1}' | bash
    rm ukb_snp_bim.tar
    """
}

process obtain_snp_qc{
    publishDir ".genotype/genotyped", mode: 'symlink'
    output:
        path("ukb_snp_qc.txt")
    script:
    """
    curl -o ukb_snp_qc.txt https://biobank.ctsu.ox.ac.uk/crystal/crystal/auxdata/ukb_snp_qc.txt
    """
}

process obtain_genotype_data{
    publishDir ".genotype/genotyped", mode: 'symlink'
    input:
        each chr
        path(ukbgene)
        path(key)
    output:
        path "ukb_cal_chr${chr}_v2.bed"
    script:
    """
    ./${ukbgene} cal -c${chr} -a${key}
    """
}

process obtain_imp_extra{    
    publishDir ".genotype/imputed", mode: 'symlink'
    input:
        tuple   val(type),
                val(info)
    output:
        path("*")
    script:
    """
    curl -o ukb_${type}_${info}.tgz https://biobank.ctsu.ox.ac.uk/crystal/crystal/auxdata/ukb_${type}_${info}.tgz
    tar -xvf ukb_${type}_${info}.tgz
    rm ukb_${type}_${info}.tgz
    """
}

process obtain_imputed_data{
    publishDir ".genotype/imputed", mode: 'symlink'
    input:
        tuple   val(chr),
                val(type),
                path(ukbgene),
                path(key)
    output:
        path "ukb_${type}_chr${chr}_v2.bgen"
    script:
    """
    ./${ukbgene} ${type} -c${chr} -a${key}
    """
}

process download_greedy_related{
    publishDir "software/bin", mode: 'symlink', overwrite: true
    module 'git'
    module 'cmake'
    output:
        path "GreedyRelated", emit: greedy
    script:
    """
    git clone https://gitlab.com/choishingwan/GreedyRelated.git; \
    mv GreedyRelated src; \
    cd src; \
    mkdir build; \
    cd build ; \
    cmake ../; \
    make; \
    cd ../../; \
    mv src/bin/GreedyRelated .
    """
}

process download_executables{
    // need to copy here, as we will need ukbfetch for later use
    publishDir "software/bin", mode: 'symlink', overwrite: true
    input:
        tuple   val(name),
                val(url)
    output:
        path(name)
    script:
    """
    curl -o ${name} ${url}
    chmod 755 ${name}
    """
}

process download_files{
    publishDir "references", mode: 'symlink', overwrite: true
    input:
        tuple   val(name),
                val(url)
    output:
        path(name)
    script:
    """
    curl -o ${name} ${url}
    """
}
