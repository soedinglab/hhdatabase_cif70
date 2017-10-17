#!/bin/bash

#BSUB -q mpi
#BSUB -W 48:00
#BSUB -n 16
#BSUB -a openmp
#BSUB -R "span[hosts=1]"
#BSUB -o /usr/users/jsoedin/jobs/cif70_hhblits.log
#BSUB -R np16
#BSUB -R haswell
#BSUB -R cbscratch
#BSUB -J cif70_hhblits[1-11]
#BSUB -m hh
#BSUB -w "done(cif70_prepare_input)"

source paths.sh
source ~/.bashrc

NCORES=16

mkdir -p /local/${USER}/
MYLOCAL=$(mktemp -d --tmpdir=/local/${USER})

# copy database to local ssd
db=${uniprot}
db_bn=$(basename $db)
cp ${db}*.ff* ${MYLOCAL}
DB=${MYLOCAL}/${db_bn}

#prepare subset of input to processed by this job
cp ${pdb70_build_dir}/selected_pdb70_fasta.ffindex ${MYLOCAL}/selected_pdb70_fasta.sel.ffindex
sed -i -n $(echo "($LSB_JOBINDEX - 1) * 5000 + 1" | bc),$(echo "$LSB_JOBINDEX * 5000" | bc)p ${MYLOCAL}/selected_pdb70_fasta.sel.ffindex
cp ${pdb70_build_dir}/selected_pdb70_fasta.ffdata ${MYLOCAL}/selected_pdb70_fasta.sel.ffdata
INPUT=${MYLOCAL}/selected_pdb70_fasta.sel

#delete old files
rm -f ${pdb70_build_dir}/pdb70_a3m_without_ss.ff{data,index}*
rm -f ${pdb70_build_dir}/pdb70_a3m_without_ss${LSB_JOBINDEX}.ff{data,index}*

hhblits_omp -i ${INPUT} -oa3m ${MYLOCAL}/pdb70_a3m_without_ss_${LSB_JOBINDEX} -d ${DB} -o /dev/null -cpu ${NCORES} -v 0 -n 3
cp ${MYLOCAL}/pdb70_a3m_without_ss_${LSB_JOBINDEX}.ff* ${pdb70_build_dir}

