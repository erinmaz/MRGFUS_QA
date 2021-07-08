#!/bin/bash

SegsDir=/Users/erin/Desktop/Projects/MRGFUS/SPMsegs_from_Conrad_July2020
#f=9024_LLB-16323
#cp ${SegsDir}/${f}/anat/* /Users/erin/Desktop/Projects/MRGFUS/analysis/${f}/anat/.
#QA_nomatlab_2.sh ${f}

#for f in  9024_LLB-17182 9030_GA-17060	9031_DB-17340 9025_RR-16717	9028_PR-16523	9030_GA-17082	9031_DB-17635 	9030_GA-17501
#do
#cp ${SegsDir}/${f}/anat/* /Users/erin/Desktop/Projects/MRGFUS/analysis/${f}/anat/.
#QA_nomatlab_2.sh ${f} &> /Users/erin/Desktop/Projects/MRGFUS/logs/QA_nomatlab_2_${f}.log
#done

#done already 9028_PR-17283 
# need to fix T1 seg 9031_DB-17261

f=9028_PR-16838
cp ${SegsDir}/${f}/anat/* /Users/erin/Desktop/Projects/MRGFUS/analysis/${f}/anat/.
QA_nomatlab_2.sh ${f} &> /Users/erin/Desktop/Projects/MRGFUS/logs/QA_nomatlab_2_${f}.log
