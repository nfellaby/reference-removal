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

    container 'quay.io/biocontainers/deacon:0.16.0--h3edb6b3_0'
    label 'process_medium'
    maxForks 10

    input:
    path(fasta_fp)
    val(sample_id)

    output:
    path("${sample_id}.fq.gz"), emit: long_synth_reads

    script:
    """
    pbsim \
        --seed 1 \
        --strategy wgs \
        --method errhmm \
        --errhmm ${params.pbsim_model} \
        --depth 10 \
        --genome ${fasta} \
        --prefix ${sample_id} \
        --id-prefix ${sample_id}__ \
        --length-mean 1000 \
        --length-max 10000 \
        --accuracy-mean 0.98; \
    """

}