# Using the SQL database
In this section, we will try to understand the basics of the UK Biobank phenotype database, and how to use it. 

!!! note

    To access the database, you must have [sqlite3](https://sqlite.org/index.html) installed. 

## Database Structure 
To use the SQL database we must first understand the basic structure of the database. 
The SQL database contains one table for each phenoytpe, with name of `fxxxx` where `xxxx` is the field ID of the phenotype. 
In addition, there are some core data table that provide basic information regarding the UK Biobank phenotypes and the current application.
Below are the detail descriptions of different data tables presented within our SQL database:

<table>
<th colspan="4">
Participant
</th>
<tr>
    <td>sample_id</td>
    <td>ID of UKB Samples</td>
    <td>int</td>
    <td>primary key</td>
</tr>
<tr>
    <td>withdrawn</td>
    <td>Number represent if sample withdrawn consent. 1 for yes, 0 for no</td>
    <td>int</td>
    <td></td>
</tr>
<th colspan="4">
fxxxx (where xxxx is the field ID of the phenotype)
</th>
<tr>
    <td>sample_id</td>
    <td>ID of UKB Samples</td>
    <td>int</td>
    <td>primary key</td>
</tr>
<tr>
    <td>pheno</td>
    <td>The phenotype</td>
    <td>text</td>
    <td></td>
</tr>
<tr>
    <td>instance</td>
    <td>0 for baseline measurement, 1 for first follow up, so and so forth</td>
    <td>int</td>
    <td></td>
</tr>
<tr>
    <td>array</td>
    <td>0 for first reported item, 1 for the second, so and so forth. This field is only presented for phenotypes that allow multiple input</td>
    <td>int</td>
    <td></td>
</tr>
<th colspan="4">
code
</th>
<tr>
    <td>code_id</td>
    <td>Data-coding ID</td>
    <td>int</td>
    <td>primary key</td>
</tr>
<th colspan="4">
code_meta
</th>
<tr>
    <td>code_id</td>
    <td>Data-coding ID</td>
    <td>int</td>
    <td>foreign key (code:code_id)</td>
</tr>
<tr>
    <td>value</td>
    <td>The Data-coding</td>
    <td>int</td>
    <td></td>
</tr>
<tr>
    <td>meaning</td>
    <td>Meaning of the Data-coding</td>
    <td>text</td>
    <td></td>
</tr>
<th colspan="4">
data_meta
</th>
<tr>
    <td>category</td>
    <td>Category ID</td>
    <td>int</td>
    <td></td>
</tr>
<tr>
    <td>field_id</td>
    <td>Unique Field ID</td>
    <td>int</td>
    <td>primary key</td>
</tr>
<tr>
    <td>field</td>
    <td>Description of the field</td>
    <td>TEXT</td>
    <td></td>
</tr>
<tr>
    <td>participants</td>
    <td>Number of participant with this phenotype</td>
    <td>int</td>
    <td></td>
</tr>
<tr>
    <td>items</td>
    <td>Number of items in this phenotype</td>
    <td>int</td>
    <td></td>
</tr>
<tr>
    <td>stability</td>
    <td>Indicate if this phenotype is table</td>
    <td>text</td>
    <td></td>
</tr>
<tr>
    <td>value_type</td>
    <td>Indicate the type of phenotype</td>
    <td>text</td>
    <td></td>
</tr>
<tr>
    <td>units</td>
    <td>The units of which the phenotype is measured in (if any)</td>
    <td>text</td>
    <td></td>
</tr>
<tr>
    <td>item_type</td>
    <td>Type of items, e.g. data, bulk, etc.</td>
    <td>text</td>
    <td></td>
</tr>
<tr>
    <td>strata</td>
    <td>e.g. Primary, auxiliary</td>
    <td>text</td>
    <td></td>
</tr>
<tr>
    <td>sexed</td>
    <td>Inidicate if this phenotype is only measured in male, female, or is unisex</td>
    <td>text</td>
    <td></td>
</tr>
<tr>
    <td>instances</td>
    <td>Indicate the number of repeated measure for this phenotype</td>
    <td>int</td>
    <td></td>
</tr>
<tr>
    <td>array</td>
    <td>For phenotype that allow multiple responses (e.g. ICD10), this indicate the maximum number of response. </td>
    <td>int</td>
    <td></td>
</tr>
<tr>
    <td>coding</td>
    <td>Data-coding used for this phenotype</td>
    <td>int</td>
    <td>foreign (code:code_id)</td>
</tr>
<tr>
    <td>included</td>
    <td>If this application has permission to access this phenotype. 1 = "yes"</td>
    <td>int</td>
    <td></td>
</tr>
</table>

## Using the SQL database
Basic understand of the SQL language is required to efficiently use our SQL database. 
We recommend one to write down the SQL commands in a `.sql` file and use the SQL database as follow
```bash
sqlite3 ukb<ID>.db < command.sql
```
where `command.sql` is the sql command file containing the following header
``` sqlite
.header on
.mode csv
.output <name>.csv
```

Below are some examples of how to use the SQL database

=== "Basic usage"
    ``` sql
    .header on
    .mode csv
    -- Output to file named Height.csv
    .output Height.csv 
    SELECT  s.sample_id AS FID, 
            s.sample_id AS IID,
            age.pheno AS Age,
            sex.pheno AS Sex,
            bmi.pheno AS BMI,
            centre.pheno AS Centre
    FROM    Participant s 
            JOIN    f21001 bmi ON 
                    s.sample_id=bmi.sample_id       -- join the BMI table by sample ID
                    AND bmi.instance = 0            -- only getting the baseline phenotype
            JOIN    f31 sex ON
                    s.sample_id=sex.sample_id       -- join the Sex table by sample ID
                    AND sex.instance = 0            -- only getting the baseline phenotype
            JOIN    f21003 age ON 
                    s.sample_id=age.sample_id       -- join the Age table by sample ID
                    AND age.instance = 0            -- only getting the baseline phenotype
            JOIN    f54 centre ON 
                    s.sample_id=centre.sample_id    -- join the UKB assessment centre table by sample ID
                    AND centre.instance = 0         -- only getting the baseline phenotype
            WHERE   s.withdrawn = 0;                -- Exclude any samples who withdrawn their consent
    .quit

    ```

=== "Use data-coding"
    ``` sql
    .header on
    .mode csv    
    -- Output to file named NumDepress.csv 
    .output NumDepress.csv 

    -- First, we build the phenotype code table
    CREATE TEMP TABLE pheno_code
    AS
    SELECT  cm.value AS value,
            cm.meaning AS meaning
    FROM    code_meta cm
    JOIN    data_meta dm on          
            dm.field_id=20442 AND   -- Extract the Field correspond to phenotype from data meta
            dm.coding = cm.code_id; -- Extract the data coding (value and meaning) for this phenotype


    SELECT  s.sample_id AS FID,
            s.sample_id AS IID,
            (CASE WHEN depress.pheno IN           -- If phenotype is found in data coding
                (
                    SELECT value 
                    FROM pheno_code
                )
            THEN  
            (
                SELECT meaning 
                FROM pheno_code 
                WHERE value = depress.pheno         -- Return the meaning as phenoytpe
            )
            ELSE depress.pheno                      -- Otherwise, return the phenotype code directly
            END) AS Pheno
    FROM    Participant s
            JOIN f20442 depress ON 
            s.sample_id=depress.sample_id
            AND depress.instance = 0                -- only select the baseline measurement
    WHERE   s.withdrawn = 0;
    .quit
    ```

=== "ICD10 example"
    ```sql
    .header on
    .mode csv    
    -- Output to file named scz.csv 
    .output scz.csv 
    -- First, extract all SCZ patients
    CREATE TEMP TABLE scz
    AS
    SELECT  DISTINCT sample_id
    FROM    f41270
    WHERE   pheno LIKE '"F20_"' -- select any samples with phenotype starts with "F20X". 
            AND instance = 0;   -- only use baseline
  
    SELECT  s.sample_id AS FID, 
            s.sample_id AS IID,
            (CASE WHEN s.sample_id IN
                (
                    SELECT  sample_id
                    FROM    scz
                )
                THEN 1          -- samples found in scz table are cases (1)
                ELSE 0
            END) AS Pheno
    FROM    Participant s 
    WHERE   s.withdrawn= 0;     -- Exclude any samples who withdrawn their consent
    .quit
    ```

!!! Note
    There are two wildcards used in conjunction with the `LIKE` operator −

    - The percent sign (`%`): 0, 1 or multiple numbers of characters
    - The underscore (`_`)  : single number of character

    For ICD10, remember to include the double quotes: `'"XXXX"'`

