#!/bin/bash
source paths.sh
source ~/.bashrc

set -e

mkdir -p "${LOCAL}/${USER}"
MYLOCAL=$(mktemp -d --tmpdir=${LOCAL}/${USER})
trap "if [ -d \"${MYLOCAL}\" ] && [ \"${MYLOCAL}\" != \"/\" ]; then rm -rf -- \"${MYLOCAL}\"; fi" EXIT

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

hhblits_omp -i ${INPUT} -oa3m ${MYLOCAL}/pdb70_a3m_without_ss_${SLURM_ARRAY_TASK_ID} -d ${DB} -cpu ${NCORES} -v 0 -n 3 -o /dev/null
cp ${MYLOCAL}/pdb70_a3m_without_ss_${SLURM_ARRAY_TASK_ID}.ff* ${pdb70_build_dir}

