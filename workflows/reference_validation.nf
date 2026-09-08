#!/usr/bin/env nextflow
include { REFERENCE_PARSING     } from '../subworkflow/reference_parsing'
include { SAMPLES_SETUP } from '../subworkflow/samples_parsing'

def checkBackgroundPresent(ch, String label, boolean required) {
    ch.count().subscribe { n ->
        if (n == 0) {
            def msg = "No ${label} background samples found to spike the synthetic reference into."
            if (required) {
                error "${msg} Cannot proceed with read_length='${params.read_length}'. Supply matching background data, or change read_length."
            } else {
                log.warn "${msg} Skipping ${label} validation; continuing with what is available."
            }
        }
    }
    return ch  // unchanged — process still runs per-item as normal, or zero times if truly empty
}

process SPIKE_LONG_READS {
    label 'process_low'
    tag "${sample_id}"

    input:
    tuple val(sample_id), path(background_fq)
    path(ref_synth_fq)

    output:
    tuple val(sample_id), path("${sample_id}.spiked.long.fq.gz"), emit: spiked

    script:
    """
    cat ${background_fq} ${ref_synth_fq} > ${sample_id}.spiked.long.fq.gz
    """
}

process SPIKE_SHORT_READS {
    label 'process_low'
    tag "${sample_id}"

    input:
    tuple val(sample_id), path(background_reads)
    tuple path(ref_r1), path(ref_r2)

    output:
    tuple val(sample_id), path("${sample_id}.spiked.R1.fq.gz"), path("${sample_id}.spiked.R2.fq.gz"), emit: spiked

    script:
    """
    cat ${background_reads[0]} ${ref_r1} > ${sample_id}.spiked.R1.fq.gz
    cat ${background_reads[1]} ${ref_r2} > ${sample_id}.spiked.R2.fq.gz
    """
}



workflow REFERENCE_VALIDATION{
    take:
    fasta
    idx
    background_samplesheet_fp
    background_data_dir
    read_length

    main:
    def long_reads  = ['long', 'both']
    def short_reads = ['short', 'both']
    def strict_both = !(params.allow_partial_validation ?: false)

    // Generate index files for reference
    REFERENCE_PARSING(fasta, read_length)
    // Set up background data
    SAMPLES_SETUP(background_samplesheet_fp, background_data_dir, read_length)


    // Spike in syntheised reference reads into test sample(s)
    if (read_length in short_reads) {
        // 'short' alone → missing paired background makes the whole run pointless → always required
        // 'both'        → required unless the user opted into partial validation
        def required = (read_length == 'short') || (read_length == 'both' && strict_both)
        def paired_ch = checkBackgroundPresent(SAMPLES_SETUP.out.paired_end, 'paired-end (short-read)', required)
        SPIKE_SHORT_READS(paired_ch, REFERENCE_PARSING.out.ref_short_synth.first())
    }

    if (read_length in long_reads) {
        def required = (read_length == 'long') || (read_length == 'both' && strict_both)
        def single_ch = checkBackgroundPresent(SAMPLES_SETUP.out.single_end, 'single-end (long-read)', required)
        SPIKE_LONG_READS(single_ch, REFERENCE_PARSING.out.ref_long_synth.first())
    }

    // Run Reference Removal on Spiked samples

    // Summarise Results

}