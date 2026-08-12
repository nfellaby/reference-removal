#!/usr/bin/env nextflow
include { REFERENCE_PARSING } from '../subworkflow/reference_parsing'

workflow REFERENCE_VALIDATION{
    take:
    reference_fp
    background_samplesheet_fp

    main:
    // Generate index files for reference
    REFERENCE_PARSING(reference_fp)


}