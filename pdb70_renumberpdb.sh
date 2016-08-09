#!/bin/zsh

#BSUB -q mpi
#BSUB -W 47:50
#BSUB -n 16
#BSUB -a openmp
#BSUB -o /usr/users/mmeier/jobs/pdb70_renumberpdb.log
#BSUB -R "span[hosts=1]"
#BSUB -R np16
#BSUB -R haswell
#BSUB -R cbscratch
#BSUB -J pdb70_renumberpdb
#BSUB -m hh
#BSUB -w "done(pdb70_hhblits)"

source paths.sh
source /etc/profile
source $HOME/.zshrc

module use-append $HOME/modulefiles/
module load intel/compiler/64/15.0/2015.3.187
module load openmpi/intel/64/1.8.5

mkdir -p /local/${USER}
MYLOCAL=$(mktemp -d --tmpdir=/local/${USER})

src_input=${pdb70_build_dir}/pdb70_a3m_without_ss
input_basename=$(basename ${src_input})
cp ${src_input}.ff* ${MYLOCAL}
input=${MYLOCAL}/${input_basename}

export TEMP=${MYLOCAL}/temp
mkdir ${TEMP}

mpirun -np 16 ffindex_apply_mpi ${input}.ff{data,index} -d ${MYLOCAL}/pdb70_pdb.ffdata -i ${MYLOCAL}/pdb70_pdb.ffindex -- renumberpdb.pl -v 0 -o stdout stdin

ffindex_build -as ${MYLOCAL}/pdb70_pdb.ff{data,index}
rm -f ${pdb70_build_dir}/pdb70_pdb.ff{data,index}
cp ${MYLOCAL}/pdb70_pdb.ff{data,index} ${pdb70_build_dir}/
