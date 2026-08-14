#!/usr/bin/env nextflow

process DOWNLOAD_REFSEQ_GENOMES {
    tag "${taxon}"
    label 'process_low'
    publishDir "${params.outdir}/reference_genomes", mode: 'copy'

    input:
    val taxon   // e.g. 'bacteria' or 'viruses'

    output:
    tuple val(taxon), path("${taxon}_genomes/*.fna.gz"), emit: genomes

    script:
    """
    datasets download genome taxon "${taxon}" \\
        --reference \\
        --assembly-level complete \\
        --include genome \\
        --filename ${taxon}.zip

    unzip -q ${taxon}.zip -d ${taxon}_extracted
    mkdir -p ${taxon}_genomes
    find ${taxon}_extracted/ncbi_dataset/data -name '*.fna' -exec gzip -c {} \\; > /dev/null
    find ${taxon}_extracted/ncbi_dataset/data -name '*.fna' -print0 | \\
        xargs -0 -I{} sh -c 'gzip -c "{}" > ${taxon}_genomes/\$(basename {}).gz'
    """
}