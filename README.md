# Anthropofree v.1.0.0

A high-performance Nextflow pipeline for the automated removal of human DNA contaminants (dehosting) from metagenomic sequencing data. Anthropofree transforms raw reads into "clean," non-human datasets by streamlining quality control, host alignment, and read filtering into a single automated command.

## Features

* **Hybrid Library Support:** Automatically detects and processes both **Paired-End** and **Single-End** libraries within the same run.
* **Sensitive Dehosting:** Uses `bowtie2` in `--very-sensitive` mode for maximum detection of host reads.
* **High-Fidelity QC:** Leverages `fastp` for adapter trimming and quality filtering ($Q > 25$).
* **Flexible Hosting:** Point to any host index (Human, Mouse, Rat, etc.) without modifying the code.
* **Automatic Cleanup:** Optional flag to wipe temporary `work/` and log files upon successful completion to save disk space.

---

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/hsgweon/anthropofree.git
cd anthropofree
```

### 2. Create Environment & Install
```bash
conda env create -f environment.yml
conda activate anthropofree-env
pip install -e .
```

---

## Database Preparation

### 1. Human Genome (Pre-built)
If you are dehosting human reads, you can download the pre-built GRCh38 index:

```bash
mkdir -p human_index
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_full_analysis_set.fna.bowtie_index.tar.gz
tar -xvf *.tar.gz -C human_index
```

### 2. Custom Host Databases (Example: Rat)
Anthropofree is host-agnostic. To remove DNA from a different species, you must download the FASTA and build a Bowtie2 index.

**Example: Building a Rat (*Rattus norvegicus*) index**

1.  **Download the FASTA:**
    ```bash
    mkdir -p rat_index
    wget -P rat_index/ https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/015/227/675/GCF_015227675.2_mRatBN7.2/GCF_015227675.2_mRatBN7.2_genomic.fna.gz
    gunzip rat_index/*.gz
    ```

2.  **Build the Index:**
    ```bash
    # Usage: bowtie2-build <reference_fasta> <index_base_name>
    bowtie2-build --threads 16 rat_index/GCF_015227675.2_mRatBN7.2_genomic.fna rat_index/rat_mRatBN7
    ```

3.  **Run the Pipeline:**
    Point the `--index` flag to the newly created index base:
    ```bash
    anthropofree --input_list samplesheet.csv --rawdata_dir ./fastq --index rat_index/rat_mRatBN7
    ```

---

## Usage

### 1. Prepare your Samplesheet
The pipeline maps files based on their position in the row. This ensures it works regardless of naming conventions.

| Column 1 (sample) | Column 2 (fastq_1) | Column 3 (fastq_2) |
| :--- | :--- | :--- |
| Sample_01 | P01_R1.fastq.gz | P01_R2.fastq.gz |
| Sample_02 | P02_single.fastq.gz | *(Leave empty for SE)* |

**Example `samplesheet.csv`:**
```csv
sample,fastq_1,fastq_2
Patient_A,A_R1.fq.gz,A_R2.fq.gz
Patient_B,B_single.fq.gz,
```

### 2. Run the Command
```bash
anthropofree --input_list samplesheet.csv \
             --rawdata_dir ./fastq \
             --index human_index/GCA_000001405.15_GRCh38_full_analysis_set.fna.bowtie_index \
             --parallel 10 \
             --threads 16 \
             --cleanup true
```

---

## Arguments

| Flag | Description | Default |
| :--- | :--- | :--- |
| `--input_list` | **Required.** Path to CSV [sample, fastq_1, fastq_2]. | `null` |
| `--rawdata_dir` | **Required.** Directory containing the FASTQ files. | `null` |
| `--index` | **Required.** Path to Bowtie2 index base. | `null` |
| `--parallel` | Max number of samples to process simultaneously. | `8` |
| `--threads` | CPUs to allocate to each task (fastp/bowtie2). | `4` |
| `--outdir` | Directory to save cleaned reads and QC reports. | `results` |
| `--cleanup` | If `true`, deletes `work/` and logs on success. | `false` |
| `-resume` | Restart pipeline skipping completed steps. | `N/A` |

---

## Output Files

| Directory | Content |
| :--- | :--- |
| `results/readqc/` | Trimmed FASTQ files and `fastp` HTML/JSON reports. |
| `results/human_removed/` | **The Final Product:** FASTQ files with host reads removed. |

---

## License
This project is licensed under the MIT License.

## Contact
For questions or to report issues, please open an issue on the GitHub repository.