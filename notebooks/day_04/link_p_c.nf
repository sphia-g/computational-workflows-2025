#!/usr/bin/env nextflow

process SPLITLETTERS {
    publishDir "results", mode: 'copy'
    
    input:
    tuple val(meta), val(in_str)
    
    output:
    path "${meta.prefix}_chunk_*.txt"
    
    script:
    """
    echo "${in_str}" | fold -w ${meta.block_size} | split -l 1 -a 3 - ${meta.prefix}_chunk_
    for file in ${meta.prefix}_chunk_*; do
        mv "\$file" "\$file.txt"
    done
    """
} 

process CONVERTTOUPPER {
    publishDir "results", mode: 'copy'
    debug true
    
    input:
    path chunk_file
    
    output:
    path "${chunk_file.baseName}_upper.txt"
    
    script:
    """
    tr '[:lower:]' '[:upper:]' < ${chunk_file} > ${chunk_file.baseName}_upper.txt
    """
} 

workflow { 
    // 1. Read in the samplesheet (samplesheet_2.csv)  into a channel. The block_size will be the meta-map
    // 2. Create a process that splits the "in_str" into sizes with size block_size. The output will be a file for each block, named with the prefix as seen in the samplesheet_2
    // 4. Feed these files into a process that converts the strings to uppercase. The resulting strings should be written to stdout

    // read in samplesheet
    samplesheet_ch = channel.fromPath('samplesheet_2.csv')
    | splitCsv(header: true, sep: ',')
    | map { row ->
        def meta = [
            prefix: row.out_name,
            block_size: row.block_size as Integer
        ]
        return [meta, row.input_str]
    }

    // split the input string into chunks
    chunk_files = SPLITLETTERS(samplesheet_ch)

    // lets remove the metamap to make it easier for us, as we won't need it anymore
    flat_chunks = chunk_files.flatten()

    // convert the chunks to uppercase and save the files to the results directory
    CONVERTTOUPPER(flat_chunks)
}