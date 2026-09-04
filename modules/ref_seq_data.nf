#!/usr/bin/env nextflow

process DOWNLOAD_GENOME {
    // tag "${taxon}"
    label 'process_low'
    maxForks 25
    container 'community.wave.seqera.io/library/ncbi-datasets-cli:18.36.0--c90bc402d344df10'
    publishDir "${params.outdir}/reference_genomes", mode: 'copy'

    input:
    val(accession)

    // output:
    // tuple val(taxon), path("${taxon}_genomes/*.fna.gz"), emit: genomes

    script:
    """
    datasets download genome accession ${accession} \
            --include genome \
            --filename ${accession}.zip \
            --no-progressbar
    
    unzip -q ${accession}.zip -d ${accession}
    rm ${accession}.zip
    """
}