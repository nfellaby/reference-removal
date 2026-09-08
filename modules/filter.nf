process LONG_REFERENCE_REMOVAL {
        /*
        This process takes single FASTQ input file and a reference index file and removes references reads using Deacon

        Inputs:
            - Sample ID
            - FASTQ
            - Index

        Outputs:
            - FASTQ file
            - Reference Report** Not sure what this looks like currently

    */

    container 'community.wave.seqera.io/library/deacon:0.17.0--43cd5289edd1686c'
    lable 'process_medium'
    maxForks 10

    input:
    tuple val(sample_id), path(fastq_fp)
    path(ref_idx)

    output:
    path("${sample_id}.ref_removed.json"), emit: ref_removed_reads
    path("${sample_id}.ref_removed.fq.gz"), emit: ref_removed_summary

    script:
    """
    deacon \
        filter \
        -d ${ref_idx} \
        ${fastq_fp} \
        -s ${sample_id}.ref_removed.json \
        -o ${sample_id}.ref_removed.fq.gz \
        -t ${task.cpus}
    """
}

process LONG_SAMPLE_REMOVAL {
        /*
        This process takes single FASTQ input file and a reference index file and removes sample reads using Deacon

        Inputs:
            - Sample ID
            - FASTQ
            - Index

        Outputs:
            - FASTQ file
            - Reference Report** Not sure what this looks like currently

    */

    container 'community.wave.seqera.io/library/deacon:0.17.0--43cd5289edd1686c'
    lable 'process_medium'
    maxForks 10

    input:
    tuple val(sample_id), path(fastq_fp)
    path(ref_idx)

    output:
    path("${sample_id}.ref_removed.json"), emit: ref_reads_only
    path("${sample_id}.ref_removed.fq.gz"), emit: ref_reads_only_summary

    script:
    """
    deacon \
        filter \
        ${ref_idx} \
        ${fastq_fp} \
        -s ${sample_id}.ref_reads_only.json \
        -o ${sample_id}.ref_reads_only.fq.gz \
        -t ${task.cpus}
    """
}

process PAIRED_REFERENCE_REMOVAL {
        /*
        This process takes paired FASTQ input files and a reference index file and removes references reads using Deacon

        Inputs:
            - SAMPLE ID
            - FASTQ R1
            - FASTQ R2
            - Index


        Outputs:
            - FASTQ file

    */

    container 'community.wave.seqera.io/library/deacon:0.17.0--43cd5289edd1686c'
    lable 'process_medium'
    maxForks 10

    input:
    val(sample_id)
    path(fastq_r1_fp)
    path(fastq_r2_fp)
    path(ref_idx)

    script:
    """
    deacon \
        filter \
        -d ${ref_idx} \
        ${fastq_r1_fp} \
        ${fastq_r2_fp} \
        -s ${sample_id}.ref_removed.json \
        -o ${sample_id}.ref_reads_only.R1.fq.gz \
        -o ${sample_id}.ref_reads_only.R2.fq.gz \
        -t ${task.cpus}
    """
}

process PAIRED_SAMPLE_REMOVAL {
        /*
        This process takes paired FASTQ input files and a reference index file and removes sample reads using Deacon

        Inputs:
            - SAMPLE ID
            - FASTQ R1
            - FASTQ R2
            - Index
        Outputs:
            - FASTQ file

    */

    container 'community.wave.seqera.io/library/deacon:0.17.0--43cd5289edd1686c'
    lable 'process_medium'
    maxForks 10

    input:
    val(sample_id)
    path(fastq_r1_fp)
    path(fastq_r2_fp)
    path(ref_idx)


    script:
    """
    deacon \
        filter \
        ${ref_idx} \
        ${fastq_r1_fp} \
        ${fastq_r2_fp} \
        -s ${sample_id}.ref_reads_only.json \
        -o ${sample_id}.ref_reads_only.R1.fq.gz \
        -o ${sample_id}.ref_reads_only.R2.fq.gz \
        -t ${task.cpus}
    """
}