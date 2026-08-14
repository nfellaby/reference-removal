#!/usr/bin/env nextflow

process DOWNLOAD_REFSEQ_GENOMES {
    tag "${taxon}"
    label 'process_low'
    container 'staphb/ncbi-datasets:16.36.0'   // pin a specific version, not 'latest'
    publishDir "${params.outdir}/reference_genomes", mode: 'copy'

    input:
    val taxon

    output:
    tuple val(taxon), path("${taxon}_genomes/*.fna.gz"), emit: genomes

    script:
    """
    datasets download genome taxon "${taxon}" \\
        --reference \\
        --assembly-level complete \\
        --include genome \\
        --filename ${taxon}.zip
    ...
    """
}