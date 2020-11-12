nextflow.preview.dsl=2
params.version=false
params.help=false
version='0.0.2'
timestamp='2020-10-29'
if(params.version) {
    System.out.println("")
    System.out.println("Prepare UK biobank data - Version: $version ($timestamp)")
    exit 1
}
// default values
params.geno = 0.02
params.seed = 1234
params.kmean = 4
params.hwe = 1e-8
params.maf = false
params.mac = false
params.build = "grch37"
params.windSize = 200
params.windStep = 50
params.r2 = 0.2
params.maxSize = 10000
params.sex = "sd"
params.sexSD = 3
params.maleF = 0.8
params.femaleF = 0.2
params.thres = 0.044
// NOTE: This script works on single genotype file. We need one that's not separated by chromosome
if(params.help){
    System.out.println("")
    System.out.println("Prepare UK biobank data - Version: $version ($timestamp)")
    System.out.println("(C) 2020 Shing Wan (Sam) Choi")
    System.out.println("MIT License")
    System.out.println("Usage: ")
    System.out.println("    nextflow run prepare_ukb.nf [options]")
    System.out.println("File inputs:")
    System.out.println("    --bfile     Prefix to genotype file")
    System.out.println("    --code      Path to Code showcase")
    System.out.println("    --conv      Path to ukbconv executable")
    System.out.println("    --data      Path to Data showcase")
    System.out.println("    --drop      File contain ID for drop out individuals")
    System.out.println("    --drug      File containing prescription record")
    System.out.println("    --encoding  Path to encoding.ukb")
    System.out.println("    --encrypt   Path to folder containing encrypted files")
    System.out.println("    --gp        File containing the GP record")
    System.out.println("    --greed     Path to GreedyRelated executable")
    System.out.println("    --key       Path to folder containing decryption keys")
    System.out.println("    --rel       Path to relatedness file")
    System.out.println("    --sql       Path to ukb_sql executable")
    System.out.println("    --unpack    Path to ukbunpack executable")
    System.out.println("Filtering parameters:")
    System.out.println("    --geno      Genotype missingness. Default: ${params.geno}")
    System.out.println("    --kmean     Number of kmean for pca clustering. Default: ${params.kmean}")
    System.out.println("    --maf       MAF filtering. Default: 0.01 if --mac not provided")
    System.out.println("    --mac       MAC filtering.")
    System.out.println("    --hwe       HWE filtering. Default: ${params.hwe}")
    System.out.println("    --build     Genome build. Can either be grch37 or grch38. ")
    System.out.println("                Use to define long LD regions. Default: ${params.build}")
    System.out.println("    --windSize  Window size for prunning. Default: ${params.windSize}")
    System.out.println("    --windStep  Step size for prunning. Default: ${params.windStep}")
    System.out.println("    --r2        Threshold for prunning. Default: ${params.r2}")
    System.out.println("    --maxSize   Maxnumber of samples used for prunning. Default: ${params.maxSize}")
    System.out.println("    --sex       sd or fix.")
    System.out.println("                sd: exclude samples N sd away from mean, as defined by --sexSD")
    System.out.println("                fix: exclude male > --maleF and female < --femaleF")
    System.out.println("                Default: ${params.sex}")
    System.out.println("    --sexSD     Sample with Fstat X SD higher (female)/ lower(male) ")
    System.out.println("                from the mean are filtered. Default: ${params.sexSD}")
    System.out.println("    --maleF     F stat threshold for male. Male with F stat lower")
    System.out.println("                than this number will be removed. Default: ${params.maleF}")
    System.out.println("    --femaleF   F stat threshold for female. Female with F stat higher")
    System.out.println("                than this number will be removed. Default: ${params.femaleF}")
    System.out.println("    --relThres  Threshold for removing related samples. Default: ${params.thres}")
    System.out.println("Options:")
    System.out.println("    --thread  Number of thread use")
    System.out.println("    --seed    Seed for random algorithms. Default: ${params.seed}")
    System.out.println("    --help    Display this help messages")
    exit 1
}
// include the modules 
include {   construct_sql; 
            decrypt_files; 
            encode_files;
            generate_field_finder;
            outliers_aneuploidy;
            extract_batch;
            extract_pcs;
            extract_biological_sex;
            generate_covariates    } from './modules/phenotype_processing'
include {   get_software_version;
            combine_meta;
            write_log    } from './modules/misc.nf'
include {   extract_eur;
            remove_dropout_and_invalid;
            basic_qc;
            generate_high_ld_region;
            prunning;
            calculate_stat_for_sex;
            filter_sex_mismatch;
            finalize_data;
            relatedness_filtering;
            extract_first_degree; } from './modules/quality_control.nf'

// function to check if file exists
def fileExists = { fn ->
   if (fn.exists())
       return fn;
    else
       error("\n\n-----------------\nFile $fn does not exist\n\n---\n")
}
// load all common files 
code_showcase=Channel.fromPath("${params.code}")
data_showcase=Channel.fromPath("${params.data}")
drug=Channel.fromPath("${params.drug}")
encoding=Channel.fromPath("${params.encoding}")
genotype = Channel
            .fromFilePairs("${params.bfile}.{bed,bim,fam}",size:3, flat : true){ file -> file.baseName }  
            .ifEmpty { error "No matching plink files" }        
            .map { a -> [fileExists(a[1]), fileExists(a[2]), fileExists(a[3])] } 
gp=Channel.fromPath("${params.gp}")
greedy=Channel.fromPath("${params.greed}")
rel = Channel.fromPath("${params.rel}")            
ukbconv = Channel.fromPath("${params.conv}")
ukbsql=Channel.fromPath("${params.sql}")
ukbunpack = Channel.fromPath("${params.unpack}")
withdrawn=Channel.fromPath("${params.drop}")


// main workflow
workflow{
    // 1. check program version
    check_version()
    // 2. Decrypt the UKB files
    extract_ukb_pheno()
    // 3. Construct the SQL file
    build_sql(extract_ukb_pheno.out.pheno)
    // 4. Perform the QC filtering
    plink_qc(build_sql.out)
    // 5. Generate the log file

    generate_log(   check_version.out.version_info, 
                    plink_qc.out.qc_info)
}

workflow check_version{
    main:
        software = greedy \
            | combine(ukbsql) 
        get_software_version(params.out, software.collect())
    emit:
        version_info=get_software_version.out
}

workflow extract_ukb_pheno{
    main:
        encrypt = Channel.fromPath("${params.encrypt}/*")
            .flatten()
            .map{ file -> tuple(file.getBaseName(), file)}
        keys = Channel.fromPath("${params.key}/*") 
            .flatten()
            .map{ file -> tuple(file.getBaseName(), file)} 
        keys \
            | join(encrypt, by: [0]) \
            | combine(ukbunpack) \
            | decrypt_files \
            | combine(encoding) \
            | combine(ukbconv) \
            | encode_files
        encode_files.out.phenotype \
            | combine(data_showcase) \
            | generate_field_finder
    emit:
        pheno=encode_files.out.phenotype
        field=generate_field_finder.out
}

workflow build_sql{
    take: phenotypes
    main:
        construct_sql(  ukbsql, 
                        code_showcase, 
                        data_showcase, 
                        withdrawn, 
                        gp, 
                        drug, 
                        params.out, 
                        phenotypes.collect())
    emit:
        sql=construct_sql.out
}

workflow plink_qc{
    take: sql
    main:
        // 1. Extract ID of samples with excessive relatedness, excessive heterozygousity and missingness
        //    or sex aneuploidy       
        outliers_aneuploidy(sql, "${params.out}")
        // 2. Extract genotyping batch information from the sql
        //    we don't extract centre as assessment centre changed depending on instance
        extract_batch(sql, "${params.out}")
        // 3. Extract all the PCs
        extract_pcs(sql, "${params.out}")
        // 4. Generate the covariate file
        generate_covariates(extract_batch.out, extract_pcs.out, "${params.out}")
        // 5. Extract self reported sex
        extract_biological_sex(sql, "${params.out}")
        // 6. Do 4 mean clustering to extract EUR samples
        extract_eur(    generate_covariates.out, 
                        params.kmean, 
                        params.seed, 
                        params.out)
       
        // 7. Now remove all drop outs and samples that failed the UK Biobank QC
        remove_dropout_and_invalid( genotype, 
                                    outliers_aneuploidy.out.outliers, 
                                    withdrawn, 
                                    params.out)
        // 8. Need to account for either using maf or mac filtering
        maf = params.maf
        if(!params.maf && !params.mac){
            // if both not provided, use default value
            maf = 0.01
        }
        maf_mac=""
        if(maf){
            maf_mac=maf_mac+" --maf "+maf
        }      
        if(params.mac){
            maf_mac=maf_mac+" --mac "+params.mac
        }
        // 9. Run the second pass QC with --geno --maf/--mac --hwe and sample filtering
        basic_qc(   genotype, 
                    extract_eur.out.eur, 
                    remove_dropout_and_invalid.out.removed, 
                    params.hwe, 
                    params.geno, 
                    maf_mac, 
                    params.out)
        // 10. Generate the file indicating the long LD region
        generate_high_ld_region(    basic_qc.out.qc, 
                                    genotype, 
                                    params.build, 
                                    params.out)
        // 11. Perform prunning
        prunning(   genotype,
                    basic_qc.out.qc, 
                    generate_high_ld_region.out, 
                    params.windSize,
                    params.windStep,
                    params.r2,
                    params.maxSize,
                    params.seed,
                    params.out)
        // 12. Perform sex check (on top of UKB pipeline just in case)
        calculate_stat_for_sex( genotype,
                                basic_qc.out.qc,
                                prunning.out,
                                params.out)
        // 13. Remove samples with mismatch genetic and reported sex                        
        filter_sex_mismatch(    basic_qc.out.qc, 
                                calculate_stat_for_sex.out,
                                extract_biological_sex.out,
                                params.sex,
                                params.sexSD,
                                params.maleF,
                                params.femaleF,
                                params.out)
        // 14. Use Greedy related to remove related samples            
        relatedness_filtering(  greedy, 
                                rel,
                                filter_sex_mismatch.out.valid,
                                params.thres,
                                params.seed,
                                params.out)
        // 15. Also extract first degree samples on the side                        
        extract_first_degree(   filter_sex_mismatch.out.valid,
                                rel,
                                relatedness_filtering.out.removed,
                                params.out )
        // 16. Generate the finalized SNP and fam file
        finalize_data(  genotype,
                        basic_qc.out.qc, 
                        filter_sex_mismatch.out.mismatch,
                        relatedness_filtering.out.removed, 
                        params.out)
        // 17. We want to gather the filtering statistic
        qc_information = outliers_aneuploidy.out.meta \
            | combine(remove_dropout_and_invalid.out.meta) \
            | combine(basic_qc.out.meta) \
            | combine(extract_eur.out.meta) \
            | combine(filter_sex_mismatch.out.meta) \
            | combine(relatedness_filtering.out.meta) \
            | combine(extract_first_degree.out.meta) \
            | combine(finalize_data.out.meta) 
        combine_meta(params.out, qc_information.collect())
    emit: 
        qc_info = combine_meta.out
}

workflow generate_log {
    take: version
    take: qc_info
    main:
        write_log(version, qc_info, params.out)
    emit:
        write_log.out
}
