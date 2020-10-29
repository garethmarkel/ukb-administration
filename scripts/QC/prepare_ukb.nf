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
include {   relatedness_filtering;
            extract_first_degree } from './modules/greedy_related'
include {   construct_sql; 
            decrypt_files; 
            encode_files;
            generate_field_finder    } from './modules/ukb_process'
include {   get_software_version;
            combine_meta;
            write_log    } from './modules/misc.nf'
include {   extract_sqc;
            first_pass_geno;
            extract_eur;
            remove_dropout_and_invalid;
            basic_qc;
            generate_high_ld_region;
            prunning;
            calculate_stat_for_sex;
            filter_sex_mismatch;
            finalize_data } from './modules/plink_qc.nf'

// load all common files 
code_showcase=Channel.fromPath("${params.data}")
data_showcase=Channel.fromPath("${params.data}")
drug=Channel.fromPath("${params.drug}")
encoding=Channel.fromPath("${params.encoding}")
gp=Channel.fromPath("${params.gp}")
greedy=Channel.fromPath("${params.greed}")
ukbconv = Channel.fromPath("${params.conv}")
ukbsql=Channel.fromPath("${params.sql}")
ukbunpack = Channel.fromPath("${params.unpack}")
withdrawn=Channel.fromPath("${params.drop}")

// function to check if file exists
def fileExists = { fn ->
   if (fn.exists())
       return fn;
    else
       error("\n\n-----------------\nFile $fn does not exist\n\n---\n")
}

// main workflow
workflow{
    // 1. check program version
    check_version()
    // 2. Decrypt the UKB files
    extract_ukb_pheno()
    // 3. Construct the SQL file
    build_sql(extract_ukb_pheno.out.pheno)
    //plink_qc(build_workspace.out.greedy)
    //generate_log(check_version.out.version_info, plink_qc.out.qc_info)
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
    take: greedy
    main:
        sqc = Channel.fromPath("${params.sqc}")
        extract_sqc(sqc, "${params.out}")
        genotype = Channel
            .fromFilePairs("${params.bfile}.{bed,bim,fam}",size:3, flat : true){ file -> file.baseName }  
            .ifEmpty { error "No matching plink files" }        
            .map { a -> [fileExists(a[1]), fileExists(a[2]), fileExists(a[3])] } 
        first_pass_geno(    genotype, 
                            params.geno, 
                            params.out)
        extract_eur(    extract_sqc.out.covar, 
                        params.kmean, 
                        params.seed, 
                        params.out)
        remove_dropout_and_invalid( genotype, 
                                    extract_sqc.out.het, 
                                    withdrawn, 
                                    params.out)
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
        basic_qc(   genotype, 
                    first_pass_geno.out.snp, 
                    extract_eur.out.eur, 
                    remove_dropout_and_invalid.out.removed, 
                    params.hwe, 
                    params.geno, 
                    maf_mac, 
                    params.out)

        generate_high_ld_region(    basic_qc.out.qc, 
                                    genotype, 
                                    params.build, 
                                    params.out)
        prunning(   genotype,
                    basic_qc.out.qc, 
                    generate_high_ld_region.out, 
                    params.windSize,
                    params.windStep,
                    params.r2,
                    params.maxSize,
                    params.seed,
                    params.out)
        calculate_stat_for_sex( genotype,
                                basic_qc.out.qc,
                                prunning.out,
                                params.out)
                                
        filter_sex_mismatch(    basic_qc.out.qc, 
                                calculate_stat_for_sex.out,
                                extract_sqc.out.sex,
                                params.sex,
                                params.sexSD,
                                params.maleF,
                                params.femaleF,
                                params.out)
        rel = Channel.fromPath("${params.rel}")                        
        relatedness_filtering(  greedy, 
                                rel,
                                filter_sex_mismatch.out.valid,
                                params.thres,
                                params.seed,
                                params.out)
        extract_first_degree(   filter_sex_mismatch.out.valid,
                                rel,
                                relatedness_filtering.out.removed,
                                params.out )
        finalize_data(  genotype,
                        basic_qc.out.qc, 
                        filter_sex_mismatch.out.mismatch,
                        relatedness_filtering.out.removed, 
                        params.out)
        qc_information = extract_sqc.out.meta \
            | combine(first_pass_geno.out.meta) \
            | combine(remove_dropout_and_invalid.out.meta) \
            | combine(basic_qc.out.meta) \
            | combine(extract_eur.out.meta) \
            | combine(filter_sex_mismatch.out.meta) \
            | combine(relatedness_filtering.out.meta) \
            | combine(extract_first_degree.out.meta) \
            | combine(finalize_data.out.meta) 
        combine_meta(params.out, qc_information.collect())
    emit: 
        covar = extract_sqc.out.covar
        eur = extract_eur.out.eur
        pca = extract_eur.out.pca
        qced= finalize_data.out.qced
        family = extract_first_degree.out.family
        kinship = extract_first_degree.out.plot
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