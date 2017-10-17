#!/bin/bash

source paths.sh
source ~/.bashrc

#delete old files
rm -f ${pdb70_build_dir}/pdb70_a3m_without_ss.ff{data,index}*

for f in ${pdb70_build_dir}/pdb70_a3m_without_ss*.ffindex;
do
  bn=$(basename $f .ffindex)
  ffindex_build -as ${pdb70_build_dir}/pdb70_a3m_without_ss.ff{data,index} -i ${pdb70_build_dir}/${bn}.ffindex -d ${pdb70_build_dir}/${bn}.ffdata
done

