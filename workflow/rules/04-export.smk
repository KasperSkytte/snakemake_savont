rule savont_export:
    input:
        asvs=expand(
            os.path.join(config["tmp_dir"], "02-asv", "{run}", "final_asvs.fasta"),
            run=runs,
        ),
        tables=expand(
            os.path.join(config["tmp_dir"], "02-asv", "{run}", "feature-table.tsv"),
            run=runs,
        ),
        samples=expand(
            os.path.join(config["tmp_dir"], "02-asv", "{run}", "samples.txt"),
            run=runs,
        ),
        mappings=(
            expand(
                os.path.join(config["tmp_dir"], "02-asv", "{run}", "asv_mappings.tsv"),
                run=runs,
            )
            if config["classify_savont"]
            else []
        ),
    output:
        asvs=result("asvs.fasta"),
        table=result("abund_table_savont.tsv"),
        # only written by savont export if ASVs have been classified
        classified=(
            [result("taxonomy_savont.tsv"), result("taxon_counts_savont.tsv")]
            if config["classify_savont"]
            else []
        ),
    log:
        os.path.join(config["log_dir"], "04-export", "savont_export.log"),
    conda:
        "../envs/savont.yml"
    container:
        savont_container
    threads: 1
    resources:
        mem_mb=scaled(180, 1),
        runtime=scaled(30, 0.1),
    params:
        tmp_dir=os.path.join(config["tmp_dir"], "04-export"),
        n_samples=len(samples),
        min_reads=config["min_reads"],
        log_dir=config["log_dir"],
    message:
        "Merging ASVs and abundances of all samples using savont export"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail

        # runs without ASVs are left out
        dirs=()
        labels=()
        n_used=0
        for f in {input.asvs}; do
            n_used=$((n_used + $(grep -c . "$(dirname "$f")/samples.txt" || true)))
            if [ -s "$f" ]; then
                dirs+=("$(dirname "$f")")
                labels+=($(cat "$(dirname "$f")/samples.txt"))
            else
                echo "No ASVs found in $(dirname "$f"), left out"
            fi
        done

        # stop with an explanation instead of a savont export usage error
        if [ ${{#dirs[@]}} -eq 0 ]; then
            set +x
            echo "ERROR: no ASVs were found in any of the {params.n_samples} samples, so there is nothing to export."
            echo "${{n_used}} of the {params.n_samples} samples had at least {params.min_reads} reads (min_reads) after primer"
            echo "trimming and were used for savont asv."
            echo "If (almost) no samples were used, check the primers in cutadapt_args and the logs in"
            echo "{params.log_dir}/01-trim/."
            echo "Otherwise the reads are probably too inaccurate: savont asv only uses reads with an"
            echo "estimated accuracy of at least --quality-value-cutoff (default 98%) and only keeps ASVs"
            echo "supported by at least --min-cluster-size reads (default 12). Reads from older chemistry"
            echo "(fx R9.4.1) or fast/hac basecalling are often below the cutoff. See the savont logs in"
            echo "{params.log_dir}/02-asv/, then rebasecall the reads with a sup model, or lower"
            echo "--quality-value-cutoff and --minimum-base-quality in savont_asv_args in the config."
            exit 1
        fi

        rm -rf "{params.tmp_dir}"
        savont export \
            --input-dirs "${{dirs[@]}}" \
            --output-dir "{params.tmp_dir}" \
            --relabel "${{labels[@]}}"

        mv "{params.tmp_dir}/merged_rep_seqs.fasta" "{output.asvs}"
        mv "{params.tmp_dir}/merged_feature_table.tsv" "{output.table}"
        set -- {output.classified}
        if [ $# -eq 2 ]; then
            mv "{params.tmp_dir}/merged_asv_taxonomy.tsv" "$1"
            mv "{params.tmp_dir}/merged_taxon_counts.tsv" "$2"
        fi
        rm -rf "{params.tmp_dir}"
        """
