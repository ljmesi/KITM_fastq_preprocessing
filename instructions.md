## Introduction

This snakemake 7.14.0 pipeline performs the following steps:

1. Pretrim
   1. [Fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
   2. [SeqKit stats](https://bioinf.shenwei.me/seqkit/usage/#stats)
2. Trim
   1. [Fastp](https://github.com/OpenGene/fastp)
3. Posttrim
   1. [SeqKit stats](https://bioinf.shenwei.me/seqkit/usage/#stats)
   2. [Fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
   3. [MultiQC](https://multiqc.info/)

## Input files

### Input directories

The input files should be placed in: `/home/lauri/Desktop/KITM_fastq_preprocessing/data/<__>/v<__>`, where:

- `<__>` is the name of the batch of input files. It can be named freely but **avoid** the following characters in the directory name: white space (tab, newline or space), `<`, `>`, `|`, `\`, `:`, `(`, `)`, `&`, `;`, `?` and `*`.
Examples of valid batch names are: `1`, `v15_16_18`, or `oktober1`.
- `v<__>` is the directory for the week, e.g. `v15`, `v1` or `v51`. There can be multiple week directories in the batch directory.

The relative path to the batch directory **must** be defined in the `config.yml` file. E.g. if you have decided to copy the input week directories to `data/okt_nov`, the second line in `config.yml` must be:

```yml
input: "data/okt_nov"
```

The pipeline will discover all the week directories in the batch directory and use all the fastq files in those directories as input.

### Input fastq files

The input fastq file names **must** follow a certain pattern. They must end with `_L001_R1_001.fastq.gz` or `_L001_R2_001.fastq.gz` and these must be preceded by unique sample names which **must not** contain any of the aforementioned disallowed characters.

As an example here is an illustration of a valid set of input files for running the pipeline:

```txt
data
└── v15_16_18
    ├── v15
    │   ├── 1A_S21_L001_R1_001.fastq.gz
    │   ├── 1A_S21_L001_R2_001.fastq.gz
    │   ├── 1B_S22_L001_R1_001.fastq.gz
    │   ├── 1B_S22_L001_R2_001.fastq.gz
    │   ├── 1C_S23_L001_R1_001.fastq.gz
    │   └── 1C_S23_L001_R2_001.fastq.gz
    ├── v16
    │   ├── 2A_S19_L001_R1_001.fastq.gz
    │   ├── 2A_S19_L001_R2_001.fastq.gz
    │   ├── 2B1_S20_L001_R1_001.fastq.gz
    │   ├── 2B1_S20_L001_R2_001.fastq.gz
    │   ├── 2B2_S21_L001_R1_001.fastq.gz
    │   ├── 2B2_S21_L001_R2_001.fastq.gz
    │   ├── 2B3_S22_L001_R1_001.fastq.gz
    │   ├── 2B3_S22_L001_R2_001.fastq.gz
    │   ├── 2C_S23_L001_R1_001.fastq.gz
    │   ├── 2C_S23_L001_R2_001.fastq.gz
    │   ├── 2D_S24_L001_R1_001.fastq.gz
    │   └── 2D_S24_L001_R2_001.fastq.gz
    └── v18
        ├── 3A_S23_L001_R1_001.fastq.gz
        ├── 3A_S23_L001_R2_001.fastq.gz
        ├── 3B_S24_L001_R1_001.fastq.gz
        ├── 3B_S24_L001_R2_001.fastq.gz
        ├── 3C1_S25_L001_R1_001.fastq.gz
        ├── 3C1_S25_L001_R2_001.fastq.gz
        ├── 3C2_S26_L001_R1_001.fastq.gz
        ├── 3C2_S26_L001_R2_001.fastq.gz
        ├── 3C3_S27_L001_R1_001.fastq.gz
        ├── 3C3_S27_L001_R2_001.fastq.gz
        ├── 3D-E10p_S31_L001_R1_001.fastq.gz
        ├── 3D-E10p_S31_L001_R2_001.fastq.gz
        ├── 3D-E1p_S30_L001_R1_001.fastq.gz
        ├── 3D-E1p_S30_L001_R2_001.fastq.gz
        ├── 3D-E25p_S32_L001_R1_001.fastq.gz
        ├── 3D-E25p_S32_L001_R2_001.fastq.gz
        ├── 3D_S28_L001_R1_001.fastq.gz
        ├── 3D_S28_L001_R2_001.fastq.gz
        ├── 3E_S29_L001_R1_001.fastq.gz
        └── 3E_S29_L001_R2_001.fastq.gz
```

## Running the trimming and qc pipeline

For running the pipeline follow these steps:

0. Copy the input files into correct directories inside your input batch directory. Make sure that the input parameter and output parameters are correct in the `config.yml` file. In addition, make sure that your current working directory is this project directory (`/home/lauri/Desktop/KITM_MiSeq-data_preprocessing`) with e.g.:

```bash
cd /home/lauri/Desktop/KITM_MiSeq-data_preprocessing
```

1. Run the pipeline with command:

```bash
make
```

## Results

The results will appear in the directory defined by `output` parameter in `config.yml`.

*Tip: The name of the output parameter **must be** the same as the input batch directory name.*

So, e.g. if you have input as following:

```yml
input: "data/v15_16_18"
```

name the output parameter to have the same batch name:

```yml
output: "results/v15_16_18"
```

In this way you won't mix up results from different batches.

### Trimmed reads

The trimmed reads are located inside the `trim` directory in results.

### QC files

Pretrim qc, posttrim qc and multiqc are located in: `pretrim`, `posttrim` and in the root of the results directory respectively. Note that `seqkit stats` results will not appear in the `multiqc_report.html`.
