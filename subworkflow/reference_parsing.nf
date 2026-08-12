workflow REFERENCE_PARSING{
    take:
    reference_fp
    // Check if reference is index file or fasta
    if (params.reference.endsWith('.fasta') || params.reference.endsWith('.fa') || params.reference.endsWith('.fna')) {
        log.info "Generating Deacon index file"
    } else {
        log.info "Detected index input"
    }
}