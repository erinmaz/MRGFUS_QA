#!/bin/bash

f=9024_LLB-16323
cp ${f}/anat/* /Users/erin/Desktop/Projects/MRGFUS/analysis/${f}/anat/.
QA_nomatlab_2.sh ${f}

#for f in 	9027_KB-16664	9028_PR-17283	9029_WW-17425	9031_DB-17261 9024_LLB-17182	9027_KB-17111	9029_WW-16753	9030_GA-17060	9031_DB-17340 9025_RR-16717	9028_PR-16523	9029_WW-16929	9030_GA-17082	9031_DB-17635 9027_KB-16392	9028_PR-16838	9029_WW-16938	9030_GA-17501
#do
#cp ${f}/anat/* /Users/erin/Desktop/Projects/MRGFUS/analysis/${f}/anat/.
#QA_nomatlab_2.sh ${f}
#done