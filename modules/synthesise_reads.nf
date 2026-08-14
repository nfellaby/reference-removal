#!/usr/bin/env nextflow

process LONG_SYNTH_READS {
    /*
        This process takes a FASTA input file and generates a deacon
        index file, used to remove reference sequences from FASTQ data.

        Inputs:
            - FASTA filepath
        Outputs:
            - IDX file

    */

    container 'community.wave.seqera.io/library/pbsim3:3.0.5--86541aa3eccd4c3c'
    label 'process_medium'
    maxForks 10

    input:
    path(fasta_fp)
    val(sample_id)

    output:
    path("${sample_id}.pbsim.fq.gz"), emit: ref_long_synth

    script:
    """
    pbsim \
        --prefix ${sample_id} \
        --id-prefix ${sample_id}__ \
        --seed 1 \
        --strategy wgs \
        --genome ${fasta_fp} \
        --depth 10 \
        --method errhmm \
        --errhmm ${params.pbsim_model} \
        --accuracy-mean 0.98;

    cat ${sample_id}_*.fq.gz > ${sample_id}.pbsim.fq.gz
    """

}