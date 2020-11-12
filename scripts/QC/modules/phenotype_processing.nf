
// This process will construct the required SQL database. 
// Ideally we should use move mode, but we want to obtain the 
// sqc information. So we need to keep the database for later process
process construct_sql{
    publishDir "phenotype" , mode: 'copy', overwrite: true
    module 'cmake'
    time '24h'
    queue 'premium' 
    cpus '1'
    memory '20G'
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
        --out ${out}.db \
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
    executor 'lsf'
    cpus '1'
    memory '10G'
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

process extract_batch{
    // We don't extract centre as the centre can change depending on the instance
    label 'normal'
    input:
        path(db)
        val(out)
    output:
        path("${out}.batch")
    script:
    """
    echo "
    .mode csv
    .header on
    .output ${out}.batch
    CREATE TEMP TABLE batch_code
    AS
    SELECT  cm.value AS value,    
            cm.meaning AS meaning 
    FROM    code cm               
    JOIN    data_meta dm ON 
            dm.code_id=cm.code_id
    WHERE   dm.field_id=22000;    
    SELECT      s.sample_id AS FID,
                s.sample_id AS IID,
                COALESCE(
                    batch_code.meaning, 
                    batch.pheno) AS Batch
    FROM        f22000 batch
    JOIN        Participant s
    LEFT JOIN   batch_code ON        
                batch_code.value = batch.pheno
    WHERE       batch.instance=0 AND
                s.sample_id = batch.sample_id AND
                s.withdrawn = 0;
    .quit
        " > sql;
    sqlite3 ${db} < sql
    """
}

process generate_covariates{
    publishDir "phenotype", mode: 'copy', overwrite: true
    module 'R'
    label 'normal'
    input:
        path(batch)
        path(pca)
        val(out)
    output:
        path("${out}.covar")
    script:
    """
    #!/usr/bin/env Rscript
    library(data.table)
    library(magrittr)
    pcs <- fread("${pca}")
    batch <- fread("${batch}")
    pca <- dcast(pcs, FID+IID~Num, value.var="PCs")
    setnames(pca, as.character(c(1:40)), c(paste0("PC",1:40)))
    merge(batch, pca, by = c("FID", "IID")) %>%
        na.omit %>%
        .[, Batch := gsub("\\"", "", Batch)] %>%
        fwrite(., "${out}.covar", sep="\\t")
    """
}


process extract_biological_sex{
    // We don't extract centre as the centre can change depending on the instance
    label 'normal'
    input:
        path(sql)
        val(out)
    output:
        path("${out}.bioSex")
    script:
    """
    echo "
    .mode csv
    .header on
    .output ${out}.bioSex
    
    SELECT      s.sample_id AS FID,
                s.sample_id AS IID,
                sex.pheno AS Sex
    FROM        Participant s
    JOIN        f31 sex ON
                sex.instance = 0 AND
                sex.sample_id = s.sample_ID
    WHERE       s.withdrawn = 0;
    .quit
        " > sql;
    sqlite3 ${sql} < sql
    """
}
process extract_pcs{
    // We don't extract centre as the centre can change depending on the instance
    label 'normal'
    input:
        path(sql)
        val(out)
    output:
        path("${out}.pcs")
    script:
    """
    echo "
    .mode csv
    .header on
    .output ${out}.pcs
    
    SELECT      s.sample_id AS FID,
                s.sample_id AS IID,
                pca.pheno AS PCs,
                pca.array AS Num
    FROM        Participant s
    JOIN        f22009 pca ON
                pca.instance = 0 AND
                pca.sample_id = s.sample_ID
    WHERE       s.withdrawn = 0;
    .quit
        " > sql;
    sqlite3 ${sql} < sql
    """
}
process outliers_aneuploidy{
    publishDir "phenotype", mode: 'copy', overwrite: true, pattern: "*outliers"
    label 'normal'
    input:
        path(db)
        val(out)
    output:
        path "${out}.outliers", emit: outliers
        path "${out}-het.meta", emit: meta
    script:
    """
    echo "
    .mode csv
    .header on
    .output ${out}.outliers
    CREATE TEMP TABLE problematic
    AS
    SELECT DISTINCT sample_id 
    FROM(
        SELECT  sample_id
        FROM    f22019 aneuploidy 
        WHERE   aneuploidy.pheno = 1 AND
                aneuploidy.instance = 0
        UNION 
        SELECT  sample_id
        FROM    f22027 outlier 
        WHERE   outlier.pheno = 1 AND
                outlier.instance = 0
    )as subquery;

    SELECT  s.sample_id AS FID,
            s.sample_id AS IID
    FROM    Participant s
    JOIN    problematic ON
            s.sample_id = problematic.sample_id AND
            s.withdrawn = 0;
    .quit
        " > sql;
    sqlite3 ${db} < sql
    num=`wc -l ${out}.outliers | cut -f 1 -d  " "`
    res=\$((num-1))
    echo "1. \${res} sample(s) with excessive het or missingness, or have aneuploidy sex according to uk biobank" > ${out}-het.meta
    """
}
