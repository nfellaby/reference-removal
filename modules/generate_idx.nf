#!/usr/bin/env nextflow

process GENERATE_IDX {
    /*
        This process takes a FASTA input file and generates a deacon
        index file, used to remove reference sequences from FASTQ data.

        Inputs:
            - FASTA filepath
        Outputs:
            - IDX file

    */

    container 'community.wave.seqera.io/library/pip_deacon:d36cab988a962281'
    label 'process_low'

    input:
    path(reference_fp)
    val(ref_id)

    output:
    path("${ref_id}.deacon.idx"), emit: ref_idx

    script:
    """
    deacon index build ${reference_fp} >${ref_id}.deacon.idx
    """

}