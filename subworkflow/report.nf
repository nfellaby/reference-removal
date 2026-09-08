// subworkflow/report.nf — join everything on sample_id
include { GENERATE_VALIDATION_REPORT } from '../modules/report.nf'
include { AGGREGATE_REPORT           } from '../modules/report.nf'

workflow VALIDATION_REPORT {
    take:
    background_truth    // tuple(sample_id, fastq) or tuple(sample_id, r1, r2) -- pre-spike, from SAMPLES_SETUP
    reference_truth     // single fastq -- from REFERENCE_PARSING (broadcast with .first())
    isolate_out         // tuple(sample_id, json, fastq) -- from LONG_SAMPLE_REMOVAL / PAIRED_SAMPLE_REMOVAL
    depleted_out        // tuple(sample_id, json, fastq) -- from LONG_REFERENCE_REMOVAL / PAIRED_REFERENCE_REMOVAL
    read_type           // val, 'long' or 'short'

    main:
    def joined = background_truth
        .join(isolate_out)
        .join(depleted_out)
        .map { sample_id, bg, iso_json, iso_fq, dep_json, dep_fq ->
            tuple(sample_id, read_type, reference_truth, bg, iso_fq, dep_fq, iso_json)
        }
        .combine(reference_truth)   // broadcasts the single shared reference fastq to every sample

    GENERATE_VALIDATION_REPORT(joined)
    AGGREGATE_REPORT(GENERATE_VALIDATION_REPORT.out.confusion.collect())

    emit:
    report = AGGREGATE_REPORT.out.report
}