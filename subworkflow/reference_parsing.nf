#!/usr/bin/env nextflow

include { GENERATE_IDX     } from '../modules/generate_idx'
include { LONG_SYNTH_READS } from '../modules/synthesise_reads'

workflow REFERENCE_PARSING{
    take:
    fasta_fp

    main:
    // Check if reference is index file or fasta
    if (fasta_fp.endsWith('.fasta') || fasta_fp.endsWith('.fa') || fasta_fp.endsWith('.fna')) {
        log.info "Generating Deacon index file"
        ref_id = file(fasta_fp).baseName
        log.info "Reference ID: ${ref_id}"
        // Create index
        GENERATE_IDX(fasta_fp, ref_id)
        ref_idx = GENERATE_IDX.out.ref_idx
        
        ref_idx.subscribe { idx ->
            idx_simp = file(idx).baseName
            log.info "Generated Deacon index file: ${idx_simp}"
        }
    } 

    // If validation is specified generate synthetic reads for index
    LONG_SYNTH_READS(fasta_fp)

    emit:
    ref_id
    ref_idx
}