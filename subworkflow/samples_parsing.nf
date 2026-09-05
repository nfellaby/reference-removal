#!/usr/bin/env nextflow
include { LONG_SYNTH_READS; SHORT_SYNTH_READS } from '../modules/synthesise_reads'
include { POOL_LONG_READS; POOL_SHORT_READS }   from '../modules/pool_reads'

workflow SAMPLES_SETUP{
    take:
    samplesheet_fp
    background_data_dir
    read_length

    main:
    // Declare channels up front so they're visible outside the if/else
    single_end_ch      = Channel.empty()
    paired_end_ch      = Channel.empty()
    reference_genomes_ch = Channel.empty()

    // Check if background data samplesheet has been supplied
    if (samplesheet_fp){
        // Handle either tsv or csv
        def sep_char = samplesheet_fp.toString().toLowerCase().endsWith('.tsv') ? '\t' : ','


        def parsed_ch = Channel
            .fromPath(samplesheet_fp)
            .splitCsv(header: false, skip: 1, sep: sep_char)  // drop header row; column names unknown/irrelevant
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
    } else if(background_data_dir){
        log.info "Specified test data directory  ${background_data_dir}. Will use FASTA files found within directory to generate synthetic data."  
        // Generate a channel for each of the FASTA files in the directory
        Channel
            .fromPath("${background_data_dir}/**/*.{fa,fasta,fas,fna,fa.gz,fasta.gz,fas.gz,fna.gz}")
            .set { fasta_ch }

        // Derive a sample_id per fasta and fan out into two lock-step channels
        // (multiMap keeps them correctly paired per-item, unlike calling .map
        // twice on the same source channel)
        def synth_input = fasta_ch.multiMap { fasta ->
            fasta:     fasta
            sample_id: fasta.getBaseName().replaceAll(/\.(fa|fasta|fas|fna)(\.gz)?$/, '')
        }

        def long_reads  = ['long', 'both']
        def short_reads = ['short', 'both']

        long_synth_reads_ch  = Channel.empty()
        short_synth_reads_ch = Channel.empty()

        if (read_length in long_reads) {
            LONG_SYNTH_READS(synth_input.fasta, synth_input.sample_id)
            long_synth_reads_ch = LONG_SYNTH_READS.out.ref_long_synth

            long_synth_reads_ch.subscribe { r ->
                log.info "Generated synthetic long reads: ${r}"
            }
        }

        if (read_length in short_reads) {
            SHORT_SYNTH_READS(synth_input.fasta, synth_input.sample_id)
            short_synth_reads_ch = SHORT_SYNTH_READS.out.ref_short_synth

            short_synth_reads_ch.subscribe { r1, r2 ->
                log.info "Generated synthetic short reads: ${r1}, ${r2}"
            }
        }

        // Pool every background genome's synthetic reads into one synthetic
        // metagenomic sample
        if (read_length in long_reads) {
            POOL_LONG_READS(long_synth_reads_ch.collect())
            synthetic_metagenome_long_ch = POOL_LONG_READS.out.pooled
            synthetic_metagenome_long_ch.view()
        }

        

        if (read_length in short_reads) {
            // toList() (not collect()) — collect() flattens the r1/r2 tuple
            // by default and you'd lose the pairing between R1/R2 lists.
            def short_split = short_synth_reads_ch.multiMap { r1, r2 ->
                r1: r1
                r2: r2
            }
            POOL_SHORT_READS(short_split.r1.toList(), short_split.r2.toList())
            synthetic_metagenome_short_ch = POOL_SHORT_READS.out.pooled
            synthetic_metagenome_short_ch.view()
        }


    } else{
        exit(1, "No samplesheet provided with --samplesheet or directory specified with --test_data. Please provide one.")
    }
        //  test_accessions_ch = Channel
        //     .fromPath(params.test_accessions)
        //     .splitText()
        //     .map { it.trim() }
        //     .filter { it && !it.startsWith('#') }

        // DOWNLOAD_GENOME(test_accessions_ch)



        // // Flatten [taxon, [genome1, genome2, ...]] -> one emission per genome, tagged with an id
        // def per_genome_ch = reference_genomes_ch
        //     .flatMap { taxon, genome_paths ->
        //         genome_paths.collect { g ->
        //             def genome_id = g.getBaseName().replaceAll(/\.fna(\.gz)?$/, '')
        //             tuple(genome_id, g)
        //         }
        //     }
        
        // if (params.read_length in ['short', 'both']) {
        //     short_synth_reads_ch = SHORT_SYNTH_READS(per_genome_ch).reads
        //     short_synth_reads_ch.subscribe { id, r1, r2 ->
        //         log.info "Generated short synthetic reads for ${id}: ${r1}, ${r2}"
        //     }
        // }

        // if (params.read_length in ['long', 'both']) {
        //     long_synth_reads_ch = LONG_SYNTH_READS(per_genome_ch).reads
        //     long_synth_reads_ch.subscribe { id, reads ->
        //         log.info "Generated long synthetic reads for ${id}: ${reads}"
        //     }
        // }


    emit:
    single_end          = single_end_ch
    paired_end           = paired_end_ch
    // reference_genomes    = reference_genomes_ch
    // short_synth_reads     = short_synth_reads_ch
    // long_synth_reads      = long_synth_reads_ch
}