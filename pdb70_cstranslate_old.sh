#!/bin/bash
source paths.sh
source $HOME/.bashrc

set -e

mkdir -p "${LOCAL}/${USER}"
MYLOCAL=$(mktemp -d --tmpdir=${LOCAL}/${USER})
trap "if [ -d \"${MYLOCAL}\" ] && [ \"${MYLOCAL}\" != \"/\" ]; then rm -rf -- \"${MYLOCAL}\"; fi" EXIT

src_input=${pdb70_build_dir}/pdb70_a3m_without_ss
input_basename=$(basename ${src_input})
cp ${src_input}.ff* ${MYLOCAL}
input=${MYLOCAL}/${input_basename}

cstranslate -A ${HHLIB}/data/cs219.lib -D ${HHLIB}/data/context_data.lib -x 0.3 -c 4 -f -i ${input} -o ${MYLOCAL}/pdb70_cs219_old -I a3m

ffindex_build -as ${MYLOCAL}/pdb70_cs219_old.ff{data,index}
rm -f ${pdb70_build_dir}/pdb70_cs219_old.ff{data,index}
cp ${MYLOCAL}/pdb70_cs219_old.ff{data,index} ${pdb70_build_dir}/
