#!/bin/bash
source /etc/profile
source $HOME/.bashrc

source paths.sh

mkdir -p /local/${USER}
MYLOCAL=$(mktemp -d --tmpdir=/local/${USER})

src_input=${pdb70_build_dir}/pdb70_a3m_without_ss
input_basename=$(basename ${src_input})
cp ${src_input}.ff* ${MYLOCAL}
input=${MYLOCAL}/${input_basename}

echo "pdb70_cstranslate: Copied data from ${pdb70_build_dir}/pdb70_a3m_without_ss to ${MYLOCAL}/${input_basename}."

echo "pdb70_cstranslate: Running: cstranslate -A ${HHLIB}/data/cs219.lib -D ${HHLIB}/data/context_data.lib -x 0.3 -c 4 -f -i ${input} -o ${MYLOCAL}/pdb70_cs219 -I a3m"

cstranslate -A ${HHLIB}/data/cs219.lib -D ${HHLIB}/data/context_data.lib -x 0.3 -c 4 -f -i ${input} -o ${MYLOCAL}/pdb70_cs219 -I a3m

ffindex_build -as ${MYLOCAL}/pdb70_cs219.ff{data,index}
rm -f ${pdb70_build_dir}/pdb70_cs219.ff{data,index}
cp ${MYLOCAL}/pdb70_cs219.ff{data,index} ${pdb70_build_dir}/

echo "pdb70_cstranslate: Copied ${MYLOCAL}/pdb70_cs219.ff{data,index} to ${pdb70_build_dir}"
