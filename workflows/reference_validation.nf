#!/usr/bin/env nextflow
include { REFERENCE_PARSING     } from '../subworkflow/reference_parsing'
include { SAMPLES_SETUP } from '../subworkflow/samples_parsing'

workflow REFERENCE_VALIDATION{
    take:
    fasta
    idx
    background_samplesheet_fp
    read_length
    test_accessions

    main:
    // Generate index files for reference
    REFERENCE_PARSING(fasta, read_length)
    // Set up background data
    SAMPLES_SETUP(background_samplesheet_fp, test_accessions)


}