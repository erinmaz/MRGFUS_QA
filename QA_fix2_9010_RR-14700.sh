#!/bin/bash

#subject ID as first input, coil (12ch or 32ch) as 2nd input
MYSUB=$1
MYCOIL=$2
MAINDIR=/Users/erin/Desktop/Projects/MRGFUS
DICOMDIR=${MAINDIR}/dicoms
ANALYSISDIR=${MAINDIR}/analysis
SCRIPTSDIR=${MAINDIR}/scripts
SPMDIR=/Users/erin/Documents/MATLAB/spm12
mkdir ${ANALYSISDIR}/${MYSUB}
ANATDIR=${ANALYSISDIR}/${MYSUB}/anat
mkdir ${ANATDIR}

#################### SAVE QA SCRIPT ###################################
#save a copy of this script to the analysis dir, so I know what I've run
cp $0 ${ANALYSISDIR}/${MYSUB}/.


#################### GET SESSION INFO ##################################
file1=`find ${DICOMDIR}/${MYSUB}/*SAG_FSPGR_BRAVO* -type f -not -name ".DS_Store" | head -1;` 
STUDYINFO=`dicom_hdr $file1 | egrep "ID Study Description" | cut -f5- -d "/"`
DATE=`dicom_hinfo -tag 0008,0020 -no_name $file1`

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
brain
fsleyes ${ANATDIR}/T1 ${ANATDIR}/spm_mask &

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
mkdir ${ANALYSISDIR}/${MYSUB}/diffusion
dcm2niix ${diff_fow_dir}
mv ${diff_fow_dir}/*.nii.gz ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow.nii.gz
dcm2niix ${diff_rev_dir}
mv ${diff_rev_dir}/*.nii.gz ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev.nii.gz
fsleyes ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow &
fsleyes ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev &
fslroi ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow_b0 0 3
fslroi ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev_b0 0 3
fslmerge -t ${ANALYSISDIR}/${MYSUB}/diffusion/all_b0 ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow_b0 ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev_b0
topup --imain=${ANALYSISDIR}/${MYSUB}/diffusion/all_b0 --datain=${SCRIPTSDIR}/acqp.txt --config=b02b0.cnf --out=${ANALYSISDIR}/${MYSUB}/diffusion/topup_results --fout=${ANALYSISDIR}/${MYSUB}/diffusion/topup_field --iout=${ANALYSISDIR}/${MYSUB}/diffusion/all_b0_unwarped
fslmaths ${ANALYSISDIR}/${MYSUB}/diffusion/all_b0_unwarped -Tmean ${ANALYSISDIR}/${MYSUB}/diffusion/mean_b0_unwarped
if [ "$MYCOIL" = "32ch" ]
then
	bet ${ANALYSISDIR}/${MYSUB}/diffusion/mean_b0_unwarped ${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain -m -f 0.3
else
	bet ${ANALYSISDIR}/${MYSUB}/diffusion/mean_b0_unwarped ${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain -m
fi
fslmerge -t ${ANALYSISDIR}/${MYSUB}/diffusion/data_uncorrected ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev
time eddy_cpu --imain=${ANALYSISDIR}/${MYSUB}/diffusion/data_uncorrected --mask=${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain_mask --acqp=${SCRIPTSDIR}/acqp_eddy.txt --index=${SCRIPTSDIR}/index.txt --bvecs=${SCRIPTSDIR}/bvecs --bvals=${SCRIPTSDIR}/bvals --topup=${ANALYSISDIR}/${MYSUB}/diffusion/topup_results --cnr_maps --repol --out=${ANALYSISDIR}/${MYSUB}/diffusion/data
fsleyes ${ANALYSISDIR}/${MYSUB}/diffusion/data &
dtifit -k ${ANALYSISDIR}/${MYSUB}/diffusion/data -o ${ANALYSISDIR}/${MYSUB}/diffusion/dtifit -m ${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain_mask -r ${ANALYSISDIR}/${MYSUB}/diffusion/data.eddy_rotated_bvecs -b ${SCRIPTSDIR}/bvals --sse
fsleyes ${ANALYSISDIR}/${MYSUB}/diffusion/dtifit_FA ${ANALYSISDIR}/${MYSUB}/diffusion/dtifit_V1 ${ANALYSISDIR}/${MYSUB}/diffusion/dtifit_sse &
#diffusion tsnr calc
fslroi ${ANALYSISDIR}/${MYSUB}/diffusion/data ${ANALYSISDIR}/${MYSUB}/diffusion/dw_fow 3 45
fslroi ${ANALYSISDIR}/${MYSUB}/diffusion/data ${ANALYSISDIR}/${MYSUB}/diffusion/dw_rev 51 6
fslmerge -t ${ANALYSISDIR}/${MYSUB}/diffusion/dw ${ANALYSISDIR}/${MYSUB}/diffusion/dw_fow ${ANALYSISDIR}/${MYSUB}/diffusion/dw_rev
fslmaths ${ANALYSISDIR}/${MYSUB}/diffusion/dw -Tmean ${ANALYSISDIR}/${MYSUB}/diffusion/dw_mean
fslmaths ${ANALYSISDIR}/${MYSUB}/diffusion/dw -Tstd ${ANALYSISDIR}/${MYSUB}/diffusion/dw_std
fslmaths ${ANALYSISDIR}/${MYSUB}/diffusion/dw_mean -div ${ANALYSISDIR}/${MYSUB}/diffusion/dw_std ${ANALYSISDIR}/${MYSUB}/diffusion/dw_tsnr
fsleyes ${ANALYSISDIR}/${MYSUB}/diffusion/dw_tsnr ${ANALYSISDIR}/${MYSUB}/diffusion/data.eddy_cnr_maps &
difftsnr=`fslstats ${ANALYSISDIR}/${MYSUB}/diffusion/dw_tsnr -k ${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain_mask -M`
diffcnr=`fslstats -t ${ANALYSISDIR}/${MYSUB}/diffusion/data.eddy_cnr_maps -k ${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain_mask -M`
if [ "$PURET1" = "YES" ] && [ "$PUREdiff" = "YES" ] 
then
	T1fordiffreg=${ANATDIR}/T1
	diffforreg=${ANALYSISDIR}/${MYSUB}/diffusion/mean_b0_unwarped
elif [ "$PURET1" = "NO" ] && [ "$PUREdiff" = "NO" ] 
then
	T1fordiffreg=${ANATDIR}/T1
	diffforreg=${ANALYSISDIR}/${MYSUB}/diffusion/mean_b0_unwarped

elif [ "$PURET1" = "YES" ]
then
	#not very efficient, because I potentially run these lines twice (once for fMRI and once for diffusion)
	dcm2niix ${DICOMDIR}/${MYSUB}/*-SAG_FSPGR_BRAVO*
	mv ${DICOMDIR}/${MYSUB}/*-SAG_FSPGR_BRAVO*/*.nii.gz ${ANATDIR}/T1_noPURE.nii.gz
	fslmaths ${ANATDIR}/T1_noPURE -mas ${ANATDIR}/spm_mask ${ANATDIR}/T1_noPURE_brain
	T1fordiffreg=${ANATDIR}/T1_noPURE
	diffforreg=${ANALYSISDIR}/${MYSUB}/diffusion/mean_b0_unwarped

elif [ "$PUREdiff" = "YES" ]
then
	T1fordiffreg=${ANATDIR}/T1
	dcm2niix ${DICOMDIR}/${MYSUB}/*-DWI_45*
	mv ${DICOMDIR}/${MYSUB}/*-DWI_45*/*.nii.gz ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow_noPURE.nii.gz
	fslroi ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow_noPURE ${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow_noPURE_nodif 0 3
	dcm2niix ${DICOMDIR}/${MYSUB}/*-DWI_PE*
	mv ${DICOMDIR}/${MYSUB}/*-DWI_PE*/*.nii.gz ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev_noPURE.nii.gz
	fslroi ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev_noPURE ${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev_noPURE_nodif 0 3
	applytopup --imain=${ANALYSISDIR}/${MYSUB}/diffusion/dti_fow_noPURE_nodif,${ANALYSISDIR}/${MYSUB}/diffusion/dti_rev_noPURE_nodif -t ${ANALYSISDIR}/${MYSUB}/diffusion/topup_results -o ${ANALYSISDIR}/${MYSUB}/diffusion/dti_noPURE_unwarped_nodif -a ${SCRIPTSDIR}/acqp_eddy.txt --inindex=1,2
	fslroi ${ANALYSISDIR}/${MYSUB}/diffusion/dti_noPURE_unwarped_nodif ${ANALYSISDIR}/${MYSUB}/diffusion/dti_noPURE_unwarped_nodif 0 1
	fslmaths ${ANALYSISDIR}/${MYSUB}/diffusion/dti_noPURE_unwarped_nodif -mas ${ANALYSISDIR}/${MYSUB}/diffusion/nodif_brain_mask ${ANALYSISDIR}/${MYSUB}/diffusion/dti_noPURE_unwarped_nodif_brain
	diffforreg=${ANALYSISDIR}/${MYSUB}/diffusion/dti_noPURE_unwarped_nodif
fi
mkdir ${ANALYSISDIR}/${MYSUB}/diffusion/xfms
#flirt -in $diffforreg -ref $T1fordiffreg -omat ${ANALYSISDIR}/${MYSUB}/diffusion/xfms/diff2str.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -cost corratio -out ${ANALYSISDIR}/${MYSUB}/diffusion/xfms/diff2str 

epi_reg --epi=${diffforreg} --t1=${T1fordiffreg} --t1brain=${T1fordiffreg}_brain --out=${ANALYSISDIR}/${MYSUB}/diffusion/xfms/diff_2_T1_bbr
convert_xfm -omat ${ANALYSISDIR}/${MYSUB}/diffusion/xfms/T1_2_diff_bbr.mat -inverse ${ANALYSISDIR}/${MYSUB}/diffusion/xfms/diff_2_T1_bbr.mat
fsleyes ${ANALYSISDIR}/${MYSUB}/diffusion/xfms/diff_2_T1_bbr ${T1fordiffreg} &

#fsleyes ${ANALYSISDIR}/${MYSUB}/diffusion/xfms/diff2str $T1fordiffreg &
#convert_xfm -omat ${ANALYSISDIR}/${MYSUB}/diffusion/xfms/str2diff.mat -inverse ${ANALYSISDIR}/${MYSUB}/diffusion/xfms/diff2str.mat 

	
############## fMRI QA ################################################
for f in ${DICOMDIR}/${MYSUB}/*PUrsBOLD*; do
    if [ -e "$f" ]; then
		PUREBOLD=YES
		BOLDdir=$f
    else
		PUREBOLD=NO
		BOLDdir=${DICOMDIR}/${MYSUB}/*rsBOLD*
    fi
    break
done
mkdir ${ANALYSISDIR}/${MYSUB}/fmri
dcm2niix ${BOLDdir}
mv ${BOLDdir}/*.nii.gz ${ANALYSISDIR}/${MYSUB}/fmri/rs.nii.gz
fsleyes ${ANALYSISDIR}/${MYSUB}/fmri/rs &
sed 's:MYINPUT:'${ANALYSISDIR}'/'${MYSUB}'/fmri/rs:g' ${SCRIPTSDIR}/QA_${MYCOIL}.fsf > ${ANALYSISDIR}/${MYSUB}/fmri/QA_${MYCOIL}.fsf
feat ${ANALYSISDIR}/${MYSUB}/fmri/QA_${MYCOIL}.fsf
fslmaths ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/filtered_func_data -Tstd ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/std_func
fslmaths ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/mean_func -div ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/std_func ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/tsnr_func
rstsnr=`fslstats ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/tsnr_func -k ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/mask -M`
fsleyes ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/tsnr_func &
fsleyes ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/filtered_func_data.ica/melodic_IC &
fsl_motion_outliers -i ${ANALYSISDIR}/${MYSUB}/fmri/rs -s ${ANALYSISDIR}/${MYSUB}/fmri/rs_motion.rms -p ${ANALYSISDIR}/${MYSUB}/fmri/rs_motion.png -o ${ANALYSISDIR}/${MYSUB}/fmri/rs_motion_confounds.txt
sed 's:MYINPUT:'${ANALYSISDIR}'/'${MYSUB}'/fmri/rs:g' ${SCRIPTSDIR}/QA_mc_only_${MYCOIL}.fsf > ${ANALYSISDIR}/${MYSUB}/fmri/QA_mc_only_${MYCOIL}.fsf
feat ${ANALYSISDIR}/${MYSUB}/fmri/QA_mc_only_${MYCOIL}.fsf
fslmaths ${ANALYSISDIR}/${MYSUB}/fmri/rs+.feat/filtered_func_data -Tstd ${ANALYSISDIR}/${MYSUB}/fmri/rs+.feat/std_func
fslmaths ${ANALYSISDIR}/${MYSUB}/fmri/rs+.feat/mean_func -div ${ANALYSISDIR}/${MYSUB}/fmri/rs+.feat/std_func ${ANALYSISDIR}/${MYSUB}/fmri/rs+.feat/tsnr_func
rstsnr_mc_only=`fslstats ${ANALYSISDIR}/${MYSUB}/fmri/rs+.feat/tsnr_func -k ${ANALYSISDIR}/${MYSUB}/fmri/rs.feat/mask -M`
fsleyes ${ANALYSISDIR}/${MYSUB}/fmri/rs+.feat/tsnr_func &
if [ "$PURET1" = "YES" ] && [ "$PUREBOLD" = "YES" ]
then
	T1forreg=${ANATDIR}/T1_brain
	BOLDforreg=${ANALYSISDIR}/${MYSUB}/fmri/rs
elif [ "$PURET1" = "NO" ] && [ "$PUREBOLD" = "NO" ]
then
	T1forreg=${ANATDIR}/T1_brain
	BOLDforreg=${ANALYSISDIR}/${MYSUB}/fmri/rs
elif [ "$PURET1" = "YES" ]
then
#need to get non-PURE T1 to reg with BOLD
	#not very efficient, because I potentially convert nonPURE T1 twice (once for fMRI and once for diffusion)
	dcm2niix ${DICOMDIR}/${MYSUB}/*-SAG_FSPGR_BRAVO*
	mv ${DICOMDIR}/${MYSUB}/*-SAG_FSPGR_BRAVO*/*.nii.gz ${ANATDIR}/T1_noPURE.nii.gz
	fslmaths ${ANATDIR}/T1_noPURE -mas ${ANATDIR}/spm_mask ${ANATDIR}/T1_noPURE_brain
	T1forreg=${ANATDIR}/T1_noPURE_brain
	BOLDforreg=${ANALYSISDIR}/${MYSUB}/fmri/rs
elif [ "$PUREBOLD" = "YES" ]
then
#need to get non-PURE BOLD to reg with T1
	dcm2niix ${DICOMDIR}/${MYSUB}/*-rsBOLD*
	mv ${DICOMDIR}/${MYSUB}/*-rsBOLD*/*.nii.gz ${ANALYSISDIR}/${MYSUB}/fmri/rs_noPURE.nii.gz
	T1forreg=${ANATDIR}/T1_brain
	BOLDforreg=${ANALYSISDIR}/${MYSUB}/fmri/rs_noPURE
fi
sed 's:MYINPUT:'${BOLDforreg}':g' ${SCRIPTSDIR}/reg_${MYCOIL}.fsf > ${ANALYSISDIR}/${MYSUB}/fmri/reg_${MYCOIL}.fsf
sed -i "" 's:MYT1:'${T1forreg}':g' ${ANALYSISDIR}/${MYSUB}/fmri/reg_${MYCOIL}.fsf
sed -i "" 's:MYOUTPUT:'${ANALYSISDIR}'/'${MYSUB}'/fmri/rs_reg.feat:g'  ${ANALYSISDIR}/${MYSUB}/fmri/reg_${MYCOIL}.fsf
feat ${ANALYSISDIR}/${MYSUB}/fmri/reg_${MYCOIL}.fsf
	

################# SUMMARY OUTPUT ########################################
echo $MYSUB,$DATE,$STUDYINFO,$PURET1,$PURET2,$PUREdiff,$PUREBOLD,$difftsnr,`echo $diffcnr | tr ' ' ,` ,`awk '{ sum += $2; n++ } END { print sum / n; } ' ${ANALYSISDIR}/${MYSUB}/diffusion/data.eddy_restricted_movement_rms`,$rstsnr,$rstsnr_mc_only,`awk -v max=0 '{if($1>max){ max=$1}}END{print max} ' ${ANALYSISDIR}/${MYSUB}/fmri/rs_motion.rms`,`awk '{ total += $1 } END { print total/NR}' ${ANALYSISDIR}/${MYSUB}/fmri/rs_motion.rms`







