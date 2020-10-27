# Using UK Biobank showcase data

The best way to get familiar with the data available in UK Biobank is to browse their [data showcase](https://biobank.ctsu.ox.ac.uk/crystal/browse.cgi). You can also [search](http://biobank.ctsu.ox.ac.uk/crystal/search.cgi) for specific fields or keywords.

## Main dataset - General overview

A main, single UKB dataset containing all the fields included in the approved application can be a very large file (17-70GB depending on file extension) not efficient to work with. Therefore, the UK Biobank data available in Minerva is split in multiple, smaller .tab files. *For each .tab file, each individual is a row, and the field codes are the variable names* (in the format f.XXXXX.X.X). 
The individual IDs are coded in the field “f.eid” and are application specific (individual’s id numbers will be different for each application).

<center>

| f.eid   | f.22040.<span style="color:red">0.0.</span> | f.42038.<span style="color:red"> 0.0. </span> | f.42037.<span style="color:red"> 0.0. </span> |
|---------|---------------------------------------------|-----------------------------------------------|-----------------------------------------------|
| 5967229 | NA                                          | 1                                             | 23                                            |
| 4674807 | NA                                          | NA                                            | NA                                            |
| 1456203 | 3330                                        | 2                                             | 575                                           |
| 3723112 | NA                                          | 1                                             | 380                                           |

</center>

Highlighted <span style="color:red">in red</span> are the instance and array codes from the UKB field codes. These two numbers are separated by a dot e.g. variable.instance.array.
**Instance** refers the assessment instance (or visit). **Array** captures multiple answers to the same "question". See UKB documentation for detailed descriptions of [instance](https://biobank.ctsu.ox.ac.uk/crystal/instance.cgi?id=2) and [array](https://biobank.ctsu.ox.ac.uk/crystal/help.cgi?cd=array).


Let’s see two examples, one where a field has multiple instances, and another example where a field has multiple arrays. 

*Example of field with multiple instances:* Standing height (field number 50) was measured 4 times. (For details, click [here](https://biobank.ndph.ox.ac.uk/showcase/field.cgi?id=50)). You will see the following in your .tab file:

<center>

| f.eid   | f.50.<span style="color:red">0.0.</span> | f.50.<span style="color:red">1.0.</span> | f.50.<span style="color:red">2.0.</span> | f.50.<span style="color:red">3.0.</span> |
|---------|------------------------------------------|------------------------------------------|------------------------------------------|------------------------------------------|
| 5967229 | 156                                      | 155                                      | 156                                      | 156                                      |
| 4674807 | 178                                      | 178                                      | 178                                      | 177                                      |
| 1456203 | 175                                      | 175                                      | 175                                      | 175                                      |
| 3723112 | 161                                      | 161                                      | 161                                      | 161                                      |

</center>


*Example of field with multiple arrays:* Information about treatment medication (field number 20003) was measured 4 times (so it has 4 instances). 
For each instance, participants indicated how many medications they were taking. Each medication would be recorded as a new item and will be stored as a new variable. 

The maximum number of items present for any participant will define how many variables the field. 
For treatment medication, there was a person who recorded 47 items, and therefore there are 47 variables per instance for this field.

<center>

| f.eid   | f.20003.0.1 | f.20003.0.2 | f. 20003.0.3 | …. | f. 20003.0.47 |
|---------|-------------|-------------|--------------|----|---------------|
| 5967229 | NA          | NA          | NA           | …. | NA            |
| 4674807 | 178         | 1754        | NA           | …. | NA            |
| 1456203 | 45          | NA          | NA           | …. | NA            |
| 3723112 | 1341        | 161         | 131          | …. | 14            |

</center>


## Health Record Linkage


### Hospital inpatient episodes

The Hospital inpatient episodes are divided into five tables. The master table is "hesin", which connects to four subsidiary tables (hesin_diag10, hesin_diag9, hesin_oper, hsin_birth) via the record_id key field

- *hesin:* Main table for hospital records, it contains all the primary information about each hospital episode, including the primary diagnosis (columns diag_icd10 or diag_icd9) and the primary operation (column oper4). Each record_id can appear only one time in this table.

- *hesin_diag10:* subsidiary table for hospital diagnoses, it contains all the secondary diagnoses coded in ICD-10 for each hospital episode. Each record_id can appear multiple times in this table. 

- *hesin_diag9:* subsidiary table for hospital diagnoses, it contains all the secondary diagnoses coded in ICD-90 for each hospital episode. Each record_id can appear multiple times iin this table.

- *hesin_oper:* subsidiary table for hospital operations, it contains all the secondary operations for each hospital episode. Each record_id can appear multiple times in this table. 

- *hesin_birth:* subsidiary table for hospital births, it contains all birth data for each hospital episode. Each record_id can appear multiple times in this table.

