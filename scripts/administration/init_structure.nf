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
    //1. Download all required software
    download_software()
    // 2. Download required reference files
    download_references()
    // 3. Download Genotype files 
    download_genotypes(download_software.out)
    // 4. Download Imputation files
    download_imputed(download_software.out)
    // 5. Download Exome Sequencing files
    download_exome(download_software.out)
}

workflow download_software{
    // Link to all UK Biobank executables
    // These are required for basic operations on raw UK biobank data
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
    // Download greedy related, which is required for the QC script
    download_greedy_related()
    // Download ukb_sql, which is used for constructing the SQL database
    download_ukb_sql_constructor()
    emit:
        download_executables.out
}

workflow download_references{
    // 1. Download the reference file. 
    //    Data_Showcase contain detail information of all available phenotype on UKB
    //    Codings contain the coding code for each phenotype
    //    encoding.ukb is required for the extraction of UKB phenotypes
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
        // 1. Genotyped files contain all chromosome
        chr = Channel.of(1..22,"X","Y","XY","MT")
        ukbgene=software.filter{it.baseName == "ukbgene"}
        // download the genotype bed file
        obtain_genotype_data(chr, ukbgene, key)
        // download the bim file
        obtain_bim_files()
        // download the SNP QC files
        obtain_snp_qc()
        // combine the per chromosome files into a single file
        // need the key and ukbgene to get the fam file 
        combine_genotype(
            ukbgene,
            key,
            obtain_genotype_data.out.collect(),
            obtain_bim_files.out.collect()
            )
}

workflow download_imputed{
    take: software
    main:
        // Imputation file does not contain Y and MT
        chr = Channel.of(1..22,"X","XY")
        // We have both imputation and haplotype data
        type = Channel.of("hap", "imp")
        ukbgene=software.filter{it.baseName == "ukbgene"}
        // download the bgen files (both imputation and haplotypes)
        chr \
            | combine(type) \
            | filter{ !(it[0]=="XY" && it[1]=="hap")} \
            | filter{ !(it[0]=="X" && it[1]=="hap")} \
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
        // Exome sequencing data only contain X and Y but not XY and MT
        // for users who want to analyze those chromosome, they might need to 
        // download the individual level data manually
        chr = Channel.of(1..22, "X", "Y")
        gfetch=software.filter{it.baseName == "gfetch"}
        // there are 4 types of exome sequencing data, 
        // population level: PLINK + pVCF
        // individual level: VCF + CRAM
        // for now, we only download PLINK format data (as pVCF isn't available as of yet)
        obtain_exome_plink(chr, gfetch, key)
        // finally, download the bim files
        obtain_exome_bim()
}

/*
 * This section contains the actual code for each processes
 *
 */

process obtain_exome_plink{
    publishDir ".exome/PLINK", mode: 'move'
    input:
        each chr
        path(gfetch)
        path(key)
    output:
        path("UKBexomeOQFE_chr${chr}.bed")
    script:
    """
    ./${gfetch} 23155 -c${chr} -a${key}
    mv ukb23155_c${chr}_*.bed UKBexomeOQFE_chr${chr}.bed
    """
}

process combine_genotype{
    publishDir ".genotype/genotyped/", mode: 'move'
    module "plink"
    input:
        path(ukbgene)
        path(key)
        path("*")
        path("*")
    output:
        tuple   path("ukb.bed"),
                path("ukb.bim")
    script:
    """
    ./${ukbgene} cal -m -c1 -a${key}
    fam=`ls *.fam`
    ls *bed | sed 's/.bed//g' | awk -v f=\$fam '{ print \$1".bed "\$1".bim "f}' > merge_list
    plink \
        --merge-list merge_list \
        --make-bed \
        --out ukb \
        --indiv-sort file \$fam
    """
}

process obtain_exome_bim{
    publishDir ".exome/PLINK", mode: 'move'
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
    publishDir ".genotype/genotyped", mode: 'move'
    output:
        path("ukb_snp_qc.txt")
    script:
    """
    curl -o ukb_snp_qc.txt https://biobank.ctsu.ox.ac.uk/crystal/crystal/auxdata/ukb_snp_qc.txt
    """
}

process obtain_genotype_data{
    input:
        each chr
        path(ukbgene)
        path(key)
    output:
        path "ukb_cal_chr${chr}_v*.bed"
    script:
    """
    ./${ukbgene} cal -c${chr} -a${key}
    """
}

process obtain_imp_extra{    
    publishDir ".genotype/imputed", mode: 'move'
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
    publishDir ".genotype/imputed", mode: 'move'
    input:
        tuple   val(chr),
                val(type),
                path(ukbgene),
                path(key)
    output:
        path "ukb_${type}_chr${chr}_v*.bgen"
    script:
    """
    ./${ukbgene} ${type} -c${chr} -a${key}
    """
}

process download_ukb_sql_constructor{
    publishDir "software/bin", mode: 'move', overwrite: true
    module 'git'
    module 'cmake'
    output:
        path "ukb_sql"
    script:
    """
    git clone https://gitlab.com/choishingwan/ukb_process.git; \
    mv ukb_process src; \
    cd src; \
    mkdir build; \
    cd build ; \
    cmake ../; \
    make; \
    cd ../../; \
    mv src/bin/ukb_sql .
    """

}
process download_greedy_related{
    publishDir "software/bin", mode: 'move', overwrite: true
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
    publishDir "software/bin", mode: 'copy', overwrite: true
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
    publishDir "references", mode: 'move', overwrite: true
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
