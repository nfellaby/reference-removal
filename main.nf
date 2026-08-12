#!/usr/bin/env nextflow
include {REFERENCE_VALIDATION} from './workflows/reference_validation'

workflow {
    // 1. Check User inputs
    // Check Reference FASTA has been supplied
    if (!params.reference){
        exit(1, "Please specify --reference FASTA file to use.")
    }

    // Check if performing validation?
    if (params.validation){
        log.info "Running reference validation with ${params.reference}"
        REFERENCE_VALIDATION(params.reference, params.background_samplesheet)

    }
    // Handle no background specified, download background dataset
    // if (!params.background){
    // }

    // 2. Check FASTA Files
    // 3. Generate synthetic reads
    // 4. Run Filtering process
    // 5. Generate Summary Table outputs
}