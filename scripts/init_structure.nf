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
        ["gfetch","https://biobank.ctsu.ox.ac.uk/crystal/util/gfetch"]
    ) 
    ukb \
        | download_executables
    // also download greedy related, which is required for the QC script
    download_greedy_related()
    emit:
        download_executables
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
    
}
workflow download_imputed{

}
workflow download_exome{

}
/*
 * This section contains the actual code for each processes
 *
 */

process download_greedy_related{
    publishDir "software/bin", mode: 'move', overwrite: true
    module 'git'
    module 'cmake'
    executor 'local'
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
    executor 'local'
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
    executor 'local'
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