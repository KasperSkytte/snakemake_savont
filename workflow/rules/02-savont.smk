rule concat_all:
    input:
        expand(
            os.path.join(
                config["tmp_dir"],
                "01-sample_prep",
                "{sample}",
                "{sample}_renamed.fastq",
            ),
            sample=sample_dirs,
        ),
    output:
        temp(os.path.join(config["tmp_dir"], "02-savont", "all_samples_renamed.fastq")),
    log:
        os.path.join(config["log_dir"], "02-savont", "concat_all.log"),
    message:
        "Concatenating all samples before generating ASVs"
    resources:
        mem_mb=1024,
        runtime=30,
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

        # error if output file is empty
        if [ ! -s "{output}" ]; then
            echo "output file {output} is empty, exiting!"
            exit 1
        fi
      """


rule cutadapt:
    input:
        os.path.join(config["tmp_dir"], "02-savont", "all_samples_renamed.fastq"),
    output:
        temp(
            os.path.join(
                config["tmp_dir"],
                "02-savont",
                "all_samples_renamed_oriented_trimmed.fastq",
            )
        ),
    log:
        os.path.join(config["log_dir"], "02-savont", "cutadapt.log"),
    params:
        cutadapt_args=config["cutadapt_args"],
    message:
        "Orienting and trimming reads using cutadapt"
    resources:
        mem_mb=4096,
        runtime=60,
        cpus_per_task=config["max_threads"],
    container:
        "docker://ghcr.io/kasperskytte/snakemake_savont:main"
    conda:
        "../envs/snakemake_savont.yml"
    threads: config["max_threads"]
    shell:
        """
        exec &> "{log}"
        set -euxo pipefail

        # this step both orients and trims at once
        cutadapt {params.cutadapt_args} -o {output} {input} -j {threads}

        # error if output file is empty
        if [ ! -s "{output}" ]; then
            echo "output file {output} is empty, exiting!"
            exit 1
        fi
        """


rule savont_asv:
    input:
        os.path.join(
            config["tmp_dir"],
            "02-savont",
            "all_samples_renamed_oriented_trimmed.fastq",
        ),
    output:
        asvs=os.path.join(config["output_dir"], "savont_output", "final_asvs.fasta"),
        asvs_clean=os.path.join(config["output_dir"], "final_asvs_clean.fasta"),
        savont_latest_log=temp("savont_latest.log"),
    log:
        os.path.join(config["log_dir"], "02-savont", "savont.log"),
    message:
        "Generating ASVs using savont"
    resources:
        mem_mb=300000,  #lambda wc, input: max(3 * input.size_mb, 512),
        runtime=600,
        cpus_per_task=10,
    container:
        "docker://ghcr.io/kasperskytte/snakemake_savont:main"
    conda:
        "../envs/snakemake_savont.yml"
    params:
        savont_asv_args=config["savont_asv_args"],
        savont_outdir=os.path.join(config["output_dir"], "savont_output"),
    threads: 10
    shell:
        """
        exec &> "{log}"
        set -euxo pipefail

        savont asv \
            --output-dir "{params.savont_outdir}" \
            --threads "{threads}" \
            {params.savont_asv_args} \
            {input}

        # error if output file is empty
        if [ ! -s "{output.asvs}" ]; then
            echo "output file {output.asvs} is empty, exiting!"
            exit 1
        fi

        # also output a fasta file with "cleaned" headers, ie no clustering/mapping stats etc
        # for sintax seq IDs to match with (usearch) abundance table IDs
        sed '/^>/ s/ .*//' {output.asvs} > {output.asvs_clean}
    """
