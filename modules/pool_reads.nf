#!/usr/bin/env nextflow

process POOL_LONG_READS {
    /*
        Concatenates per-genome synthetic long reads into a single
        synthetic metagenomic sample.
    */
    label 'process_low'
    // Find a light weight container 
    container 'community.wave.seqera.io/library/pip_gunzip:1ea8ddc0b75355cd'

    input:
    path(fastqs)

    output:
    path("synthetic_metagenome.long.fq.gz"), emit: pooled

    script:
    """
    cat ${fastqs} > synthetic_metagenome.long.fq.gz
    """
}

process POOL_SHORT_READS {
    /*
        Concatenates per-genome synthetic short (paired) reads into a
        single synthetic metagenomic sample. R1/R2 order must match --
        these lists come from the same multiMap fan-out so they're
        already aligned per-genome.
    */
    label 'process_low'
    container 'community.wave.seqera.io/library/pip_gunzip:1ea8ddc0b75355cd'

    input:
    path(r1_fastqs)
    path(r2_fastqs)

    output:
    tuple path("synthetic_metagenome.R1.fq.gz"), path("synthetic_metagenome.R2.fq.gz"), emit: pooled

    script:
    """
    cat ${r1_fastqs} > synthetic_metagenome.R1.fq.gz
    cat ${r2_fastqs} > synthetic_metagenome.R2.fq.gz
    """
}