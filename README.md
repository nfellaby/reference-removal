# Reference Removal

## Description
The project looks to evaluate methods of removing references from metagenomic datasets. Specifically, internal controls that have been spiked-in i.e. TMV, lambda phage etc.

## De-Hosting Tools
- [Hostile](https://github.com/bede/hostile): Hostile removes host sequences from short and long read (meta)genomes, consuming single or paired FASTQ from files or stdin.
- [Deacon](https://github.com/bede/deacon): Deacon filters DNA sequences in FASTA/Q files and streams using SIMD-accelerated minimizer comparison with query sequence(s), emitting either matching sequences (search mode), or sequences without matches (deplete mode).
- [NoHuman](https://github.com/mbhall88/nohuman/): nohuman removes human reads from sequencing reads by classifying them with kraken2 against a custom database built from all of the genomes in the Human Pangenome Reference Consortium's ( HPRC) second release. It can take any type of sequencing technology.
- [detaxizer](https://github.com/nf-core/detaxizer/tree/dev): A pipeline to identify (and remove) certain sequences from raw genomic data. Default taxon to identify (and remove) is Homo sapiens. Removal is optional.

## Reference Datasets
The following datasets were canabilised from the Deacon pre-pub [paper](https://www.biorxiv.org/content/10.1101/2025.06.09.658732v1.full.pdf):
- [Viral Genomes](https://zenodo.org/records/15411280): 14,861 complete NCBI RefSeq virus sequences downloaded on 2026-07-31
- [Bacterial genomes](https://zenodo.org/records/15424142): all 1,428 complete [FDA-ARGOS bacterial reference genomes]((https://www.nature.com/articles/s41467-019-11306-6)) including plasmids, downloaded on 2026-07-31.
- Fungal Genomes: all 5,488 complete NCBI RefSeq, downloaded on 2026-07-31.

## Synthetic Read Generation Tools
- Short Read, [DWGSIM](https://github.com/nh13/DWGSIM)
- Long Read, [PBSIM](https://github.com/yukiteruono/pbsim3)

## Reference Organisms for Internal Control Spike-in
Viral:
- Tobacco Mosaic Virus ([Adela Alcolea-Medina et al., 2025](https://www.thelancet.com/journals/lanmic/article/PIIS2666-5247(25)00102-8/fulltext))
- Hazara Virus ([Kuiama Lewandowski et al., 2019](https://pubmed.ncbi.nlm.nih.gov/31666364/))
- Lambda Phage ([Jiayi Duan et al., 2025](https://pmc.ncbi.nlm.nih.gov/articles/PMC12633245/))
- T1 Phage ([Zhangfan Fu et al., 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10714923/))
- Thermus thermophilus ([Zhangfan Fu et al., 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10714923/))

Bacterial FASTA References 
- [ZymoBIOMICs references](https://www.bioscience.co.uk/cpl/zymobiomics-dna-kits?gad_source=1&gad_campaignid=21301459676&gbraid=0AAAAAD_TCRJyensW6-q0ajdbGar2qCICn&gclid=CjwKCAjwj7HTBhBiEiwA8s35OmX-N4EqACiysya4QZFb7_7QZMjsWO357qzxvQ40A8Ae7OlWGuWCbhoC0j4QAvD_BwE):
  - Imtechella halotolerans
  - Allobacillus halotolerans
  - Truepera radiovictrix

Predefined by mSCAPE:  
spike-in:
- ERCC-RNA_4456740
- bacillus_ms2phage
- ms2-phage
- phix
- tobacco_mosaic_virus
- zymo_D6320
- zymo_D6321

Internal Controls:
- [NIBSC_11/242](https://nibsc.org/products/brm_product_catalogue/detail_page.aspx?catid=11/242): Mock community containing 25 human pathogenic viruses
- [NIBSC_20/170](https://nibsc.org/about_us/latest_news/winter_multiplex.aspx): Flu A (H1N1, H3N2), Flu B, RSV A, RSV B, SARS-CoV-2
- bacillus_ms2phage
- zepto_rp2.1: Adenovirus 1, 3, 31; C. pneumoniae; Influenza A 2009 H1N1pdm, H3N2; Metapneumovirus 8; M. pneumoniae; Parainfluenza Type 1, 4; Rhinovirus 1A; SARS-CoV-2; B. parapertussis; B. pertussis; Coronavirus 229E, HKU-1, BL63, OC43; Influenza AH1, Influenza B, Parainfluenza Type 2, 3; RSV A
- [zymo-mc_D6300](https://zymoresearch.eu/collections/zymobiomics-microbial-community-standards/products/zymobiomics-microbial-community-standard): Listeria monocytogenes - 12%, Pseudomonas aeruginosa - 12%, Bacillus subtilis - 12%, Escherichia coli - 12%, Salmonella enterica - 12%, Lactobacillus fermentum - 12%, Enterococcus faecalis - 12%, Staphylococcus aureus - 12%, Saccharomyces cerevisiae - 2%, and Cryptococcus neoformans - 2%.



## Creating Reference Datasets
Given the references will be in the refseq/argos downloads, need to filter out references from those datasets. 
### 1. Remove References from Dataset
1. Run Kraken2 and de-hosting tools for reference
    - Evaluate number of hits
2. Remove matched reads 
3. Create version for each reference without reference, i.e. NCBI_refseq_visues_20260731.noTMV.fasta
4. Re-Run to see if any additional reads are annotated.

### 2.1 Generate Synthetic reads for viral datasets and references
Again, canabalised from Deacon pre-pub [paper](https://www.biorxiv.org/content/10.1101/2025.06.09.658732v1.full.pdf)
1. Long Read
   - Model: ERRHMM-ONT-HQ
   - Depth: 10x
   - Mean read length: 1,000bp
   - Max read length: 10,000bp
   - Mean accuracy: 0.98
   - Random seed: 1

Command used:
```
 for fasta in rsviruses17900/*.fa; do
    acc=$(basename "$fasta" .fa) \ 
    pbsim \
        --seed 1 \
        --strategy wgs \
        --method errhmm \
        --errhmm pbsim3/data/ERRHMM-ONT-HQ.model \
        --depth 10 \
        --genome ${fasta} \
        --prefix ${acc} \
        --id-prefix ${acc}__ \
        --length-mean 1000 \
        --length-max 10000 \
        --accuracy-mean 0.98; \
    cat ${acc}*.fastq | pigz > ${acc}.fastq.gz 
done;
```
2. Short Read
   - Read length: 2x150bp (paired)
   - Depth: 10x
   - Random read probability (-y): 0
   - Error rate (-e and -E): 0.01
   - Mutation rate (-r): 0.0 (of which low frequency somatic mutations (-F): 0.0)
   - Random seed (-z): 1

Command used:
```
for fasta in rsviruses17900/*.fa; do \
    acc=$(basename "$fasta" .fa) \
    dwgsim \
        -C 10 \
        -1 150 \
        -2 150 \
        -y 0.0 \
        -o 1 \
        -z 1 \
        -F 0.0 \
        -r 0.0 \
        -e 0.01 \
        -E 0.01 "$fasta" "$acc";
done;
```

### 2.2 Generate Synthetic reads for bacterial datasets and references
Again, canabalised from Deacon pre-pub [paper](https://www.biorxiv.org/content/10.1101/2025.06.09.658732v1.full.pdf)
1. Long Read
   - Model: ERRHMM-ONT-HQ
   - Depth: 10x
   - Mean read length: 5,000bp
   - Max read length: 50,000bp
   - Mean accuracy: 0.98
   - Random seed: 1

Command used:
```
 for fasta in bacteria/*.fa; do
    acc=$(basename "$fasta" .fa) \ 
    pbsim \
        --seed 1 \
        --strategy wgs \
        --method errhmm \
        --errhmm pbsim3/data/ERRHMM-ONT-HQ.model \
        --depth 10 \
        --genome ${fasta} \
        --prefix ${acc} \
        --id-prefix ${acc}__ \
        --length-mean 5000 \
        --length-max 50000 \
        --accuracy-mean 0.98; \
    cat ${acc}*.fastq | pigz > ${acc}.fastq.gz 
done;
```
2. Short Read
   - Read length: 2x150bp (paired)
   - Depth: 10x
   - Random read probability (-y): 0
   - Error rate (-e and -E): 0.01
   - Mutation rate (-r): 0.0 (of which low frequency somatic mutations (-F): 0.0)
   - Random seed (-z): 1

Command used:
```
for fasta in bacteria/*.fa; do \
    acc=$(basename "$fasta" .fa) \
    dwgsim \
        -C 10 \
        -1 150 \
        -2 150 \
        -y 0.0 \
        -o 1 \
        -z 1 \
        -F 0.0 \
        -r 0.0 \
        -e 0.01 \
        -E 0.01 "$fasta" "$acc";
done;
```

### Expected outputs:
All Viral Genomes
- NCBI_refseq_viruses_20260731.fasta
Viral FASTA References
- NCBI_refseq_viruses_20260731.noTMV.fasta
   - Remove GCA_000854365.1
- NCBI_refseq_viruses_20260731.noHazara.fasta
   - GCA_002831085.1
- NCBI_refseq_viruses_20260731.noLambda.fasta
   - GCA_000840245.1 (E.coli phage lambda)
   - Note: GCA_000840825.1 for Lambdapapillomavirus 2
- NCBI_refseq_viruses_20260731.noT1.fasta
   - GCA_000845005.1 (Escherichia phage T1)

Bacterial FASTA References
All bacterial genomes
- FDA-ARGOS_bacteria_20260731.fasta

Fungal FASTA References
- NCBI_refseq_fungi_20260731.fasta

### Set-up
1. Generate synthetic reads per FASTA
2. Combine Viral and Bacterial synth reads for background datasets 
   - i.e. not including references
3. Test for presence of reference
   - Filter reads mapping to reference if required (note # of reads)
4. Spike in reference reads
5. Test de-hosting process

### Starting with long read content only
- Transferred viral and bacterial datasets across to HPC working directory
- Uncompress directories for bacteria and viruses. Note: Leaving fungi for the moment.
```
mkdir FDA-ARGOS_bacterial_20260731/
unzip FDA-ARGOS_bacterial_20260731.zip -d FDA-ARGOS_bacterial_20260731/
mkdir NCBI_refseq_viruses_20260731
unzip NCBI_refseq_viruses_20260731.zip -d NCBI_refseq_viruses_20260731
```

- Generate synthetic long reads for viruses:
   - Create PBSim3 environment:
   ````
   mm create -n pbsim3
   mm activate  pbsim3
   mm install -c bioconda pbsim3
   ````
```
mkdir -p synth-reads/viral
cd $_


for fasta in /home/phe.gov.uk/nicholas.ellaby/scratch/NCBI_refseq_viruses_20260731/ncbi_dataset/data/*/*.fna; do
    acc=$(basename "$fasta" .fa)
    pbsim --seed 1 --strategy wgs --method errhmm --errhmm /home/phe.gov.uk/nicholas.ellaby/micromamba/envs/pbsim3/data/ERRHMM-ONT-HQ.model --depth 10 --genome ${fasta} --prefix ${acc} --id-prefix ${acc}__ --length-mean 1000 --length-max 10000 --accuracy-mean 0.98; cat ${acc}*.fastq | pigz > ${acc}.fastq.gz
done
```
- Generate synthetic long reads for bacteria

```
for fasta in /home/phe.gov.uk/nicholas.ellaby/scratch/FDA-ARGOS_bacterial_20260731/data/*/*fna; do
    acc=$(basename "$fasta" .fa)
    pbsim --seed 1 --strategy wgs --method errhmm --errhmm /home/phe.gov.uk/nicholas.ellaby/micromamba/envs/pbsim3/data/ERRHMM-ONT-HQ.model --depth 10 --genome ${fasta} --prefix ${acc} --id-prefix ${acc}__ --length-mean 5000 --length-max 50000 --accuracy-mean 0.98; cat ${acc}*.fastq | pigz > ${acc}.fastq.gz;
done;
```

- Minor issue, output files are in .fq.gz, I wanted to consolidate them into single files:
```
for fasta in /home/phe.gov.uk/nicholas.ellaby/scratch/FDA-ARGOS_bacterial_20260731/data/*/*fna; do     acc=$(basename "$fasta" .fa); echo ${acc}; cat ${acc}_*.fq.gz > ${acc}.combined.fq.gz; done;
```

- Do the same for viruses:
```
for fasta in /home/phe.gov.uk/nicholas.ellaby/scratch/NCBI_refseq_viruses_20260731/ncbi_dataset/data/*/*.fna; do     acc=$(basename "$fasta" .fa); echo ${acc}; cat ${acc}_*.fq.gz > ${acc}.combined.fq.gz; done;
```

- Move reference fastq's to a separate directory:
```
mkdir reference_synth_reads
mv viral/GCF_000854365.1_ViralProj15071_genomic.fna.combined.fq.gz reference_synth_reads/
```
- Combine all viral and bacterial datasets, without TMV
```
cat viral/*.fna.combined.fq.gz bacteria/*.fna.combined.fq.gz >>All_viral_bacterial.minusTMV.combined.fq.gz
```
- Copy TMV back into original directory
```
cp reference_synth_reads/GCF_000854365.1_ViralProj15071_genomic.fna.combined.fq.gz  viral/
```
- Some minor clean-up of temp files

### Running tools
1. Deacon
   - Build index: `deacon index build ../NCBI_refseq_viruses_20260731/ncbi_dataset/data/GCF_000854365.1/GCF_000854365.1_ViralProj15071_genomic.fna >GCF_000854365.deacon.idx`
   - Check how many reads it finds associated with TMV in each fa:  
      - Running against dataset without reference:
        ```
        deacon filter -d GCF_000854365.deacon.idx ../synth-reads/All_viral_bacterial.minusTMV.combined.fq.gz -o All_viral_bacterial.minusTMV.combined.deacon.TMV_filt.fq.gz -s All_viral_bacterial.minusTMV.combined.deacon.TMV_filt.summary.json

        Deacon v0.15.0; mode: deplete; input: single; options: abs_threshold=2, rel_threshold=0.01, threads=8(4f+4c)
        Loaded index (k=31, w=15) in 4.35ms
        Retained 24835274/24835287 sequences (100.000%), 127882883577/127882914955 bp (100.000%) in 859.51s. 28895 seqs/s (148.8 Mbp/s)

        "seqs_removed": 13,
        "bp_removed": 31378,
        ```
        To work out which sequences have been removed:
        ```
        # Extract sorted, unique read IDs from each file
        seqkit seq -n ../synth-reads/All_viral_bacterial.minusTMV.combined.fq.gz | sort -u > All_viral_bacterial.minusTMV.combined.ids.txt
        seqkit seq -n All_viral_bacterial.minusTMV.combined.deacon.TMV_filt.fq.gz | sort -u > All_viral_bacterial.minusTMV.combined.deacon.TMV_filt.ids.txt

        # Reads present in file1 but not file2
        comm -23 ids1.txt ids2.txt > only_in_1.txt

        # Reads present in file2 but not file1
        comm -13 ids1.txt ids2.txt > only_in_2.txt

        # Pull the actual FASTQ records for those unique reads
        seqkit grep -f only_in_1.txt file1.fastq.gz -o unique_to_1.fastq.gz
        seqkit grep -f only_in_2.txt file2.fastq.gz -o unique_to_2.fastq.gz
        ```
      - Running against dataset with reference:  
        ```
        deacon filter -d GCF_000854365.deacon.idx ../synth-reads/All_viral_bacterial.combined.fq.gz -o All_viral_bacterial.combined.deacon.TMV_filt.fq.gz -s All_viral_bacterial.combined.deacon.TMV_filt.summary.json
        

        Deacon v0.15.0; mode: deplete; input: single; options: abs_threshold=2, rel_threshold=0.01, threads=8(4f+4c)
        Loaded index (k=31, w=15) in 11.63ms
        Retained 24835274/24835326 sequences (100.000%), 127882883577/127882978905 bp (100.000%) in 947.57s. 26210 seqs/s (135.0 Mbp/s)
        Filter summary saved to "All_viral_bacterial.combined.deacon.TMV_filt.summary.json"

        "seqs_removed": 52
        "bp_removed": 95328
        ```

   - 13 reads (31,378 bp) removed from dataset without TMV spiked in
   - 52 reads (95,328 bp) removed from dataset with TMV spiked in

   - Number of synthetic reads generated for TMV: 39 (63,950 bp):  
   `seqkit stats ../synth-reads/viral/GCF_000854365.1_ViralProj15071_genomic.fna.combined.fq.gz`
       - This suggests that the synthetic reads generated for TMV have been successfully removed from the full dataset (read # from dataset - TMV) - (read # from dataset + TMV)
       - I suspect that the 13 reads present in the total dataset are TMV, but have been included in a reference genome. Will review IDs that match to these sequences, understand which samples they are retrieved from.

   

