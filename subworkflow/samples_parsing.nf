#!/usr/bin/env nextflow


workflow SAMPLES_SETUP{
    take:
    background_samplesheet_fp

    main:
    // Check if background data samplesheet has been supplied
    if(background_samplesheet_fp){
        samples_ch = Channel
                .fromPath(samplesheet)
                .splitCsv(header: true)
                .map { row ->
                    tuple(row.sample_id, file(row.file_path))
        }
    }

    // if not download test data

    // return channels 
    
}