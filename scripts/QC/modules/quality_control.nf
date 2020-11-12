

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
    writeLines(paste0("2. ",nrow(dropout),"sample(s) withdrawn their consent"), fileConn)
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
        awk '{print "4. "\$1" snp(s) removed due to missing genotype data (--geno ${geno})"}' > ${out}-basic.meta
    grep removed ${out}-basic-qc.log |\
        grep hwe |\
        awk '{print "5. "\$2" snp(s) removed due Hardy-Weinberg exact test (--hwe ${hwe})"}' >> ${out}-basic.meta
    grep removed ${out}-basic-qc.log |\
        grep minor |\
        awk '{print "6. "\$1" snp(s) removed due to minor allele threshold(s) (${mac})"}' >> ${out}-basic.meta
    """
}

process extract_eur{
    publishDir "genotyped", mode: 'copy', overwrite: true, pattern: '*EUR'
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
    writeLines(paste0("3. ",nrow(eur)," european sample(s) identified using ${kmean}-mean clustering"), fileConn)
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
        sex.bound <- sex[,.(m=mean(F), s=sd(F)), by="Sex"]
        sex[,invalid := FALSE]
        bound <- sex.bound[Sex=="M"]
        sex[   Sex=="M" &
            ( F < bound[,m] -bound[,s]*${sdm} ), invalid:=TRUE]
        bound <- sex.bound[Sex=="F"]
        sex[   Sex=="F" &
            (F > bound[,m] + bound[,s]*${sdm}), invalid:=TRUE]
    }else{
        filter.info <- "(Male fstat >${male}; Female fstat < ${female} )"
        sex[,invalid:=FALSE]
        sex[Sex=="M" & F < ${male}, invalid:=TRUE ]
        sex[Sex=="F" & F < ${female}, invalid:=TRUE ]
    }
    
    invalid <- sex[invalid==TRUE]
    fileConn <- file("${out}-sex.meta")
    writeLines(paste0("7. ",nrow(invalid),"sample(s) with mismatch sex information ",filter.info), fileConn)
    close(fileConn)
    fwrite(invalid, "${out}.sex-mismatch", sep="\\t")
    fwrite(sex[invalid==FALSE], "${out}.sex-valid", sep="\\t")
    """
}


process finalize_data{
    publishDir "genotyped", mode: 'copy', overwrite: true, pattern: "*snplist"
    publishDir "genotyped", mode: 'copy', overwrite: true, pattern: "*qc.fam"
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
    rm ${qc_fam}
    sample=`wc -l ${out}-qc.fam | cut -f 1 -d  " "`
    snp=`wc -l ${out}-qc.snplist | cut -f 1 -d  " "`
    echo "11. \${sample} sample(s) remaining" > ${out}-final.meta
    echo "12. \${snp} snp(s) remaining" >> ${out}-final.meta
    """


}


process relatedness_filtering{
    cpus 1
    executor 'lsf'
    memory '10G'
    time '1h'
    input: 
        path(greedy)
        path(related)
        path(samples) 
        val(thres)
        val(seed)
        val(out)
    output:
        path "${out}-invalid.samples", emit: removed
        path "${out}-rel.meta", emit: meta

    script:
    """
    ./${greedy} \
        -r ${related} \
        -i ID1 \
        -I ID2 \
        -f Kinship \
        -k ${samples} \
        -o ${out}-invalid.samples \
        -t ${thres} \
        -s ${seed}
    num=`wc -l ${out}-invalid.samples| cut -f 1 -d  " "`
    echo "8. \${num} sample(s) removed due to relatedness (Kinship > ${thres})" > ${out}-rel.meta
    """
}

process extract_first_degree{
    publishDir "genotyped", mode: 'copy', overwrite: true, pattern: "*parents"
    publishDir "genotyped", mode: 'copy', overwrite: true, pattern: "*sibs"
    publishDir "plots", mode: 'copy', overwrite: true, pattern: "*png"
    cpus 1
    memory '10G'
    module 'R'
    input:
        path(samples) 
        path(related)
        path(removed)
        val(out)
    output:
        tuple   path("${out}.parents"), 
                path("${out}.sibs"), emit: family
        path "${out}-kinship.png", emit: plot
        path "${out}-family.meta", emit: meta
    script:
    """
    #!/usr/bin/env Rscript
    library(data.table)
    library(magrittr)
    library(ggplot2)
    library(ggsci)
    valid  <- fread("${samples}")[,c("FID", "IID")]
    invalid <- fread("${removed}")
    proband <- valid[!IID %in% invalid[,V2]]
    # Get first degree related samples
    related <- fread("${related}") %>%
        .[Kinship>=0.177 & Kinship <= 0.354] %>%
        .[ID1 %in% proband[,IID] | ID2 %in% proband[,IID]] %>%
        # flip so that ID1 contains all our proband samples
        # and ID2 will be our sibs
        .[ID2 %in% proband[,IID], c("ID1", "ID2"):=list(ID2, ID1)] %>%
        # only allow relatives that passed other QC
        .[ID2 %in% valid[,IID]]
    fwrite(related[IBS0<0.001], "${out}.parents", sep="\\t")
    fwrite(related[IBS0>0.001], "${out}.sibs", sep="\\t")
    related[,group:="Siblings"]
    related[IBS0<0.001, group:="Parents"]

    fileConn <- file("${out}-family.meta")
    input <- c(paste0("9. ",nrow(related[group=="Parents"])," parent(s) were extracted into ${out}.parents"), 
        paste0("10. ",nrow(related[group!="Parents"])," sibling(s) were extracted into ${out}.sibs"))
    writeLines(input, fileConn)
    close(fileConn)
    p <- ggplot(related, aes(x=Kinship, y=IBS0, color=group))+\
            geom_point() + \
            theme_classic() + \
            theme(  axis.title = element_text(size=16, face="bold"),
                    axis.text = element_text(size=14),
                    legend.title = element_blank(),
                    legend.text = element_text(size=14)) + \
            scale_color_npg()
    ggsave("${out}-kinship.png", plot=p, height=7,width=7)
    """

}