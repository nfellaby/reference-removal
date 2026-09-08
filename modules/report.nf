// modules/report.nf
process GENERATE_VALIDATION_REPORT {
    container 'community.wave.seqera.io/library/pyfastx_pandas_pip_plotly:ce47640d3d5148f3'
    label 'process_low'
    tag "${sample_id}"

    input:
    tuple val(sample_id), val(read_type), path(reference_fastq), path(background_fastq),
          path(isolate_fastq), path(depleted_fastq), path(deacon_json)

    output:
    path("${sample_id}.confusion.json"), emit: confusion

    script:
    """
    generate_validation_report.py \\
        --sample-id ${sample_id} \\
        --read-type ${read_type} \\
        --reference-fastq ${reference_fastq} \\
        --background-fastq ${background_fastq} \\
        --isolate-fastq ${isolate_fastq} \\
        --depleted-fastq ${depleted_fastq} \\
        --deacon-json ${deacon_json} \\
        -o ${sample_id}
    """
}

process AGGREGATE_REPORT {
    container 'community.wave.seqera.io/library/pyfastx_pandas_pip_plotly:ce47640d3d5148f3'
    label 'process_low'
    publishDir "${params.outdir}/report", mode: params.publish_dir_mode

    input:
    path(confusion_jsons)

    output:
    path("validation_report.html"), emit: report

    script:
    "build_html_report.py --jsons ${confusion_jsons} -o validation_report.html"
}