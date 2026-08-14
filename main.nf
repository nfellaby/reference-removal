#!/usr/bin/env nextflow
include {REFERENCE_VALIDATION} from './workflows/reference_validation'
include {REFERENCE_REMOVAL} from './workflows/reference_removal'


workflow {
    // 1. Check User inputs
    // Check Reference has been supplied
    if (!params.fasta){
        exit(1, "Please specify --fasta FASTA file to use.")
    }

    // Performing Validation?
    def validation_options = ['true', 'false']
    if (!(params.validation) in validation_options){
        exit 1, "ERROR --validation must be one of ${validation_options.join(', ')} (Got '${params.validation_options}')"
    }

    if (params.validation){
        // Validation always requires fasta
        if (!params.fasta){
            exit(1, "Please specify --reference FASTA file to use.")
        }
        log.info "Running reference validation with ${params.fasta}"
        if (params.idx){
            log.info "Testing with included index: ${params.idx}"
        }

        def valid_read_length = ['short', 'long', 'both']
        if (!(params.read_length in valid_read_length)){
            exit 1, "ERROR: --read_length must be one of ${valid_read_length.join(', ')} (got '${params.read_length}')"
        }
        log.info "Generating ${params.read_length} read synthetic data. Designated by --read_length, default='long', options='short','long','both'"

        REFERENCE_VALIDATION(params.fasta, params.idx, params.samplesheet, params.read_length)

    }
    else {
        log.info "Running reference removal with ${params.fasta}"
        if(!params.samplesheet){
            exit(1, "When running reference removal please specify --background_samplesheet.")
        }
        else{
            REFERENCE_REMOVAL(params.fasta, params.samplesheet)
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