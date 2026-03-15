# Anthropofree v.1.0.0

A high-performance Nextflow pipeline for the automated removal of human DNA contaminants (dehosting) from metagenomic sequencing data. Anthropofree is a robust, scalable workflow designed to transform raw metagenomic reads into "clean," non-human datasets. It streamlines quality control, host alignment, and read filtering into a single automated command.

## Features

*   **Sensitive Dehosting:** Uses `bowtie2` in `--very-sensitive` mode to ensure maximum detection of human reads.
*   **High-Fidelity QC:** Leverages `fastp` for adapter trimming and quality filtering ($Q > 25$).
*   **Granular Resource Control:** Directly control sample concurrency (`--parallel`) and per-task threading (`--threads`).
*   **Flexible Hosting:** Point to any host index (Human, Mouse, etc.) without modifying the code.
*   **Smart Resumption:** Built-in check-pointing; use `-resume` to restart from the last successful step.

## Installation

Anthropofree is designed to be installed into a Conda environment for easy dependency management.

### 1. Clone and Enter the Repo
```bash
git clone https://github.com/hsgweon/anthropofree.git
cd anthropofree
```

### 2. Create Environment & Install
```bash
conda env create -f environment.yml
conda activate anthropofree-env
```

## Database Preparation

Before running the pipeline, you must have a Bowtie2 index for the human genome. You can download and prepare the GRCh38 index from NCBI:

```bash
mkdir -p human_index
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_full_analysis_set.fna.bowtie_index.tar.gz
tar -xvf *.tar.gz -C human_index
```

## Usage

### 1. Prepare your Samplesheet
Anthropofree uses a simple comma-separated (`.csv`) file:
*   **Column 1:** Sample Name (e.g., `Patient_A`)
*   **Column 2:** SRR or Library ID (e.g., `SRR12345`)

### 2. Run the Pipeline
> **Note:** Use the base name of your Bowtie2 index (the part before `.1.bt2`).

```bash
anthropofree --input_list samples.csv \
             --rawdata_dir /path/to/fastqs \
             --index human_index/GCA_000001405.15_GRCh38_full_analysis_set.fna.bowtie_index \
             --parallel 10 \
             --threads 16
```

---

## Arguments

| Flag | Description | Default |
| :--- | :--- | :--- |
| `--input_list` | **Required.** Path to CSV file [SampleName, ID]. | `null` |
| `--rawdata_dir` | **Required.** Directory where raw FASTQ files are stored. | `null` |
| `--index` | **Required.** Path to Bowtie2 index base (e.g., `/db/hg38/base_name`). | `null` |
| `--parallel` | Max number of samples to process simultaneously. | `8` |
| `--threads` | CPUs to allocate to each sample. | `4` |
| `--outdir` | Directory to save cleaned reads and QC reports. | `results` |
| `-resume` | Re-run the pipeline skipping completed steps. | `N/A` |
| `--help` | Display the help menu. | `N/A` |

---

## Output Files

| Directory | Content |
| :--- | :--- |
| `results/readqc/` | Trimmed FASTQ files and `fastp` HTML/JSON reports. |
| `results/human_removed/` | **The Final Product:** FASTQ files with human reads removed. |

---

## License
This project is licensed under the MIT License.

## Contact
For questions or to report issues, please open an issue on the GitHub repository.

---

*Would you like me to help you create a `nextflow.config` file so users can store their index path permanently? This would allow them to run the pipeline without typing the long `--index` path every time.*