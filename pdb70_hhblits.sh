#!/bin/bash

#BSUB -q mpi
#BSUB -W 48:00
#BSUB -n 16
#BSUB -a openmpi
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

echo "pdb70_hhblits: Running mpirun -np 160 ffindex_apply_mpi ${pdb70_build_dir}/selected_pdb70_fasta.ff{data,index} -i ${pdb70_build_dir}/pdb70_a3m_without_ss.ffindex -d ${pdb70_build_dir}/pdb70_a3m_without_ss.ffdata -- hhblits -i stdin -oa3m stdout -o /dev/null -cpu 1 -d ${uniprot} -n 3 -v 0"

mpirun -np 16 ffindex_apply_mpi ${pdb70_build_dir}/selected_pdb70_fasta.ff{data,index} -i ${pdb70_build_dir}/pdb70_a3m_without_ss.ffindex -d ${pdb70_build_dir}/pdb70_a3m_without_ss.ffdata -- hhblits -i stdin -oa3m stdout -o /dev/null -cpu 1 -d ${uniprot} -n 3 -v 0

