#!/bin/bash

#BSUB -q mpi
#BSUB -W 48:00
#BSUB -n 192
#BSUB -a openmpi
#BSUB -o /cbscratch/hvoehri/hhdatabase_pdb70/logs/pdb70_hhblits.log
#BSUB -R np16
#BSUB -R haswell
#BSUB -R cbscratch
#BSUB -J pdb70_hhblits
#BSUB -m hh
##BSUB -w "done(pdb70_prepare_input)"

source paths.sh
source ~/.bashrc
source /etc/profile

# import modules to get mpirun to work
module load intel/compiler/64/15.0/2015.5.223
module load openmpi/gcc/64/1.6.4

rm -f ${pdb70_build_dir}/pdb70_a3m_without_ss.ff{data,index}*


echo "pdb70_hhblits: Running mpirun -np 192 ffindex_apply_mpi ${pdb70_build_dir}/selected_pdb70_fasta.ff{data,index} -i ${pdb70_build_dir}/pdb70_a3m_without_ss.ffindex -d ${pdb70_build_dir}/pdb70_a3m_without_ss.ffdata -- hhblits -i stdin -oa3m stdout -o /dev/null -cpu 1 -d ${uniprot} -n 3 -v 0"

mpirun -np 192 ffindex_apply_mpi ${pdb70_build_dir}/selected_pdb70_fasta.ff{data,index} -i ${pdb70_build_dir}/pdb70_a3m_without_ss.ffindex -d ${pdb70_build_dir}/pdb70_a3m_without_ss.ffdata -- hhblits -i stdin -oa3m stdout -o /dev/null -cpu 1 -d ${uniprot} -n 3 -v 0

