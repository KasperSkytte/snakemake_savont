rule savont_asv:
    input:
        reads=lambda wc: expand(
            os.path.join(config["tmp_dir"], "01-trim", "{sample}.fastq.gz"),
            sample=run_samples(wc),
        ),
        counts=lambda wc: expand(
            os.path.join(config["tmp_dir"], "01-trim", "{sample}.tsv"),
            sample=run_samples(wc),
        ),
    output:
        asvs=temp(
            os.path.join(config["tmp_dir"], "02-asv", "{run}", "final_asvs.fasta")
        ),
        table=temp(
            os.path.join(config["tmp_dir"], "02-asv", "{run}", "feature-table.tsv")
        ),
        samples=temp(os.path.join(config["tmp_dir"], "02-asv", "{run}", "samples.txt")),
    log:
        os.path.join(config["log_dir"], "02-asv", "{run}.log"),
    benchmark:
        os.path.join(config["log_dir"], "02-asv", "{run}.benchmark.tsv")
    conda:
        "../envs/savont.yml"
    container:
        savont_container
    # savont only uses ~8 cores efficiently
    threads: min(config["threads"], 8)
    resources:
        # measured up to 4.7GB for 180MB of gzipped reads, peak use is ~75% of this
        mem_mb=scaled(896, 40, config["max_mem_mb"]),
        runtime=scaled(30, 0.1),
    params:
        pooled="--pooled-samples" if config["pool_samples"] else "",
        min_reads=config["min_reads"],
        savont_asv_args=config["savont_asv_args"],
    message:
        "{wildcards.run}: Generating ASVs using savont"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail
        outdir="$(dirname "{output.asvs}")"

        # savont fails on samples with (almost) no reads, leave them out
        reads=()
        for f in {input.reads}; do
            n=$(cut -f3 "${{f%.fastq.gz}}.tsv")
            if [ "$n" -ge {params.min_reads} ]; then
                reads+=("$f")
                basename "$f" .fastq.gz >>"{output.samples}"
            else
                echo "Leaving out $f, only $n reads after trimming"
            fi
        done

        if [ ${{#reads[@]}} -gt 0 ]; then
            savont asv {params.pooled} "${{reads[@]}}" \
                --output-dir "$outdir" \
                --threads {threads} \
                {params.savont_asv_args}
            # intermediate files and read assignments take up a lot of space
            rm -rf "$outdir/temp" "$outdir/final_assignments.tsv" "$outdir"/savont_*.log
        fi
        # empty outputs if no samples are left
        touch {output}
        """
