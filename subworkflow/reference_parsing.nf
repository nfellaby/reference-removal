workflow REFERENCE_PARSING{
    take:
    reference_fp
    // Check if reference is index file or fasta
    if (params.input.endsWith('.fasta') || params.input.endsWith('.fa') {
        log.info "Detected FASTA input"
    } else if (params.input.endsWith('.idx')) {
        log.info "Detected index input"
    else{
        exit(1, "Reference input file must be either '.fasta', '.fa', or '.idx'"))
    }
}