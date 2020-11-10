# Phenotype extraction - Plain text
Compared to using the SQL database, extracting phenotypes from .tab files requires only basic knowledge of `grep` and `awk`. Other programming languages such as R or python can also be used for more 'sophisticated' phenotype extractions.

In this section, we provide a step by step tutorial of **1.** how to extract a phenotype from the .tab file (Basic usage), **2.** how to incorporate data coding to the phenotyes of interest, and **3.** how to extract phenotypes from Health Records Linkage data using the ICD codes.

!!! important
    We assume the UK biobank application folder follows [our proposed structure](../../admin/master_generation/#expected-result).

## Example 1: Basic usage

In the 'Basic usage' section, we present an example on how to extract the first instance of the phenotype 'Height' (f.50.0.0) from UK Biobank.

1. Go into `phenotype/raw/`. Inside that folder, you will see two types of files: ukbXXXXX.tab and ukbXXXXX.field_finder.

	- **ukbXXXXX.field_finder** contains the field information (f.XXXXX.X.X) and the description of the field (i.e. Standing.height).
	- **ukbXXXXX.tab** contains the phenotype information for each individual (each individual is one row), and the field codes are the variable names.

2. Search for the phenotype of interest in the field_finder files using `grep`. For example, if your phenotype of interest is height, you should grep the word [Hh]eight across all the ".field_finder" files in the raw folder:

    ```bash
    grep [Hh]eight *.field_finder
    ```
    For the example of height, you might see the following. 
 
    ```bash
    ukb12345.field_finder:32	f.50.0.0	Standing.height
    ukb12345.field_finder:33	f.50.1.0	Standing.height
    ukb12345.field_finder:34	f.50.2.0	Standing.height
    ukb12345.field_finder:35	f.50.3.0	Standing.height
    ukb23456.field_finder:36	f.51.0.0	Seated.height
    ukb23456.field_finder:37	f.51.1.0	Seated.height
    ukb23456.field_finder:38	f.51.2.0	Seated.height
    ukb23456.field_finder:39	f.51.3.0	Seated.height
    ```
    
    The output indicates that in the tab file **ukb12345.tab**, columns 32 to 35 contain information about the field f.50.X.X. which represents 'Standing.height'. 

    To extract the first instance  measurement of standing height *(f.50.0.0)*, we will want to extract the column `32` from `ukb12345.tab`

    !!! note 
        You will not see the `ukbxxxxx.field_finder` prefix if there is only one set of phenotype in your folder
        
3. Extract the phenotype from the text file, assuming the first column contains the sample ID
    ```bash
    awk '{print $1,$32}' ukb12345.tab > height.txt
    ```

    !!! Warning
        It is possible that the phenotype ordering within the phenotype file might change between updates.
        Thus it is important to check that the column index of the phenotype is correct when repeating the analysis.

## Example 2: Phenotypes with data-coding

In the 'Phenotypes with data-coding' section, we present an example of a field with categorical values, encoded by UK Biobank. 

The example consists on extracting the question "*How many periods did you have in your life lasting two or more weeks where you felt like this?"* (f.20442.0.0). This question was included in the Mental health questionnaire of the [Online follow-up](https://biobank.ctsu.ox.ac.uk/crystal/label.cgi?id=100089) and contains numerical information (the number of depressed periods), but also some values with special meanings (i.e. -818 means *"Prefer not to answer"*, and -999 means *"Too many to count/One episode ran into the next"*).
 

The first steps are similar to the basic usage example:

1. Go into `phenotype/raw/`.
2. Search for the phenotype of interest in the field_finder files using `grep`

    ```
    grep depressed.periods *.field_finder 
    
    ukb12345.field_finder:41	f.20442.0.0	Lifetime.number.of.depressed.periods
    ukb98765.field_finder:2409	f.20442.0.0	Lifetime.number.of.depressed.periods
    ```

    !!! Note 
        Sometimes different .tab files will contain the same field. That's why there is more than one ukbXXXXX file with the field f.20442.0.0
	
3. Extract the phenotype from the text file, assuming the first column contains the sample ID

    ```
	awk '{print $1,$2409}' ukb98765.tab > ndep_episodes.txt
    ```

4. The special values and its meaning are stored in a different database, so you will need to **manually** check the data coding for each field you use. For this example, [data coding 511](https://biobank.ctsu.ox.ac.uk/crystal/coding.cgi?id=511) was used. 

    To replace the values with special meaning using R:

    ```
    data = read.table(file="ndep_episodes.txt", h=T)

    data$f.20442.0.0 = ifelse(f.20442.0.0 == -999, "Too_many/runnning_episodes", 
							ifelse(f.20442.0.0 == -818, "Prefer_not_to_answer", f.20442.0.0)
    ```

You can replace the value of special meanings in a more systematic/reproducible way using the [SQL approach.](./understand_sql.md) 

## Example 3: Phenotypes from Health Records Linkage 

In the 'Phenotypes from Health Records Linkage' section, we present an example on how to extract information from Health Records, using the ICD-10 coding and HESIN tables.

In this example, we will use R code to ascertain those individuals who were give a diagnosis of schizophrenia disorders ([F20 Category](https://biobank.ctsu.ox.ac.uk/crystal/field.cgi?id=41270) in the ICD-10).

    # 1. Read Hospital In-patient episodes data
    main_hesin_ICD10 = read.table(file=ukbXXXX.hesin.tsv", h=T, sep = "\t", fill = T)
    hesin_diag_ICD10 = read.table(file="ukbXXXXX.hesin_diag10.tsv", h=T, sep = "\t", fill = T)

    # 2. Create string with the ICD-10 codes for schizophrenia (F20)
    ICD10scz = c('F200','F201','F202','F203','F204','F205','F206','F208','F209')

    # 3. Find the rows in hesin_tables that contain F20 codes. Returns a boolean matrix where each column is one row from main_hesin_ICD10
    HES_scz_main = apply(main_hesin_ICD10, 1, function(row) ICD10scz %in% row)
    HES_scz_diag = apply(secondary_hesin, 1, function(row) ICD10scz %in% row)

    # 4. Loop over the rows of your full dataset (my_ukbXXXXX_data) and assign 1 to those individuals in my_ukbXXXXX_data that are in HES_scz_main or HES_scz_diag 
    HES_main_secondary = numeric()
    for(indiv in 1:dim(my_ukbXXXXX_data)[1]){
          HES_main_secondary[indiv] = ifelse(any(HES_scz_main[(((indiv-1)*length(ICD10scz))+1):(indiv*length(ICD10scz))] | 
                                       HES_scz_secondary[(((indiv-1)*length(ICD10scz))+1):(indiv*length(ICD10scz))]), 
                                     1, 0)}

    data$with_scz[c(HES_main_secondary==1)] = 1

    # Detail on the loop:
    # Indexes start from "(indiv-1*length(antipsychotics))+1)" = 0 to "(indiv*length(antipsychotics))" =  46 
    # Operator ":" means From .... To
