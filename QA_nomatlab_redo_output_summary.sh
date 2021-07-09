#!/bin/bash

#subject ID as input (e.g., 9XXX_YY-ZZZZZ)
MYSUB=$1


##### CHECK: DO YOU NEED TO EDIT THESE VARIABLES?
MAINDIR=/Users/erin/Desktop/Projects/MRGFUS

##################################################


##### CREATE THESE DIRECTORIES BEFORE RUNNING THIS SCRIPT FOR THE FIRST TIME
DICOMDIR=${MAINDIR}/dicoms
ANALYSISDIR=${MAINDIR}/analysis
SCRIPTSDIR=${MAINDIR}/scripts_QA
############################################################################


ANATDIR=${ANALYSISDIR}/${MYSUB}/anat


#################### SAVE QA SCRIPT ###################################
#save a copy of this script to the analysis dir, so I know what I've run
cp $0 ${ANALYSISDIR}/${MYSUB}/.



#################### GET SESSION INFO ##################################
file1=`find ${DICOMDIR}/${MYSUB}/*SAG_FSPGR_BRAVO* -type f -not -name ".DS_Store" | head -1;` 
STUDYINFO=`dicom_hdr $file1 | egrep "ID Study Description" | cut -f5- -d "/"`
DATE=`dicom_hinfo -tag 0008,0020 -no_name $file1`



#################### GET COIL INFO ##################################
COIL=`dicom_hinfo -tag 0018,1250 -no_name $file1`
if [ "$COIL" = "RM:Nova32ch" ]; then
	MYCOIL=32ch
else
	MYCOIL=12ch
fi

#################### T1 QA #############################################
for f in ${DICOMDIR}/${MYSUB}/*PUSAG_FSPGR_BRAVO*; do
    if [ -e "$f" ]; then
	PURET1=YES
	T1dir=$f
    else
	PURET1=NO
	T1dir=${DICOMDIR}/${MYSUB}/*SAG_FSPGR_BRAVO*
    fi
    break
done




#################### T2 QA #############################################
for f in ${DICOMDIR}/${MYSUB}/*PUSag_CUBE_T2*; do
    if [ -e "$f" ]; then
	PURET2=YES
	T2dir=$f
    else
	PURET2=NO
	T2dir=${DICOMDIR}/${MYSUB}/*Sag_CUBE_T2*
    fi
    break
done



#################### Diffusion QA #######################################
for f in ${DICOMDIR}/${MYSUB}/*PUDWI_45*; do
	if [ -e "$f" ]; then
		PUREdiff=YES
		diff_fow_dir=$f
		diff_rev_dir=${DICOMDIR}/${MYSUB}/*PUDWI_PE*
	else
		PUREdiff=NO
		diff_fow_dir=${DICOMDIR}/${MYSUB}/*DWI_45*
		diff_rev_dir=${DICOMDIR}/${MYSUB}/*DWI_PE*
	fi
	break
done

difftsnr=`fslstats ${ANALYSISDIR}/${MYSUB}/diffusion/dw_tsnr -k ${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain_mask -M`
diffcnr=`fslstats -t ${ANALYSISDIR}/${MYSUB}/diffusion/data.eddy_cnr_maps -k ${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain_mask -M`


	

	

################# SUMMARY OUTPUT ########################################
echo $MYSUB,$MYCOIL,$DATE,$STUDYINFO,$PURET1,$PURET2,$PUREdiff,$PUREBOLD,$difftsnr,`echo $diffcnr | tr ' ' ,` ,`awk '{ sum += $2; n++ } END { print sum / n; } ' ${ANALYSISDIR}/${MYSUB}/diffusion/data.eddy_restricted_movement_rms`,NC,NC,NC,NC
