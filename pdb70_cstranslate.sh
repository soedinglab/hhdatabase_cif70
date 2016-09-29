#!/bin/bash

#BSUB -q mpi
#BSUB -W 47:50
#BSUB -n 16
#BSUB -a openmp
#BSUB -o /usr/users/jsoedin/jobs/cif70_cstranslate.log
#BSUB -R "span[hosts=1]"
#BSUB -R np16
#BSUB -R haswell
#BSUB -R cbscratch
#BSUB -J cif70_cstranslate
#BSUB -m hh
#BSUB -w "done(cif70_hhblits)"

source paths.sh
source $HOME/.bashrc

module load intel/compiler/64/15.0/2015.3.187
module load openmpi/intel/64/1.8.5

mkdir -p /local/${USER}
MYLOCAL=$(mktemp -d --tmpdir=/local/${USER})

src_input=${pdb70_build_dir}/pdb70_a3m_without_ss
input_basename=$(basename ${src_input})
cp ${src_input}.ff* ${MYLOCAL}
input=${MYLOCAL}/${input_basename}

echo "pdb70_cstranslate: Copied data from ${pdb70_build_dir}/pdb70_a3m_without_ss to ${MYLOCAL}/${input_basename}."

echo "pdb70_cstranslate: Running: cstranslate -A ${HHLIB}/data/cs219.lib -D ${HHLIB}/data/context_data.lib -x 0.3 -c 4 -f -i ${input} -o ${MYLOCAL}/pdb70_cs219 -I a3m -b."

cstranslate -A ${HHLIB}/data/cs219.lib -D ${HHLIB}/data/context_data.lib -x 0.3 -c 4 -f -i ${input} -o ${MYLOCAL}/pdb70_cs219 -I a3m -b

ffindex_build -as ${MYLOCAL}/pdb70_cs219.ff{data,index}
rm -f ${pdb70_build_dir}/pdb70_cs219.ff{data,index}
cp ${MYLOCAL}/pdb70_cs219.ff{data,index} ${pdb70_build_dir}/

echo "pdb70_cstranslate: Copied ${MYLOCAL}/pdb70_cs219.ff{data,index} to ${pdb70_build_dir}"
