# reads are streamed through cutadapt, so no uncompressed copies are made
rule trim:
    input:
        sample_fastqs,
    output:
        reads=temp(os.path.join(config["tmp_dir"], "01-trim", "{sample}.fastq.gz")),
        counts=temp(os.path.join(config["tmp_dir"], "01-trim", "{sample}.tsv")),
    log:
        log=os.path.join(config["log_dir"], "01-trim", "{sample}.log"),
        json=os.path.join(config["log_dir"], "01-trim", "{sample}.cutadapt.json"),
    conda:
        "../envs/cutadapt.yml"
    container:
        cutadapt_container
    threads: 1
    resources:
        # measured ~150MB + 0.7MB per MB of reads
        mem_mb=scaled(192, 1),
        runtime=scaled(30, 0.05),
    params:
        cutadapt_args=config["cutadapt_args"],
        cat_fastq=workflow.source_path("../scripts/cat_fastq.py"),
    message:
        "{wildcards.sample}: Trimming primers and orienting reads using cutadapt"
    shell:
        """
        exec &>"{log.log}"
        set -euxo pipefail

        # gzipped or not, files that are cut off are used up to the last complete
        # read and noted in this log
        python3 "{params.cat_fastq}" {input} \
            | cutadapt {params.cutadapt_args} -j {threads} -Z --json "{log.json}" -o "{output.reads}" -

        # sample, number of reads before and after trimming
        python3 -c 'import json, sys; c = json.load(open(sys.argv[1]))["read_counts"]; print(sys.argv[2], c["input"], c["output"], sep="\\t")' \
            "{log.json}" "{wildcards.sample}" >"{output.counts}"
        """


rule read_counts:
    input:
        expand(
            os.path.join(config["tmp_dir"], "01-trim", "{sample}.tsv"),
            sample=samples,
        ),
    output:
        os.path.join(config["output_dir"], "read_counts.tsv"),
    log:
        os.path.join(config["log_dir"], "01-trim", "read_counts.log"),
    conda:
        "../envs/cutadapt.yml"
    container:
        cutadapt_container
    threads: 1
    resources:
        mem_mb=scaled(150, 0),
        runtime=scaled(10, 0),
    message:
        "Gathering read counts"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail

        (
            printf "sample\\treads\\treads_trimmed\\n"
            cat {input}
        ) >"{output}"
        """
