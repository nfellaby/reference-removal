workflow REFERENCE_PARSING{
    take:
    reference_fp

    main:
    // Check if reference is index file or fasta
    if (reference_fp.endsWith('.fasta') || reference_fp.endsWith('.fa') || reference_fp.endsWith('.fna')) {
        log.info "Generating Deacon index file"
    } else {
        log.info "Detected index input"
    }
}