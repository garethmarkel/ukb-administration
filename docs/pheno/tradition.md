# Using the plain text phenotypes
Comparing to the SQL database, exctracting phenotypes from the text files are simpler, require only basic knowledge of `grep` and `awk`. 
In this section, we provide a step by step example of extracting a phenotype from the text file.

!!! important
    We assume the UK biobank application folder follows [our proposed structure](../../admin/master_generation/#expected-result).

## Step by step guide
1. Go into `phenotype/raw/`
2. Search for the phenotype of interest in the field_finder files using `grep`
    ```bash
    grep [Hh]eight *.field_finder
    ```
    You might see the following:
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
    The format of the field finder file is as follow
    
    | Column Index | FieldID.Instance.Array | Phenotype name|
    |---|---|---|

    To select the baseline measurement of the standing height, we will want to extract the `32` column from `ukb12345.tab`

    !!! note 
        You will not see the `ukbxxxxx.field_finder` prefix if there is only one set of phenotype in your folder
3. Extract the phenotype from the text file, assuming the first column contains the sample ID
    ```bash
    awk '{print $1,$32}' ukb12345.tab > height.txt
    ```

    !!! Warning
        It is possible that the phenotype ordering within the phenotype file might change between updates.
        Thus it is important to check that the column index of the phenotype is correct when repeating the analysis.
