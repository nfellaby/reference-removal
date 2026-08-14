#!/usr/bin/env nextflow

process DOWNLOAD_REFSEQ_GENOMES {
    tag "${taxon}"
    label 'process_low'
    container 'community.wave.seqera.io/library/ncbi-datasets-cli:18.35.0--21225b8906124161'   // pin a specific version, not 'latest'
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