# Basic QC of Genetic data


### Removing related samples

UK Biobank supplies the relatedness file *ukbA_rel_sP.txt* with header: ID1, ID2, HetHet, IBS0 and [KING kinship coefficient](http://people.virginia.edu/~wc9c/KING/manual.html) (Manichaikul et al, 2010). Description of the file can be found [here.](https://biobank.ctsu.ox.ac.uk/crystal/refer.cgi?id=531)

The *ukbA_rel_sP.txt* file lists the pairs of individuals related up to the third degree in the data set. It is a plaintext file with space separated columns as follows:

| Column name    | Data type       | Info                                                                                                                                                                                                                    |
|----------------|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|     ID1        |     String      |     sample_id for individual 1 in related pair.                                                                                                                                                                         |
|     ID2        |     String      |     sample_id for individual 2 in related pair                                                                                                                                                                          |
|     HetHet     |     Numeric     |     Fraction of markers for which the pair both have a heterozygous genotype (output from KING software).                                                                                                               |
|     IBS0       |     Numeric     |     Fraction of markers for which the pair shares zero alleles (output from KING software).                                                                                                                             |
|     Kinship    |     Numeric     |     Estimate of the kinship coefficient for this pair based on the set of markers used in the kinship inference (output from KING software). The set of markers is indicated by the field: used.in.kinship.inference    |

<br>

There are many ways to remove related individuals from phenotypic data for genetic analyses. 
You could simply exclude all individuals indicated as having “excess relatedness” and include those “used in pca calculation” (these variables are included in the sample QC data, ukb_sqc_v2.txt).
This list is based on the complete dataset and possibly removes more samples than you need to for your phenotype of interest.
Ideally, you want a maximum independent set, i.e., to remove the minimum number of individuals with data on the phenotype of interest, so that no pair exceeds some cut off for relatedness.

You can use the script [GreedyRelated](https://gitlab.com/choishingwan/GreedyRelated) for relatedness filtering. 
