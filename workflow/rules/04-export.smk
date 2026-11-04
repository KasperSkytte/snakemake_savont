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
    message:
        "Merging ASVs and abundances of all samples using savont export"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail

        # runs without ASVs are left out
        dirs=()
        labels=()
        for f in {input.asvs}; do
            if [ -s "$f" ]; then
                dirs+=("$(dirname "$f")")
                labels+=($(cat "$(dirname "$f")/samples.txt"))
            fi
        done

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
