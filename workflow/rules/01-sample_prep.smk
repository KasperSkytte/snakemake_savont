rule sample_prep:
    input:
        # function to list all fastq files per wildcard (subfolder/sample)
        # see https://snakemake.readthedocs.io/en/latest/snakefiles/rules.html#input-functions
        lambda wildcards: (
            glob.glob(
                os.path.join(config["input_dir"], wildcards.sample, "**", "*.fastq"),
                recursive=True,
            )
            + glob.glob(
                os.path.join(config["input_dir"], wildcards.sample, "**", "*.fq"),
                recursive=True,
            )
            + glob.glob(
                os.path.join(
                    config["input_dir"], wildcards.sample, "**", "*.fastq.gz"
                ),
                recursive=True,
            )
            + glob.glob(
                os.path.join(config["input_dir"], wildcards.sample, "**", "*.fq.gz"),
                recursive=True,
            )
        ),
    output:
        fastq=touch(
            temp(
                os.path.join(
                    config["tmp_dir"], "01-sample_prep", "{sample}", "{sample}.fastq"
                )
            )
        ),
        total_reads_file=touch(
            temp(
                os.path.join(
                    config["tmp_dir"],
                    "01-sample_prep",
                    "totalreads",
                    "{sample}_totalreads.csv",
                )
            )
        ),
        sample_renamed=touch(
            temp(
                os.path.join(
                    config["tmp_dir"],
                    "01-sample_prep",
                    "{sample}",
                    "{sample}_renamed.fastq",
                )
            )
        ),
    log:
        os.path.join(config["log_dir"], "01-sample_prep", "sample_prep_{sample}.log"),
    resources:
        mem_mb=lambda wc, input: max(10 * input.size_mb, 2048),
        runtime=10,
        cpus_per_task=1,
    container:
        "docker://ghcr.io/kasperskytte/snakemake_savont:main"
    conda:
        "../envs/snakemake_savont.yml"
    params:
        sample_sep=config["sample_sep"],
    threads: 1
    message:
        "{wildcards.sample}: Filtering and preparing reads"
    shell:
        """
        exec &> "{log}"
        set -euxo pipefail
        
        # decompress only if compressed, but concatenate regardless
        echo "*** Decompressing and concatenating fastq files"
        gunzip -cdfq {input} > {output.fastq}

        # calc total number of reads
        echo "*** Calculating total number of reads before any filtering"
        num_reads=$(grep -c '^+$' {output.fastq} || true)
        echo "{wildcards.sample},$num_reads" > "{output.total_reads_file}"

        echo "*** Renaming reads with sample name"
        usearch -fastx_relabel \
          "{output.fastq}" \
          -prefix "{wildcards.sample}{params.sample_sep}" \
          -fastqout "{output.sample_renamed}"
        """


rule concatenate_total_reads_files:
    input:
        expand(
            os.path.join(
                config["tmp_dir"],
                "01-sample_prep",
                "totalreads",
                "{sample}_totalreads.csv",
            ),
            sample=sample_dirs,
        ),
    output:
        os.path.join(config["output_dir"], "totalreads.csv"),
    log:
        os.path.join(
            config["log_dir"], "01-sample_prep", "concatenate_total_reads_files.log"
        ),
    message:
        "Concatenating total reads files"
    resources:
        mem_mb=512,
        runtime=10,
        cpus_per_task=1,
    container:
        "docker://ghcr.io/kasperskytte/snakemake_savont:main"
    conda:
        "../envs/snakemake_savont.yml"
    threads: 1
    shell:
        """
        exec &> "{log}"
        set -euxo pipefail
        
        cat {input} > {output}
        """
