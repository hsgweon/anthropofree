# Anthropofree v.1.0.0

A high-performance Nextflow pipeline for the automated removal of human DNA contaminants (dehosting) from metagenomic sequencing data.

**Anthropofree** is a robust, scalable workflow designed to transform raw metagenomic reads into "clean," non-human datasets. It streamlines the complex process of quality control, host alignment, and read filtering into a single command.

The pipeline is particularly suited for clinical metagenomics, forensic analysis, or any research where human DNA background interferes with microbial signal or raises privacy concerns.

## Features

-   Automated Host Indexing: Automatically downloads and prepares the GRCh38 human reference genome.
-   High-Fidelity QC: Leverages fastp for adapter trimming, quality filtering, and base correction.
-   Sensitive Dehosting: Uses bowtie2 in --very-sensitive mode to ensure maximum detection of human-derived reads.
-   Precision Filtering: Utilises seqkit for high-speed retrieval of non-human reads, maintaining the integrity of paired-end data.
-   Native Parallelism: Powered by Nextflow, allowing it to process hundreds of samples simultaneously across local machines or HPC clusters
-   Smart Resumption: Includes built-in check-pointing; if a run is interrupted, use -resume to pick up exactly where it left off.
-   Resource Efficiency: Implements a "one-time" download strategy for reference genomes to save bandwidth and disk space.

## Pipeline Workflow
The workflow executes the following stages:
1.  Reference Setup: Downloads the GRCh38 full analysis set and extracts the Bowtie2 index.
2.  Read QC (fastp): Performs quality trimming ($Q > 25$), length filtering ($>100bp$), and adapter detection.
3.  Host Mapping (bowtie2): Maps reads against the human reference.
4.  Read Extraction (samtools & seqkit): Extracts read IDs that failed to map (non-human) and retrieves the corresponding sequences from the original FASTQ files.
5.  Aggregation: Groups processed files by Sample ID for downstream analysis (e.g., assembly or taxonomic profiling).

## Installation
### Prerequisites:
-   `conda` (or miniconda/mamba)
-   `nextflow` (installed via conda or manually)

**1.  Clone the Repository**
```bash
git clone https://github.com/hsgweon/anthropofree.git
cd anthropofree
```

**2. Create the Conda Environment**

Create a self-contained environment with all necessary dependencies (`fastp`, `bowtie2`, `samtools`, `seqkit`).

```bash
conda env create -f environment.yml
conda activate anthropofree-env
```

## Usage

### 1. Prepare your Samplesheet
Anthropofree uses a simple comma-separated (`.csv`) or list (`.lst`) file.
-   Column 1: Sample Name (e.g., Patient_A)
-   Column 2: SRR or Library ID (e.g., SRR12345)
Example `samplelist.csv`:
```bash
Sample_01,SRR192031
Sample_01,SRR192032
Sample_02,SRR192040
```

### 2. Run the Pipeline
```bash
run main.nf \
    --input_list samplelist.csv \
    --rawdata_dir /path/to/fastqs \
    --outdir results \
    --parallel 10 \
    --threads 16
```

### Arguments

### Configuration Flags

| Flag | Description | Default |
| :--- | :--- | :--- |
| `--input_list` | Path to the CSV/LST file containing sample names and IDs. | `samplelist.lst` |
| `--rawdata_dir` | Directory where your raw FASTQ files are stored. | `rawdata` |
| `--outdir` | Directory to save the cleaned reads and QC reports. | `results` |
| `--parallel` | Max number of samples to process simultaneously. | `8` |
| `--threads` | CPUs to allocate to each sample (e.g., for Bowtie2). | `4` |
| `-resume` | Re-run the pipeline skipping already completed steps. | `N/A` |
| `-help` | Display the help menu. | `N/A` |

---

### Output Files

| Directory | Content |
| :--- | :--- |
| `results/readqc/` | Cleaned, trimmed FASTQ files and fastp HTML reports. |
| `results/human_removed/` | **The Final Product:** FASTQ files with human reads removed. |
| `reference_genome/` | The downloaded and indexed human reference (stored for future use). |

---

### Implementation Details

#### Handling Ambiguity
By default, Anthropofree identifies human reads by capturing any read that aligns to the reference. It uses `samtools view -F 12` to identify reads where neither the read nor its mate mapped to the host, ensuring that even partially human fragments are excluded for maximum stringency.

#### Resource Management
The pipeline is designed to be "machine-aware."
-   If you have a 64-core machine, you could run `--parallel 4 --threads 16` to process 4 samples at once, giving each one 16 cores.

## License
This project is licensed under the MIT License.

## Contact
For questions or to report issues, please open an issue on the GitHub repository.


