// subworkflow/filter_reads.nf
#!/usr/bin/env nextflow

include { LONG_REFERENCE_REMOVAL; LONG_SAMPLE_REMOVAL     } from '../modules/filter'
include { PAIRED_REFERENCE_REMOVAL; PAIRED_SAMPLE_REMOVAL } from '../modules/filter'

workflow FILTER_READS {
    take:
    spiked_long   // tuple(sample_id, fastq)         from SPIKE_LONG_READS  (or Channel.empty())
    spiked_short  // tuple(sample_id, r1, r2)         from SPIKE_SHORT_READS (or Channel.empty())
    ref_idx       // single path, from REFERENCE_PARSING.out.ref_idx

    main:
    // .first() — same fix as the AIBLAST queue-vs-value issue: broadcasts
    // the one reference index to every sample rather than being consumed once
    def idx_ch = ref_idx.first()

    LONG_REFERENCE_REMOVAL(spiked_long, idx_ch)
    LONG_SAMPLE_REMOVAL(spiked_long, idx_ch)
    PAIRED_REFERENCE_REMOVAL(spiked_short, idx_ch)
    PAIRED_SAMPLE_REMOVAL(spiked_short, idx_ch)

    emit:
    long_depleted   = LONG_REFERENCE_REMOVAL.out.ref_removed_summary   // depleted background — should be reference-free
    long_ref_only   = LONG_SAMPLE_REMOVAL.out.ref_reads_only_summary   // isolated matches — should be ~exactly the spiked reference reads
    short_depleted  = PAIRED_REFERENCE_REMOVAL.out.ref_removed
    short_ref_only  = PAIRED_SAMPLE_REMOVAL.out.ref_reads_only
}