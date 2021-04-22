#! /bin/bash -eu
folders=$(ls data/)
input_file='input.lyrx'
output_dir='/usr/share/geoserver/data_dir/styles/ag/'
for folder in $folders
do
    echo "Converting ${folder}"
    output_file="${output_dir}${folder}.sld"
    curl -d @"data/${folder}/${input_file}" "http://localhost/v1/lyrx2sld/?replaceesri=true" -o "${output_file}"
done