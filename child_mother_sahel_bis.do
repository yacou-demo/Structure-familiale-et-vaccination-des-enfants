use final_dataset_analysis_paper_2_final,clear

duplicates drop 

codebook concat_IndividualId
**Uniqued IndiId  =130,051
codebook MotherId
**Uniqued MotherId =50,179
keep concat_IndividualId MotherId DoB DoBMO
duplicates drop concat_IndividualId MotherId DoB DoBMO,force
rename concat_IndividualId ChildId
rename MotherId concat_IndividualId
sort concat_IndividualId
bysort concat_IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(concat_IndividualId) j(child_rank)
rename DoBMO DoB_mother
save mother_children_sahel_bis, replace