#!/bin/bash

#BSUB -q mpi
#BSUB -W 47:50
#BSUB -n 16
#BSUB -a openmp
#BSUB -o /usr/users/jsoedin/jobs/cif70_hhmake.log
#BSUB -R "span[hosts=1]"
#BSUB -R np16
#BSUB -R haswell
#BSUB -R cbscratch
#BSUB -J cif70_hhmake
#BSUB -m hh
#BSUB -w "done(cif70_addss)"

source paths.sh
source $HOME/.bashrc

module load intel/compiler/64/15.0/2015.3.187
module load openmpi/intel/64/1.8.5

mkdir -p /local/${USER}
MYLOCAL=$(mktemp -d --tmpdir=/local/${USER})

src_input=${pdb70_build_dir}/pdb70_a3m
input_basename=$(basename ${src_input})
cp ${src_input}.ff* ${MYLOCAL}
input=${MYLOCAL}/${input_basename}

echo "pdb70_hhmake: Copied data from ${pdb70_build_dir}/pdb70_a3m to ${MYLOCAL}/${input_basename}."

echo "pdb70_hhmake: Running: mpirun -np 16 ffindex_apply_mpi ${input}.ff{data,index} -d ${MYLOCAL}/pdb70_hhm.ffdata -i ${MYLOCAL}/pdb70_hhm.ffindex -- hhmake -i stdin -o stdout -v 0."

mpirun -np 16 ffindex_apply_mpi ${input}.ff{data,index} -d ${MYLOCAL}/pdb70_hhm.ffdata -i ${MYLOCAL}/pdb70_hhm.ffindex -- hhmake -i stdin -o stdout -v 0

ffindex_build -as ${MYLOCAL}/pdb70_hhm.ff{data,index}
rm -f ${pdb70_build_dir}/pdb70_hhm.ff{data,index}
cp ${MYLOCAL}/pdb70_hhm.ff{data,index} ${pdb70_build_dir}/

echo "pdb70_hhmake: Copied data from ${MYLOCAL}/pdb70_hhm.ff{data,index} to ${pdb70_build_dir}" 
