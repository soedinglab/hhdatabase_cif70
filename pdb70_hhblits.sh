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

hhblits_omp -i ${pdb70_build_dir}/selected_pdb70_fasta -oa3m ${MYLOCAL}/pdb70_a3m_without_ss -o /dev/null -cpu ${NCORES} -d "${DB}" -n 3 -v 0
cp -f ${MYLOCAL}/pdb70_a3m_without_ss.ff{data,index} ${pdb70_build_dir}
