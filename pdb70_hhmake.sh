#!/bin/bash
source /etc/profile
source $HOME/.bashrc

source paths.sh

set -e

mkdir -p "${LOCAL}/${USER}"
MYLOCAL=$(mktemp -d --tmpdir=${LOCAL}/${USER})
trap "if [ -d \"${MYLOCAL}\" ] && [ \"${MYLOCAL}\" != \"/\" ]; then rm -rf -- \"${MYLOCAL}\"; fi" EXIT

src_input=${pdb70_build_dir}/pdb70_a3m
input_basename=$(basename ${src_input})
cp ${src_input}.ff* ${MYLOCAL}
input=${MYLOCAL}/${input_basename}

mpirun -np ${NCORES} ffindex_apply_mpi ${input}.ff{data,index} -d ${MYLOCAL}/pdb70_hhm.ffdata -i ${MYLOCAL}/pdb70_hhm.ffindex -- hhmake -i stdin -o stdout -v 0

ffindex_build -as ${MYLOCAL}/pdb70_hhm.ff{data,index}
rm -f ${pdb70_build_dir}/pdb70_hhm.ff{data,index}
cp ${MYLOCAL}/pdb70_hhm.ff{data,index} ${pdb70_build_dir}/
