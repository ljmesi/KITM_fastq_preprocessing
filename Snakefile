
from pathlib import Path

configfile: "config.yml"

#### MAX_READ_LENGTH
MAX_READ_LENGTH: str = config.get("max_read_length")
print(f"Maximum length of the reads is '{MAX_READ_LENGTH}'")

#### Input directory
PREFIX: str = config.get("input")
print(f"Looking for fastq files under '{PREFIX}'")

#### BATCH_NAME used for making sure that logs are stored in correct batch subdirectory
BATCH_NAME: str = str(Path(PREFIX).parts[-1])

#### OUTPUT directory
OUTPUT: str = config.get("output")
print(f"Results will go under '{OUTPUT}'")

#### Input files for pretrim seqkit stats
FILES = glob_wildcards(f"{PREFIX}/{{week}}/{{sample}}.fastq.gz")
WEEKS_NAMES: list[str] = [f"{w}/{n}" for w, n in zip(FILES.week, FILES.sample)]
print(f"Weeks sample names: '{WEEKS_NAMES}'")
INPUT_FASTQS: list[str] = [f"{PREFIX}/{base}.fastq.gz" for base in WEEKS_NAMES]

#### Output files for pretrim fastqc
PRETRIM_FASTQC: list[str] = expand("{output}/pretrim/{week_name}_fastqc.html", output=OUTPUT, week_name=WEEKS_NAMES)

#### output files for fastp
R1 = glob_wildcards(f"{PREFIX}/{{week}}/{{sample}}_L001_R1_001.fastq.gz")
R2 = glob_wildcards(f"{PREFIX}/{{week}}/{{sample}}_L001_R2_001.fastq.gz")
R1_TRIMMED: list[str] = [f"{OUTPUT}/trim/{w}/{n}_L001_R1_001.trim.fastq.gz" for w, n in zip(R1.week, R1.sample)]
R2_TRIMMED: list[str] = [f"{OUTPUT}/trim/{w}/{n}_L001_R2_001.trim.fastq.gz" for w, n in zip(R2.week, R2.sample)]

#### Maximum number cores available on this machine
MAX_CORES = 92

################################################################

def compute_num_cores(num_input_fastqs: int, max_num_cores: int = MAX_CORES):
    if num_input_fastqs <= max_num_cores:
        return num_input_fastqs
    else:
        return max_num_cores

NUM_CORES = compute_num_cores(len(WEEKS_NAMES))
print(f'Number of cores: {NUM_CORES}')

################################################################

# request the output files
rule all:
    input:
        # use the extracted 'name' values to build new filenames                
        PRETRIM_FASTQC,
        f"{OUTPUT}/pretrim/pretrim_seqkit_stats.tsv",
        R1_TRIMMED,
        R2_TRIMMED,
        f"{OUTPUT}/posttrim/posttrim_seqkit_stats.tsv",
        expand("{output}/posttrim/{week_name}.trim_fastqc.html", output=OUTPUT, week_name=WEEKS_NAMES),
        f"{OUTPUT}/multiqc_report.html",


# Fastqc before trimming
rule pretrim_fastqc:
    input:
        f"{PREFIX}/{{week}}/{{name}}.fastq.gz",
    output:
        f"{OUTPUT}/pretrim/{{week}}/{{name}}_fastqc.html",
    params:
        f"{OUTPUT}/pretrim/",
    log:
        f"logs/{BATCH_NAME}/pretrim/{{week}}/{{name}}.log",
    shell:
        """
        (fastqc \
        --threads 1 \
        -o {params}/{wildcards.week} \
        {input}) &> {log}
        """


# pre_trim seqkit stats
rule pretrim_seqkit_stats:
    input:
        INPUT_FASTQS,
    output:
        f"{OUTPUT}/pretrim/pretrim_seqkit_stats.tsv",
    log:
        f"logs/{BATCH_NAME}/pretrim/pretrim_seqkit_stats.log",
    params:
        cores=NUM_CORES,
    shell:
        """
        seqkit stats \
        --all \
        --tabular \
        -j {params.cores} \
        {input} > {output} &> {log}
        """


# Trimming with fastp
rule fastp:
    input:
        r1=f"{PREFIX}/{{week}}/{{sample}}_L001_R1_001.fastq.gz",
        r2=f"{PREFIX}/{{week}}/{{sample}}_L001_R2_001.fastq.gz",
    output:
        r1=f"{OUTPUT}/trim/{{week}}/{{sample}}_L001_R1_001.trim.fastq.gz",
        r2=f"{OUTPUT}/trim/{{week}}/{{sample}}_L001_R2_001.trim.fastq.gz",
        json=f"{OUTPUT}/trim/{{week}}/{{sample}}.fastp.json",
    params:
        max_len=MAX_READ_LENGTH,
        trim_dir=lambda w, output: str(Path(output.r1).parts[0]/Path("trim")),  #f"{OUTPUT}/trim",
    log:
        f"logs/{BATCH_NAME}/trim/{{week}}/{{sample}}_trim.log",
    shell:
        """
        (fastp \
        -i {input.r1} \
        -I {input.r2} \
        -o {output.r1} \
        -O {output.r2} \
        -b {params.max_len} \
        -B {params.max_len} \
        --html {params.trim_dir}/fastp.html \
        --json {output.json}) &> {log}
        """


# post trimming seqkit stats
rule posttrim_seqkit_stats:
    input:
        R1_TRIMMED + R2_TRIMMED,
    output:
        f"{OUTPUT}/posttrim/posttrim_seqkit_stats.tsv",
    params:
        cores=NUM_CORES,
    log:
        f"logs/{BATCH_NAME}/posttrim/posttrim_seqkit_stats.log",
    shell:
        """
        seqkit stats \
        --all \
        --tabular \
        -j {params.cores} \
        {input} > {output} &> {log}
        """


# post trimming fastqc
rule posttrim_fastqc:
    input:
        f"{OUTPUT}/trim/{{week}}/{{name}}.trim.fastq.gz",
    output:
        f"{OUTPUT}/posttrim/{{week}}/{{name}}.trim_fastqc.html",
    params:
        f"{OUTPUT}/posttrim/",
    log:
        f"logs/{BATCH_NAME}/posttrim/{{week}}/fastqc_{{name}}.log",
    shell:
        """
        (fastqc \
        --threads 1 \
        -o {params}/{wildcards.week} \
        {input}) &> {log}
        """


# multiqc
rule multiqc:
    input:
        R1_TRIMMED + R2_TRIMMED + PRETRIM_FASTQC,
    output:
        f"{OUTPUT}/multiqc_report.html",
    params:
        look_dir=lambda w, output: str(Path(output[0]).parts[0]/Path(BATCH_NAME)),
    log:
        f"logs/{BATCH_NAME}/posttrim/multiqc.log",
    shell:
        """
        multiqc \
        --outdir {params.look_dir} \
        --force \
        {params.look_dir} &> {log}
        """
