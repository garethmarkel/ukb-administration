# Understanding UK Biobank showcase data

The best way to get familiar with the data available in UK Biobank is to browse their [data showcase](https://biobank.ctsu.ox.ac.uk/crystal/browse.cgi). You can also [search](http://biobank.ctsu.ox.ac.uk/crystal/search.cgi) for specific fields or keywords.

## Main dataset

A main, single UKB dataset containing all the fields included in the approved application can be a very large file (17-70GB depending on file extension) not efficient to work with. Therefore, the UK Biobank data available in Minerva is split in multiple, smaller .tab files.

For each .tab file, each individual is a row, and the field codes are the variable names (in the format *f.XXXXX.X.X*). 
The individual IDs are coded in the field “f.eid” and are application specific (Note that individual’s id numbers will be different for each application).

<center>

| f.eid   | f.22040.<span style="color:red">0.0.</span> | f.42038.<span style="color:red">0.0.</span> | f.42037.<span style="color:red">0.0.</span> |
|---|---|---|---|
| 5967229 | NA | 1   | 23  |
| 4674807 | NA | NA| NA|
| 1456203 | 3330| 2| 575|
| 3723112 | NA| 1| 380|

</center>

Highlighted <span style="color:red">in red</span> are the instance and array codes from the UKB field codes. These two numbers are separated by a dot e.g. *variable.instance.array.*
**Instance** refers the assessment instance (or visit). **Array** capture multiple answers that may be given to the same question. See UKB documentation for detailed descriptions of [instance](https://biobank.ctsu.ox.ac.uk/crystal/instance.cgi?id=2) and [array](https://biobank.ctsu.ox.ac.uk/crystal/help.cgi?cd=array).

Let’s see two examples, one where a field has multiple instances, and another example where a field has multiple arrays. 

*Example of field with multiple instances:* Standing height (field number 50) was measured 4 times. (For details on this specific field, click [here](https://biobank.ndph.ox.ac.uk/showcase/field.cgi?id=50)). You will see the following in your .tab file:

<center>

| f.eid   | f.50.<span style="color:red">0.0.</span> | f.50.<span style="color:red">1.0.</span> | f.50.<span style="color:red">2.0.</span> | f.50.<span style="color:red">3.0.</span> |
|---|---|---|---|---|
| 5967229 | 156| 155| 156| 156|
| 4674807 | 178| 178| 178| 177|
| 1456203 | 175| 175| 175| 175|
| 3723112 | 161| 161| 161| 161|

</center>


*Example of field with multiple arrays:* Information about treatment medication (field number 20003) was measured 4 times (so it has 4 instances). 
For each instance, participants indicated how many medications they were taking. Each medication would be recorded as a new item and will be stored as a new variable. 

The maximum number of items present for any participant will define how many variables the field. 
For treatment medication, there was a person who recorded 47 items, and therefore there are 47 variables per instance for this field. Each number represents categories or values to code medical treatments (For details on the treatments coding, click [here](https://biobank.ctsu.ox.ac.uk/crystal/coding.cgi?id=4)).

<center>

| f.eid   | f.20003.0.1 | f.20003.0.2 | f. 20003.0.3 | …. | f. 20003.0.47 |
|---------|-------------|-------------|--------------|----|---------------|
| 5967229 | NA          | NA          | NA           | …. | NA            |
| 4674807 | 178         | 1754        | NA           | …. | NA            |
| 1456203 | 45          | NA          | NA           | …. | NA            |
| 3723112 | 1341        | 161         | 131          | …. | 14            |

</center>


## Health Records Linkage

### Hospital inpatient episodes

Inpatient hospital data for the UK Biobank cohort contains information on when a particular diagnosis or procedure was recorded in the hospital data. This information was obtained through linkage to external data providers. 
Inpatients are defined as persons who are admitted to hospital and occupy a hospital bed. Diagnoses are coded according to the World Health Organization’s International Classification of Diseases and Related Health Problems (Both [ICD-10](https://biobank.ctsu.ox.ac.uk/crystal/field.cgi?id=41270) and [ICD-9](https://biobank.ctsu.ox.ac.uk/crystal/field.cgi?id=41271) codes are available). All operations and procedures are coded according to the Office of Population, Censuses and Surveys [(OPCS)](https://biobank.ctsu.ox.ac.uk/crystal/field.cgi?id=41272). Click [here](https://biobank.ndph.ox.ac.uk/ukb/ukb/docs/HospitalEpisodeStatistics.pdf) for more details on the UK Biobank Hospital inpatient data.

**Due to the format and complexity of the record-level data, data on Hospital inpatient episodes is not provided as part of the main UK Biobank dataset but as separate data tables**. 
It is also important to note that the hospital inpatient data is available to researchers in two formats: summary and record-level data. Detailed explanations about data collection and the two data formats available can be found [here](https://biobank.ndph.ox.ac.uk/ukb/label.cgi?id=2000).

#### Record-level inpatient data
Record level inpatient data is divided into seven interrelated database tables. The core table is "hesin", which connects to the subsidiary tables via a "record_id" field.

<center>
<img src="..//img/HES_tables.png" alt="HES_tables" width="600" />
<figcaption> Record-level data in seven interrelated data tables. Figure obtained from UK Biobank website</figcaption>
</center>

Below there is an example of how a *hesin* table looks like. For a hesin table, the same individual (eid) can appear more than once, but each inpatient episode (record_id) for a participant is stored as a single record, i.e. a row of data. **This differs from the format of the UK Biobank main dataset, which provides a single row of data per participant**.

The hesin table provides information on inpatient episodes of care for England, Wales and Scotland, including details on admissions and discharge, the type of episode and -where applicable- how an episode fits into a hospital spell (that is, the full time a patient spends in hospital from admission to discharge).

|     eid|record_id    |     admidate      |     diag_icd10    |     disdate       |     epiend        |     epistart      |     opdate        |     oper4    |
|----------------|------------------|-------------------|-------------------|-------------------|-------------------|-------------------|-------------------|--------------|
|     1234567    |     9073133      |     2003-05-11    |     R198          |     2003-05-15    |     2003-05-15    |     2003-05-15    |                   |     X948     |
|     1234567    |     1195874      |     2003-07-05    |     R104          |     2003-06-05    |     2003-06-05    |     2003-06-05    |     2003-06-05    |     H151     |
|     6467723    |     1134531      |     2000-02-01    |                   |     2000-05-01    |     2000-05-01    |     2000-05-01    |                   |     X668     |
|     5123456    |     3345750      |     2006-09-16    |     L720          |     2006-05-16    |     2006-05-16    |     2006-05-16    |     2006-05-16    |     S045     |
|     5123456    |     2343109      |                   |     M8414         |                   |     2005-10-05    |     2005-10-05    |     2005-10-05    |     W200     |
|     5123456    |     4223415      |                   |     M8414         |                   |     2005-10-05    |     2005-10-05    |     2005-10-05    |     W231     |

<p>&nbsp;</p>

#### Summary-level hospital inpatient data

UK Biobank has also created summary fields that provide the first date of any given diagnostic or operation code, which may be sufficient for many researchers’ needs. More information about summary-level hospital inpatient data can be found [here](https://biobank.ctsu.ox.ac.uk/crystal/label.cgi?id=2000).

### Hospital outpatient episodes

### Death registrations

### Cancer registrations

### Primary care
