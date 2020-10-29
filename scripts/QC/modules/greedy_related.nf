process download_greedy_related{
    publishDir "software", mode: 'copy', overwrite: true
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
    num=`wc -l ${out}-invalid.samples`
    echo "9. \${num} sample(s) removed due to relatedness (Kinship > ${thres})" > ${out}-rel.meta
    """
}

process extract_first_degree{
    publishDir "genotype", mode: 'copy', overwrite: true
    cpus 1
    memory '10G'
    module 'R'
    input:
        path(samples) 
        path(related)
        path(removed)
        val(out)
    output:
        tuple path("${out}.parents"), path("${out}.sibs"), emit: family
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
    input <- c(paste0("10. ",nrow(related[group=="Parents"])," parent(s) were extracted into ${out}.parents"), 
        paste0("11. ",nrow(related[group!="Parents"])," sibling(s) were extracted into ${out}.sibs"))
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