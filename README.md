# Reference  Removal

An application that takes in reference genome and looks to remove it from fastq datasets. Statistical sumamry will be provided for the reference sequence that has been removed from the sample.

An additional component can be used which will test how effectively a reference is removed from either a supplied dataset or a downloaded dataset.

## Validation
## Input data
- Reference FASTA (required)
- Reference IDX. Index created by Deacon (Optional)
- Samplesheet (Optional)
    - Column 1: Sample ID; Column 2: Read 1; Column 3: Read 2 (for paired-end only)


## To Do
- [x] Set up README    
- [x] Set up Nextflow config  
- [x] Read in reference FASTA    
- [ ] Read in FASTA | FASTQ to remove reference from  
- [ ] Download example FASTA to remove reference from
- [ ] Generate synthetic reads for reference FASTA [Optional]  
- [ ] Generate synthetic reads for background FASTA [Optional]  
- [ ] Spike reference reads into into background FASTA [Optional]  
- [ ] Generate index for Reference FASTA
- [ ] Remove reference from background FASTQ
- [ ] Generate summary statistics