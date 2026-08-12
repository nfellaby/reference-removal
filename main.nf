#!/usr/bin/env nextflow
include {REFERENCE_VALIDATION} from './workflows/reference_validation'
include {REFERENCE_REMOVAL} from './workflows/reference_removal'


workflow {
    // 1. Check User inputs
    // Check Reference has been supplied
    if (!params.fasta){
        exit(1, "Please specify --fasta FASTA file to use.")
    }

    // Check if performing validation?
    if (params.fasta){
        // Validation always requires fasta
        if (!params.fasta){
            exit(1, "Please specify --reference FASTA file to use.")
        }
        log.info "Running reference validation with ${params.fasta}"
        if (params.idx){
            log.info "Testing with included index: ${params.idx}"
        }

        REFERENCE_VALIDATION(params.fasta, params.idx, params.background_samplesheet)

    }
    else {
        log.info "Running reference removal with ${params.fasta}"
        if(!params.background_samplesheet){
            exit(1, "When running reference removal please specify --background_samplesheet.")
        }
        else{
            REFERENCE_REMOVAL(params.fasta, params.background_samplesheet)
        }
        
    }
    // Handle no background specified, download background dataset
    // if (!params.background){
    // }

    // 2. Check FASTA Files
    // 3. Generate synthetic reads
    // 4. Run Filtering process
    // 5. Generate Summary Table outputs
}