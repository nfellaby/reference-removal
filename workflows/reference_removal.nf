#!/usr/bin/env nextflow
include { RESOLVE_REFERENCE } from '../subworkflow/resolve_reference'
include { SAMPLES_SETUP     } from '../subworkflow/samples_parsing'
include { FILTER_READS      } from '../subworkflow/filter_reads'

workflow REFERENCE_REMOVAL{
    take:
    fasta             // FASTA path, or null if idx is supplied
    idx               // prebuilt Deacon index path, or null if fasta is supplied
    samplesheet_fp    // samplesheet path, or null if sample_data_dir is supplied
    sample_data_dir   // directory of FASTQs, or null if samplesheet_fp is supplied


    main:
    RESOLVE_REFERENCE(fasta, idx)

    // read_type is unused inside samples_parsing.nf's body -- it auto-detects
    // single vs paired per sample from the samplesheet/directory regardless,
    // so any value is fine here; 'both' is just the clearest to read.
    SAMPLES_SETUP(samplesheet_fp, sample_data_dir, 'both')

    SAMPLES_SETUP.out.single_end
        .mix(SAMPLES_SETUP.out.paired_end)
        .count()
        .subscribe { n ->
            if (n == 0) {
                error "No samples found via --samplesheet or --sample_data_dir. Nothing to run reference removal on."
            }
        }

    FILTER_READS(
        SAMPLES_SETUP.out.single_end,
        SAMPLES_SETUP.out.paired_end,
        RESOLVE_REFERENCE.out.ref_idx,
    )

    emit:
    single_depleted = FILTER_READS.out.single_depleted
    single_ref_only = FILTER_READS.out.single_ref_only
    paired_depleted = FILTER_READS.out.paired_depleted
    paired_ref_only = FILTER_READS.out.paired_ref_only

}