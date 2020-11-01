process extract_sqc_test{
    publishDir "phenotype", mode: 'copy', overwrite: true
    input:
        path(db)
        val(out)
    output:
        path "${out}.invalid", emit: het
        path "${out}.sex", emit: sex
        path "${out}.covar", emit: covar
        path "${out}-het.meta", emit: meta
    script:
    """
    echo "
    .mode csv
    .header on
    .output ${out}.sex
    SELECT  s.sample_id AS FID,
            s.sample_id AS IID
    FROM    Participant s
            WHERE withdrawn = 0
            
    FROM    Participant s
            LEFT JOIN   f31 sex ON
                        s.sample_id=sex.sample_id
                        AND sex.instance = 0
            LEFT JOIN   f21003 age ON
                        s.sample_id=age.sample_id
                        AND age.instance = 0
            LEFT JOIN   f54 centre ON
                        s.sample_id=centre.sample_id
                        AND centre.instance = 0
            LEFT JOIN   f${fieldID} trait ON
                        s.sample_id=trait.sample_id
                        AND trait.instance = 0;
    .quit
        " > sql;
    sqlite3 ${db} < sql
    """

}
process extract_sqc{
    publishDir "phenotype", mode: 'copy', overwrite: true
    module 'R'
    input:
        path(sqc)
        val(out)
    output:
        path "${out}.invalid", emit: het
        path "${out}.sex", emit: sex
        path "${out}.covar", emit: covar
        path "${out}-het.meta", emit: meta
    script:
    """
    #!/usr/bin/env Rscript
    library(data.table)
    library(magrittr)
    dat <- fread("${sqc}")
    dat[,c("FID", "IID", "Batch", paste("PC",1:40,sep=""))] %>%
        fwrite(., "${out}.covar", quote=F, na="NA", sep="\\t")
    dat[,c("FID", "IID", "Submitted.Gender")] %>%
        fwrite(., "${out}.sex", quote=F, na="NA", sep="\\t")
    het <- dat[het.missing.outliers==1 | excess.relatives==1 | FID < 0] %>%
        .[,c("FID", "IID")] 
        fwrite(het , "${out}.invalid", quote=F, na="NA", sep="\\t")
    fileConn <- file("${out}-het.meta")
    writeLines(paste0("2. ",nrow(het),"sample(s) with excessive het, missing or relatives"), fileConn)
    close(fileConn)
    """
}

process first_pass_geno{
    cpus 12
    module 'plink/1.90b6.7'
    executor 'lsf'
    memory '1G'
    input:
        tuple   path(bed),
                path(bim),
                path(fam)
        val(geno)
        val(out)
    output:
        path "${out}-geno${geno}.snplist", emit: snp
        path "${out}-geno.meta", emit: meta
    script:

    """
    plink   --bed ${bed} \
            --bim ${bim} \
            --fam ${fam} \
            --geno ${geno} \
            --write-snplist \
            --out ${out}-geno${geno}
    grep removed ${out}-geno${geno}.log |\
        awk '{print "1. First pass geno filter (--geno ${geno}) removed: "\$1" snp(s)"}' > ${out}-geno.meta
    """
}

process remove_dropout_and_invalid{
    module 'R'
    input:
        tuple   path(bed),
                path(bim),
                path(fam)
        path(invalid)
        path(dropout)
        val(out)
    output:
        path "${out}-remove", emit: removed
        path "${out}-dropout.meta", emit: meta
    script:
    """
    #!/usr/bin/env Rscript
    library(data.table)
    library(magrittr)
    fam <- fread("${fam}") %>%
        setnames(., c("V1", "V2"),c("FID", "IID")) %>%
        .[,c("FID", "IID")]
    invalid <- fread("${invalid}")        
    dropout <- fread("${dropout}", header=F)
    fam <- fam[IID%in% dropout[,V1]]
    rbind(invalid, fam) %>%
        fwrite(., "${out}-remove", sep="\\t")
    fileConn <- file("${out}-dropout.meta")
    writeLines(paste0("3. ",nrow(dropout),"sample(s) withdrawn their consent"), fileConn)
    close(fileConn)
    """
}

process basic_qc{
    cpus 12
    module 'plink/1.90b6.7'
    executor 'lsf'
    memory '1G'
    input:
        tuple   path(bed),
                path(bim),
                path(fam)
        path(snplist)
        path(eur)
        path(remove)
        val(hwe)
        val(geno)
        val(mac)
        val(out)
    output:
        tuple   path("${out}-basic-qc.fam"), 
                path("${out}-basic-qc.snplist"), emit: qc
        path "${out}-basic.meta", emit: meta
    script:
    base=bed.baseName
    """
    plink   --keep ${eur} \
            --bed ${bed} \
            --bim ${bim} \
            --fam ${fam} \
            --geno ${geno} \
            ${mac} \
            --hwe ${hwe} \
            --write-snplist \
            --make-just-fam \
            --out ${out}-basic-qc \
            --remove ${remove} 
    grep removed ${out}-basic-qc.log |\
        grep geno |\
        awk '{print "5. "\$1" snp(s) removed due to missing genotype data (--geno ${geno})"}' > ${out}-basic.meta
    grep removed ${out}-basic-qc.log |\
        grep hwe |\
        awk '{print "6. "\$1" snp(s) removed due Hardy-Weinberg exact test (--hwe ${hwe})"}' >> ${out}-basic.meta
    grep removed ${out}-basic-qc.log |\
        grep hwe |\
        awk '{print "7. "\$1" snp(s) removed due to minor allele threshold(s) (${mac})"}' >> ${out}-basic.meta
    """
}

process extract_eur{
    publishDir "genotype", mode: 'copy', overwrite: true, pattern: '*EUR'
    publishDir "plots", mode: 'copy', overwrite: true, pattern: '*png'
    module 'R'
    executor 'lsf'
    input:
        path(covar)
        val(kmean)
        val(seed)
        val(out)
    output:
        path "${out}-${kmean}mean-EUR", emit: eur
        path "${out}-pca.png", emit: pca
        path "${out}-eur.meta", emit: meta
    script:
    """
    #!/usr/bin/env Rscript
    library(data.table)
    library(ggplot2)
    library(ggsci)
    cov <- fread("${covar}")
    # Set the seed for the kmean clustering
    if("${seed}"!="false"){
        set.seed("${seed}")
    }
    pc1k<-kmeans(cov[,PC1], ${kmean})
    pc2k<-kmeans(cov[,PC2], ${kmean})
    cov[,clusters:=as.factor(paste(pc1k\$cluster,pc2k\$cluster,sep="."))]
    #table(pc1k\$cluster, pc2k\$cluster)
    g <- ggplot(cov, aes(x=PC1,y=PC2, color=clusters))+\
            geom_point()+\
            theme_classic()+\
            scale_color_npg()
    ggsave("${out}-pca.png", plot=g, height=7,width=7)
    max.cluster <- names(which.max(table(cov[,clusters])))
    # We assume the largest cluster is the EUR cluster
    eur <- cov[clusters==max.cluster,c("FID", "IID")]
    fwrite(cov[clusters==max.cluster,c("FID", "IID")], "${out}-${kmean}mean-EUR", quote=F, na="NA", sep="\\t")

    fileConn <- file("${out}-eur.meta")
    writeLines(paste0("4. ",nrow(eur)," european sample(s) identified using ${kmean}-mean clustering"), fileConn)
    close(fileConn)
    """
}

process generate_high_ld_region{
    cpus 12
    module 'plink/1.90b6.7'
    memory '1G'
    executor 'lsf'
    input:
        tuple   path(qc_fam), 
                path(qc_snp)
        tuple   path(bed),
                path(bim),
                path(fam)
        val(build)
        val(out)
    output:
        path "${out}.set"
    script:
    base=bed.baseName
    """
    echo "1     48000000     52000000   High_LD
2     86000000     100500000    High_LD
2     134500000     138000000   High_LD
2     183000000     190000000   High_LD
3     47500000     50000000 High_LD
3     83500000     87000000 High_LD
3     89000000     97500000 High_LD
5     44500000     50500000 High_LD
5     98000000     100500000    High_LD
5     129000000     132000000   High_LD
5     135500000     138500000   High_LD
6     25000000     35000000 High_LD
6     57000000     64000000 High_LD
6     140000000     142500000   High_LD
7     55000000     66000000 High_LD
8     7000000     13000000  High_LD
8     43000000     50000000 High_LD
8     112000000     115000000   High_LD
10     37000000     43000000    High_LD
11     46000000     57000000    High_LD
11     87500000     90500000    High_LD
12     33000000     40000000    High_LD
12     109500000     112000000  High_LD
20     32000000     34500000 High_LD" > high_ld_37
    echo "1     48060567     52060567     hild
2     85941853     100407914     hild
2     134382738     137882738     hild
2     182882739     189882739     hild
3     47500000     50000000     hild
3     83500000     87000000     hild
3     89000000     97500000     hild
5     44500000     50500000     hild
5     98000000     100500000     hild
5     129000000     132000000     hild
5     135500000     138500000     hild
6     25500000     33500000     hild
6     57000000     64000000     hild
6     140000000     142500000     hild
7     55193285     66193285     hild
8     8000000     12000000     hild
8     43000000     50000000     hild
8     112000000     115000000     hild
10     37000000     43000000     hild
11     46000000     57000000     hild
11     87500000     90500000     hild
12     33000000     40000000     hild
12     109521663     112021663     hild
20     32000000     34500000     hild
X     14150264     16650264     hild
X     25650264     28650264     hild
X     33150264     35650264     hild
X     55133704     60500000     hild
X     65133704     67633704     hild
X     71633704     77580511     hild
X     80080511     86080511     hild
X     100580511     103080511     hild
X     125602146     128102146     hild
X     129102146     131602146     hild" > high_ld_38
    ldFile=high_ld_37
    if [[ "${build}" != "grch37" ]];
    then
        ldFile=high_ld_38
    fi
    echo \${ldFile}
    plink \
        --bed ${bed} \
        --bim ${bim} \
        --fam ${fam} \
        --extract ${qc_snp} \
        --keep ${qc_fam} \
        --make-set \${ldFile} \
        --write-set \
        --out ${out}
    """
}


process prunning{
    cpus 12
    memory '1G'
    executor 'lsf'
    module 'plink/1.90b6.7'
    input: 
        tuple   path(bed),
                path(bim),
                path(fam)
        tuple   path(qc_fam),
                path(qc_snp)
        path(high_ld)
        val(wind_size)
        val(wind_step)
        val(wind_r2)
        val(max_size)
        val(seed)
        val(out)
    output:
        path "${out}-qc.prune.in"
    script:
    base=bed.baseName
    """
    if [[ \$(wc -l < ${qc_fam}) -ge ${max_size} ]];
    then
        plink \
            --bed ${bed} \
            --bim ${bim} \
            --fam ${fam} \
            --extract ${qc_snp} \
            --keep ${qc_fam} \
            --indep-pairwise ${wind_size} ${wind_step} ${wind_r2} \
            --out ${out}-qc \
            --thin-indiv-count ${max_size} \
            --seed ${seed} \
            --exclude ${high_ld}
    else
        plink \
            --bed ${bed} \
            --bim ${bim} \
            --fam ${fam} \
            --extract ${qc_snp} \
            --keep ${qc_fam} \
            --indep-pairwise ${wind_size} ${wind_step} ${wind_r2} \
            --out ${out}-qc \
            --exclude ${high_ld}
    fi 
    """
}  


process calculate_stat_for_sex{
    cpus 12
    memory '1G'
    module 'plink/1.90b6.7'
    executor 'lsf'
    input:
        tuple   path(bed),
                path(bim),
                path(fam)
        tuple   path(qc_fam),
                path(qc_snp)
        path(prune)
        val(out)
    output:
        path "${out}.sexcheck"
    script:
    base=bed.baseName
    """
    plink \
        --bed ${bed} \
        --bim ${bim} \
        --fam ${fam} \
        --extract ${prune} \
        --keep ${qc_fam} \
        --check-sex \
        --out ${out}
    """
}


process filter_sex_mismatch{
    cpus 1
    executor 'lsf'
    memory '1G'
    module 'R'
    input:
        tuple   path(qc_fam), 
                path(qc_snp)
        path (fstat)
        path (biosex)
        val(mode)
        val(sdm)
        val(male)
        val(female)
        val(out)
    output:
        path "${out}.sex-mismatch", emit: mismatch
        path "${out}.sex-valid", emit: valid
        path "${out}-sex.meta", emit: meta
    script:
    """
    #!/usr/bin/env Rscript
    library(data.table)
    library(magrittr)
    fam <- fread("${qc_fam}")
    # Read in sex information and remove samples that doesn't pass QC
    sex <- fread("${biosex}") %>%
        merge(., fread("${fstat}")) %>%
        .[FID %in% fam[,V1] & FID > 0]
    filter.info <- NULL
    if("${mode}"=="sd"){
        filter.info <-  "(${sdm} ${mode} from mean)"
        sex.bound <- sex[,.(m=mean(F), s=sd(F)), by="Submitted.Gender"]
        sex[,invalid := FALSE]
        bound <- sex.bound[Submitted.Gender=="M"]
        sex[   Submitted.Gender=="M" &
            ( F < bound[,m] -bound[,s]*${sdm} ), invalid:=TRUE]
        bound <- sex.bound[Submitted.Gender=="F"]
        sex[   Submitted.Gender=="F" &
            (F > bound[,m] + bound[,s]*${sdm}), invalid:=TRUE]
    }else{
        filter.info <- "(Male fstat >${male}; Female fstat < ${female} )"
        sex[,invalid:=FALSE]
        sex[Submitted.Gender=="M" & F < ${male}, invalid:=TRUE ]
        sex[Submitted.Gender=="F" & F < ${female}, invalid:=TRUE ]
    }
    
    invalid <- sex[invalid==TRUE]
    fileConn <- file("${out}-sex.meta")
    writeLines(paste0("8. ",nrow(invalid),"sample(s) with mismatch sex information ",filter.info), fileConn)
    close(fileConn)
    fwrite(invalid, "${out}.sex-mismatch", sep="\\t")
    fwrite(sex[invalid==FALSE], "${out}.sex-valid", sep="\\t")
    """
}


process finalize_data{
    publishDir "genotype", mode: 'copy', overwrite: true
    cpus 12
    module 'plink/1.90b6.7'
    memory '1G'
    executor 'lsf'
    input:
        tuple   path(bed),
                path(bim),
                path(fam)
        tuple   path(qc_fam),
                path(qc_snp)
        path(sex)
        path(rel)
        val(out)
    output:
        tuple   path("${out}-qc.snplist"),
                path("${out}-qc.fam"), emit: qced
        path "${out}-final.meta", emit: meta
    script:
    base=bed.baseName
    """
    cat ${rel} ${sex} > ${out}.removed
    plink \
        --bed ${bed} \
        --bim ${bim} \
        --fam ${fam} \
        --extract ${qc_snp} \
        --keep ${qc_fam} \
        --remove ${out}.removed \
        --make-just-fam \
        --write-snplist \
        --out ${out}-qc
    sample=`wc -l ${out}-qc.fam`
    snp=`wc -l ${out}-qc.snplist`
    echo "12. \${sample} sample(s) remaining" > ${out}-final.meta
    echo "13. \${snp} snp(s) remaining" >> ${out}-final.meta
    """


}


