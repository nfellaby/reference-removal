include { GENERATE_IDX } from '../modules/generate_idx.nf'

workflow REFERENCE_PARSING{
    take:
    reference_fp

    main:
    // Check if reference is index file or fasta
    if (reference_fp.endsWith('.fasta') || reference_fp.endsWith('.fa') || reference_fp.endsWith('.fna')) {
        log.info "Generating Deacon index file"
        ref_id = file(reference_fp).simpleName
        log.info "${ref_id}"
        // GENERATE_IDX(reference_fp, ref_id)
        // log.info"Generated Deacon index files."
    } else {
        log.info "Detected index input"
    }
}