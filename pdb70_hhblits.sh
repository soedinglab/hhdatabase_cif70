#!/bin/bash
source paths.sh
source ~/.bashrc

rm -f ${pdb70_build_dir}/pdb70_a3m_without_ss.ff{data,index}*

echo "hhblits_omp -i ${pdb70_build_dir}/selected_pdb70_fasta -oa3m ${pdb70_build_dir}/pdb70_a3m_without_ss -o /dev/null -cpu 16 -d ${uniprot} -n 3 -v 0"
hhblits_omp -i ${pdb70_build_dir}/selected_pdb70_fasta -oa3m ${pdb70_build_dir}/pdb70_a3m_without_ss -o /dev/null -cpu 16 -d ${uniprot} -n 3 -v 0

