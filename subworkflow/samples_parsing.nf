#!/usr/bin/env nextflow


workflow SAMPLES_SETUP{
    take:
    samplesheet_fp

    main:
    // Check if background data samplesheet has been supplied
    if(samplesheet_fp){
        samples_ch = Channel
                .fromPath(samplesheet_fp)
                .splitCsv(header: true)
                .map { row ->
                    tuple(row.sample_id, file(row.file_path))
        }
        samples_ch
            .count()
            .subscribe { n ->
                log.info "Read in provided samplesheet (${samplesheet_fp}): ${n} samples."
            }
    } else {
        log.info "No samplesheet provided using --samplesheet"
    }

    // if not download test data

    // return channels
    // emit:
    // samples_ch
    
}