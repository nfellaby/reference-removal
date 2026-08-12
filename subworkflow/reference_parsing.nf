#!/usr/bin/env nextflow

include { GENERATE_IDX } from '../modules/generate_idx.nf'

workflow REFERENCE_PARSING{
    take:
    reference_fp
    background_samplesheet

    main:
    // Check if reference is index file or fasta
    if (reference_fp.endsWith('.fasta') || reference_fp.endsWith('.fa') || reference_fp.endsWith('.fna')) {
        log.info "Generating Deacon index file"
        ref_id = file(reference_fp).baseName
        log.info "Reference ID: ${ref_id}"
        
        GENERATE_IDX(reference_fp, ref_id)
        ref_idx = GENERATE_IDX.out.ref_idx
        
        ref_idx.subscribe { idx ->
            idx_simp = file(idx).baseName
            log.info "Generated Deacon index file: ${idx_simp}"
        }
    } else {
        ref_id  = file(reference_fp).baseName
        log.info "Detected index input: ${ref_id}.idx"
        ref_idx = Channel.fromPath(reference_fp)
    }

    emit:
    ref_id
    ref_idx
}