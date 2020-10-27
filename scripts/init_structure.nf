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

workflow{
    // First, we need to download all required software into desired directory
    download_software()
}

workflow download_software{
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
    download_greedy_related()
    
}

process download_greedy_related{
    publishDir "software", mode: 'move', overwrite: true
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
    publishDir "software/bin", mode: 'move', overwrite: true
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