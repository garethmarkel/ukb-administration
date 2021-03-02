process get_software_version{
    executor 'local'
    module 'cmake'
    input:
        val(out)
        path("*")
    output:
        path("${out}-software.log")
    script:
    """
    for i in `ls`; 
    do
        ./\$i -v >> ${out}.tmp 2>&1
    done
    awk '{print "@"\$0}' ${out}.tmp > ${out}-software.log
    """
}

process combine_meta{
    executor 'local'
    input: 
        val(out)
        path("*")
    output:
        path("${out}-qc.meta")
    script:
    """
        for i in `ls *meta`;
        do
            cat \${i} >> ${out}-qc.tmp
        done
        sort -g ${out}-qc.tmp > ${out}-qc.meta
    """
}

process write_log{
    publishDir ".", mode: 'copy', overwrite: true
    executor 'local'
    input: 
        path(version)
        path(meta)
        val(out)
    output:
        path("${out}.log")
    script:
    """
    echo "Pipeline completed on "`date` > ${out}.log
    echo "" >> ${out}.log
    echo "Software information: " >> ${out}.log
    echo "================================" >> ${out}.log
    mv ${version} version
    cat version >> ${out}.log
    echo "" >> ${out}.log
    echo "Quanlity Control information: ">> ${out}.log
    echo "================================" >> ${out}.log
    cat ${meta} >> ${out}.log
    echo "" >> ${out}.log
    echo "Directory structure: ">> ${out}.log
    echo "================================" >> ${out}.log
echo "

    |-- ${out}.log # This log file
    |
    |-- genotyped
    |    |
    |    |-- ${out}-qc.fam # Post QC fam file. Should use this in analyses
    |    |
    |    |-- ${out}-qc.snplist # Post QC snp file. Should use this in analyses
    |    |
    |    |-- ${out}-*mean-EUR # file contains european samples
    |    |
    |    |-- ${out}.parents # Parental information. Useful if want to include family data
    |    |
    |    |-- ${out}.sibs # Sibling information. Useful if want to include family data
    |
    |-- imputed
    |
    |-- phenotype
    |    |
    |    |-- ${out}.covar # Covariate information. Contain batch and 40 PCs
    |    |
    |    |-- ${out}.db # SQLite database containing all phenotype information
    |    |
    |    |-- raw
    |        |
    |        |-- *.field_finder # field finder for phenotype extraction from the *.tab files
    |        |
    |        |-- *.tab # Raw text phenotype information. Useful for non-sql operation
    |        |
    |        |-- withdrawn # Folder containing the withdrawn samples
    |     
    |-- plots
        |
        |-- ${out}-kinship.png # Plot showing the IBS0 and kinship relationship
        |
        |-- ${out}-pca.png # Plot illustrating kmean results
 "   >> ${out}.log
    """

}

process obtain_exome_qvcf{
    publishDir "exome/qVCF", mode: 'move'
    input:
        each chr
        val(prefix)
        path(gfetch)
        path(key)
    output:
        path "ukb${id}_chr${chr}.vcf.gz", optional true
    script:
    """
    ./${gfetch} 23156 -c${chr} -a${key}
    mv ukb23156_c${chr}*.vcf.gz ${prefix}_chr${chr}.vcf.gz
    """
}
