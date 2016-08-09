#!/bin/bash

#BSUB -q mpi
#BSUB -W 47:50
#BSUB -n 16
#BSUB -a openmp
#BSUB -o /cbscratch/hvoehri/hhdatabase_pdb70/logs/pdb70_addss.log
#BSUB -R "span[hosts=1]"
#BSUB -R np16
#BSUB -R haswell
#BSUB -R cbscratch
#BSUB -J pdb70_addss
#BSUB -m hh
#BSUB -w "done(pdb70_hhblits)"

source paths.sh
source $HOME/.bashrc
source /etc/profile

# we need the following lines to get mpirun to work
module load intel/compiler/64/15.0/2015.5.223 
module load openmpi/gcc/64/1.6.4 

mkdir -p /local/${USER}
MYLOCAL=$(mktemp -d --tmpdir=/local/${USER})

src_input=${pdb70_build_dir}/pdb70_a3m_without_ss
input_basename=$(basename ${src_input})
cp ${src_input}.ff* ${MYLOCAL}
input=${MYLOCAL}/${input_basename}

echo "pdb70_addss: Copied data from ${pdb70_build_dir}/pdb70_a3m_without_ss to ${MYLOCAL}/${input_basename}."

echo "pdb70_addss: Running: mpirun -np 16 ffindex_apply_mpi ${input}.ff{data,index} -d ${MYLOCAL}/pdb70_a3m.ffdata -i ${MYLOCAL}/pdb70_a3m.ffindex -- ${HHLIB}/scripts/addss.pl stdin stdout -v 0"

mpirun -np 16 ffindex_apply_mpi ${input}.ff{data,index} -d ${MYLOCAL}/pdb70_a3m.ffdata -i ${MYLOCAL}/pdb70_a3m.ffindex -- ${HHLIB}/scripts/addss.pl stdin stdout -v 0

ffindex_build -as ${MYLOCAL}/pdb70_a3m.ff{data,index}
rm -f ${pdb70_build_dir}/pdb70_a3m.ff{data,index}
cp ${MYLOCAL}/pdb70_a3m.ff{data,index} ${pdb70_build_dir}/

echo "Copied data from ${MYLOCAL}/pdb70_a3m.ff{data,index} to ${pdb70_build_dir}." 

