#!/usr/bin/env nextflow
include { GENERATE_IDX } from '../modules/generate_idx.nf'

workflow REFERENCE_REMOVAL{
    take:
    reference
    background_samplesheet

    // Check reference input
    main:
    // Check if reference is index file or fasta
    if (reference_fp.endsWith('.fasta') || reference_fp.endsWith('.fa') || reference_fp.endsWith('.fna')) {
        log.info "Generating Deacon index file"
        ref_id = file(reference_fp).baseName
        log.info "Reference ID: ${ref_id}"
        GENERATE_IDX(reference_fp, ref_id)
        GENERATE_IDX.out.ref_idx.view { idx ->
            idx_simple = file(idx).baseName
            log.info "Generated Deacon index file: ${idx_simple}.idx"
        }
    } else {
        idx_simple = file(reference_fp).baseName
        log.info "Detected index input: ${idx_simple}.idx"
    }
}