# Phenotype extraction - Plain text
Compared to using the SQL database, extracting phenotypes from .tab files requires only basic knowledge of `grep` and `awk`. 
In this section, we provide a step by step tutoria of how to extract a phenotype from the .tab file.

!!! important
    We assume the UK biobank application folder follows [our proposed structure](../../admin/master_generation/#expected-result).

## Step by step guide
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
    
    The output indicates that in the tab file **ukb12345.tab**, columns 32 to 35 contain information about the field f.50.X.X. which represents 'Stainding.height'. 

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
