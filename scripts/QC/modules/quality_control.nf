#!/usr/bin/env nextflow



params.maf = 0.01
params.geno1 = 0.2
params.geno2 = 0.02
params.mind = 0.02
params.hwe = 1e-6
params.windSize=200
params.windStep=50
params.r2=0.2
params.maxSize=10000
params.seed=1234
params.plink="plink"
params.eur=""
maf=params.maf 
geno1=params.geno1
geno2=params.geno2
mind=params.mind
hwe=params.hwe
bfile=params.bfile
fam= params.fam
rel=params.rel
greed=params.greed
plink=params.plink
meta=params.meta
out=params.out
eur=params.eur
wind_size=params.windSize
wind_step=params.windStep
wind_r2=params.r2
max_size=params.maxSize
seed=params.seed
fileExists = { fn ->
   if (fn.exists())
       return fn;
    else
       error("\n\n-----------------\nFile $fn does not exist\n\n---\n")
}


firstPass = Channel
   .fromFilePairs("${bfile}.{bed,bim,fam}",size:3, flat : true){ file -> file.baseName }  
      .ifEmpty { error "No matching plink files" }        
      // apply the fileExists function to the three input (bed bim fam)
      .map { a -> [fileExists(a[1]), fileExists(a[2]), fileExists(a[3])] } 
      

if(eur==""){
    eurFilter=""
}else{
    eurFilter="--keep ${eur}"
}

process firstPassGeno{
    input:
    set file(bed), file(bim), file(fam) from firstPass

    output:
    file ("${out}-geno${geno1}.snplist") into (fgeno)
    set file(bed), file(bim), file(fam) into basicQC
    script:

    base = bed.baseName
    """
    plink   --bfile ${base} \
            --geno ${geno1} \
            --write-snplist \
            --out ${out}-geno${geno1}
    """
}


process basicQC{
    input:
    set file(bed), file(bim), file(fam) from basicQC
    file(snplist) from (fgeno)
    
    output:
    set file("${out}-qc.fam"), file("${out}-qc.snplist") into (qced)
    set file(bed), file(bim), file(fam) into (prune)
    file("${out}.sample.count") into num_sample
    script:
    base=bed.baseName
    """
    plink   ${eurFilter} \
            --bfile ${base} \
            --geno ${geno2} \
            --maf ${maf} \
            --hwe ${hwe} \
            --write-snplist \
            --make-just-fam \
            --out ${out}-qc 
    
    wc -l ${out}-qc.fam > ${out}.sample.count
    """
}


import java.nio.file.Files; 
process prunning{
    input:
    set file(bed), file(bim), file(fam) from prune
    set file(qcfam), file(qcsnp), file(count) from qced
    file(sample_num) from num_sample
    
    output:
    set file(bed), file(bim), file(fam) into sexcheck
    set file("${out}-qc.prune.in"), file("${out}-qc.prune.out") into pruned

    script: 
    base=bed.baseName
    // we use indep-pairwise as it is faster
    num=sample_num.text()
    //long num=num_sample.text()
    if(count < ${max_size}){
    """
    plink   --bfile ${base} \
            --extract ${qcsnp} \
            --keep ${qcfam} \
            --indep-pairwise ${wind_size} ${wind_step} ${wind_r2} \
            --out ${out}-qc 
    """
    }else{
    """
    plink   --bfile ${base} \
            --extract ${qcsnp} \
            --keep ${qcfam} \
            --indep-pairwise ${wind_size} ${wind_step} ${wind_r2} \
            --out ${out}-qc \
            --thin-indiv-count ${max_size} \
            --seed ${seed}
    """
    }

}