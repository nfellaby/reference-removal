#!/usr/bin/env nextflow

workflow SAMPLES_SETUP{
    take:
    samplesheet_fp

    main:
    // Check if background data samplesheet has been supplied
    def parsed_ch = Channel
        .fromPath(samplesheet_fp)
        .splitCsv(header: false)
        .skip(1)   // drop header row; column names unknown/irrelevant
        .map { row ->
            if (row.size() < 2) {
                exit 1, "ERROR: Malformed row in samplesheet (${samplesheet_fp}): ${row}"
            }

            def sample_id = row[0]
            def read1_fp  = file(row[1])
            // Treat a missing/blank third column as single-end
            def read2_raw = (row.size() >= 3) ? row[2]?.trim() : null
            def read2_fp  = (read2_raw) ? file(read2_raw) : null

            if (!read1_fp.exists()) {
                exit 1, "ERROR: read1 file not found for sample '${sample_id}': ${row[1]}"
            }
            if (read2_fp && !read2_fp.exists()) {
                exit 1, "ERROR: read2 file not found for sample '${sample_id}': ${read2_raw}"
            }

            tuple(sample_id, read1_fp, read2_fp)
        }

    def branched = parsed_ch.branch { sample_id, read1_fp, read2_fp ->
        paired: read2_fp != null
        single: read2_fp == null
    }

    single_end_ch = branched.single.map { sample_id, read1_fp, read2_fp -> tuple(sample_id, read1_fp) }
    paired_end_ch = branched.paired.map { sample_id, read1_fp, read2_fp -> tuple(sample_id, [read1_fp, read2_fp]) }

    single_end_ch.subscribe { sample_id, read1 -> log.info "Single-end sample: ${sample_id} -> ${read1}" }
    paired_end_ch.subscribe { sample_id, reads -> log.info "Paired-end sample: ${sample_id} -> ${reads.join(', ')}" }
    // if not download test data

    // return channels
    // emit:
    // samples_ch
    
}