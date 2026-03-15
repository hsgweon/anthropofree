nextflow.enable.dsl=2

// Default Parameters
params.input_list = "samplelist.lst"
params.rawdata_dir = "rawdata"
params.outdir = "results"
params.parallel = 8    // How many samples to run at once
params.threads = 4     // How many CPUs per task
params.help = false

// Help Message
if (params.help) {
    log.info """
    Anthropofree - Human Read Removal Pipeline
    ==========================================
    Usage:
    nextflow run main.nf --input_list list.csv --rawdata_dir ./reads [options]

    Options:
    --parallel      Maximum number of samples to process in parallel (Default: ${params.parallel})
    --threads       Number of CPUs to allocate per task (Default: ${params.threads})
    --outdir        Directory to save results (Default: ${params.outdir})
    --help          Display this help message
    """
    exit 0
}

process DOWNLOAD_INDEX {
    storeDir "reference_genome"
    output: path "human_index/", emit: index_files
    script:
    """
    wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_full_analysis_set.fna.bowtie_index.tar.gz
    mkdir -p human_index
    tar -xvf *.tar.gz -C human_index --strip-components=1
    """
}

process FASTP_QC {
    tag "$srr_id"
    cpus params.threads
    maxForks params.parallel
    publishDir "${params.outdir}/readqc", mode: 'copy'

    input:
    tuple val(sample_name), val(srr_id), path(reads)

    output:
    tuple val(sample_name), val(srr_id), path("${srr_id}_{1,2}.fastp.fastq.gz"), emit: qc_reads
    path "${srr_id}.fastp.{json,html}"

    script:
    """
    fastp --in1 ${reads[0]} --in2 ${reads[1]} \
          --out1 ${srr_id}_1.fastp.fastq.gz --out2 ${srr_id}_2.fastp.fastq.gz \
          --json ${srr_id}.fastp.json --html ${srr_id}.fastp.html \
          --thread ${task.cpus} --detect_adapter_for_pe -q 25 --length_required 100
    """
}

process REMOVE_HUMAN {
    tag "$srr_id"
    cpus params.threads
    maxForks params.parallel
    publishDir "${params.outdir}/human_removed", mode: 'copy'

    input:
    tuple val(sample_name), val(srr_id), path(reads)
    path index_dir

    output:
    tuple val(sample_name), path("${srr_id}_{1,2}.clean.fastq.gz"), emit: clean_reads

    script:
    def index_base = "${index_dir}/GCA_000001405.15_GRCh38_full_analysis_set.fna.bowtie_index"
    """
    bowtie2 -p ${task.cpus} --very-sensitive -x ${index_base} -1 ${reads[0]} -2 ${reads[1]} | \
    samtools view -F 12 | cut -f1 | sort -u > human_ids.txt

    seqkit grep -v -f human_ids.txt ${reads[0]} | seqkit seq -i -o ${srr_id}_1.clean.fastq.gz
    seqkit grep -v -f human_ids.txt ${reads[1]} | seqkit seq -i -o ${srr_id}_2.clean.fastq.gz
    """
}

workflow {
    ch_sample_list = Channel.fromPath(params.input_list)
        .splitCsv()
        .map { row -> 
            def sample_name = row[0]
            def srr_id = row[1]
            def reads = file("${params.rawdata_dir}/${srr_id}*_{1,2}*")
            return [ sample_name, srr_id, reads.sort() ]
        }

    DOWNLOAD_INDEX()
    FASTP_QC(ch_sample_list)
    REMOVE_HUMAN(FASTP_QC.out.qc_reads, DOWNLOAD_INDEX.out.index_files)
}