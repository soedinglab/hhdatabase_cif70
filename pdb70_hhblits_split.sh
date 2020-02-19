#!/bin/bash
source paths.sh
source ~/.bashrc

NCORES=16

set -e

mkdir -p /local/${USER}/
MYLOCAL=$(mktemp -d --tmpdir=/local/${USER})

# copy database to local ssd
db=${uniprot}
db_bn=$(basename $db)
cp ${db}*.ff* ${MYLOCAL}
DB=${MYLOCAL}/${db_bn}

#prepare subset of input to processed by this job
split -n "l/${SLURM_ARRAY_TASK_ID}/${SLURM_ARRAY_TASK_COUNT}" "${pdb70_build_dir}/selected_pdb70_fasta.ffindex" > "${MYLOCAL}/selected_pdb70_fasta.sel.ffindex"
cp ${pdb70_build_dir}/selected_pdb70_fasta.ffdata ${MYLOCAL}/selected_pdb70_fasta.sel.ffdata
INPUT=${MYLOCAL}/selected_pdb70_fasta.sel

#delete old files
rm -f ${pdb70_build_dir}/pdb70_a3m_without_ss.ff{data,index}*
rm -f ${pdb70_build_dir}/pdb70_a3m_without_ss${SLURM_ARRAY_TASK_ID}.ff{data,index}*

hhblits_omp -i ${INPUT} -oa3m ${MYLOCAL}/pdb70_a3m_without_ss_${SLURM_ARRAY_TASK_ID} -d ${DB} -o /dev/null -cpu ${NCORES} -v 0 -n 3
cp ${MYLOCAL}/pdb70_a3m_without_ss_${SLURM_ARRAY_TASK_ID}.ff* ${pdb70_build_dir}

