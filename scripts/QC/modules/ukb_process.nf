
// This process will construct the required SQL database. 
// Ideally we should use move mode, but we want to obtain the 
// sqc information. So we need to keep the database for later process
process construct_sql{
    publishDir "phenotype" , mode: 'copy', overwrite: true
    module 'cmake'
    time '12h'
    cpus '1'
    memory '100G'
    executor 'lsf'
    input:
        path(ukb_process)
        path(code_showcase)
        path(data_showcase)
        path(withdrawn) 
        path(gp) 
        path(drug)
        val(out)
        path(pheno)
    output:
        path "${out}.db", emit: database
    script:
    """
    phenotype=""
    function join_by { local IFS="\$1"; shift; echo "\$*"; }
    # Larger number in file name usually represent later version
    pheno_list=`ls ${pheno} | sort -Vr | awk '{printf \$0" "}END{print ""}'`
    phenotype=`join_by , \${pheno_list}`
    ./${ukb_process} \
        -d ${data_showcase} \
        -c ${code_showcase} \
        -p \${phenotype} \
        --out ${out} \
        -g ${gp} \
        -u ${drug} \
        -D \
        -m 10737418240  \
        -r \
        -w ${withdrawn}
    """
}

// This process will decrypt ukbiobank phenotype file with ukbunpack and the key provided
process decrypt_files{
    input:
        tuple   val(data_id),
                path(key),
                path(encrypted),
                path (ukbunpack)
    output:
        tuple   val(data_id), 
                path("${data_id}.enc_ukb")
    script:
    """
    ./${ukbunpack} ${encrypted} ${key}
    """
}

// This process will convert the decrypted ukbiobank phenotype file into accepted format
process encode_files{
    publishDir "phenotype/raw", mode: 'copy', overwrite: true
    input:
        tuple   val(data_id),
                path(decrypted),
                path(encoding),
                path(ukbconv)
    output:
        path "${data_id}.tab", emit: phenotype
    script:
    """
    ./${ukbconv} ${decrypted} r -e${encoding}
    """
}

// This process will take the data showcase file, and the phenotype file to generate the 
// field finder
process generate_field_finder{
    publishDir "phenotype/raw", mode: 'copy', overwrite: true
    module 'R'
    input:
        tuple   path(pheno),
                path(data_showcase)
    output:
        path("${data_id}.field_finder")
    script:
    data_id=pheno.getBaseName()
    """
    #!/usr/bin/env Rscript
    library(data.table)
    library(magrittr)
    con <- file("${pheno}", "r")
    file.fields <- readLines(con, n=1) %>%
        strsplit(., split="\\t") %>% 
        unlist %>%
        data.table(Input=.) %>%
        .[,FieldID:=sapply(Input, function(x){
                strsplit(x, split="\\\\.") %>%
                unlist %>%
                head(n=2) %>%
                tail(n=1)
            })] %>% 
        .[,Instance:=sapply(Input, function(x){
                strsplit(x, split="\\\\.") %>%
                unlist %>%
                head(n=3) %>%
                tail(n=1)
            })] %>%
        .[,Array:=sapply(Input, function(x){
                tmp <- strsplit(x, split="\\\\.") %>%
                    unlist 
                if(length(tmp)<4){
                    return(NA)
                }else{
                    tail(tmp, n=1) %>%
                        return
                }
            })]
    close(con)
    showcase <- fread("${data_showcase}") %>%
        .[,c("FieldID", "Field")] %>%
        .[,Field:=gsub(" ", ".", Field)] %>%
        .[,Field:=gsub(",", "", Field)] %>%
        .[,FieldID:=as.character(FieldID)]
    res <- showcase[file.fields, on="FieldID"]
    res[,Line:=1:.N]
    fwrite(res[,c("Line", "FieldID", "Instance", "Array", "Field")], 
        "${data_id}.field_finder",
        na="NA", 
        sep="\\t", 
        quote=F)
    """
}