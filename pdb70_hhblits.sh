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
#BSUB -J cif70_hhblits
#BSUB -m hh
#BSUB -w "done(cif70_prepare_input)"

source paths.sh
source ~/.bashrc

rm -f ${pdb70_build_dir}/pdb70_a3m_without_ss.ff{data,index}*

echo "hhblits_omp -i ${pdb70_build_dir}/selected_pdb70_fasta -oa3m ${pdb70_build_dir}/pdb70_a3m_without_ss -o /dev/null -cpu 16 -d ${uniprot} -n 3 -v 0"
hhblits_omp -i ${pdb70_build_dir}/selected_pdb70_fasta -oa3m ${pdb70_build_dir}/pdb70_a3m_without_ss -o /dev/null -cpu 16 -d ${uniprot} -n 3 -v 0

