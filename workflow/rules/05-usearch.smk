# both use the merged ASVs from savont export, so the ASV IDs match
# those in the savont tables
rule sintax_classify:
    input:
        asvs=result("asvs.fasta"),
        db=config["sintax_db"],
    output:
        result("taxonomy_sintax.tsv"),
    log:
        os.path.join(config["log_dir"], "05-usearch", "sintax_classify.log"),
    conda:
        "../envs/usearch.yml"
    container:
        usearch_container
    threads: config["threads"]
    resources:
        mem_mb=scaled(1024, 10),
        runtime=scaled(60, 0),
    params:
        classify_usearch_sintax_args=config["classify_usearch_sintax_args"],
    message:
        "Classifying ASVs using usearch -sintax"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail

        usearch -sintax "{input.asvs}" \
            -db "{input.db}" \
            -tabbedout "{output}" \
            -threads {threads} \
            {params.classify_usearch_sintax_args}
        sort -o "{output}" "{output}"
        """


# MUUUCH faster to do this per sample and merge afterwards
# usearch -otutab does NOT scale linearly with more threads
rule usearch_abund:
    input:
        asvs=result("asvs.fasta"),
        reads=os.path.join(config["tmp_dir"], "01-trim", "{sample}.fastq.gz"),
    output:
        reads=temp(os.path.join(config["tmp_dir"], "05-usearch", "{sample}.fastq")),
        table=temp(os.path.join(config["tmp_dir"], "05-usearch", "{sample}.tsv")),
    log:
        os.path.join(config["log_dir"], "05-usearch", "usearch_abund_{sample}.log"),
    conda:
        "../envs/usearch.yml"
    container:
        usearch_container
    threads: min(config["threads"], 16)
    resources:
        mem_mb=scaled(1024, 4),
        runtime=scaled(30, 1),
    message:
        "{wildcards.sample}: Estimating abundances of ASVs using usearch -otutab"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail

        # usearch takes the sample name from the read labels
        zcat "{input.reads}" \
            | awk 'NR % 4 == 1 {{ print "@r" (NR + 3) / 4 ";sample={wildcards.sample};"; next }} {{ print }}' \
                >"{output.reads}"

        usearch -otutab "{output.reads}" \
            -zotus "{input.asvs}" \
            -otutabout "{output.table}" \
            -threads {threads}
        """


rule usearch_merge_abund:
    input:
        expand(
            os.path.join(config["tmp_dir"], "05-usearch", "{sample}.tsv"),
            sample=samples,
        ),
    output:
        result("abund_table_usearch.tsv"),
    log:
        os.path.join(config["log_dir"], "05-usearch", "usearch_merge_abund.log"),
    conda:
        "../envs/usearch.yml"
    container:
        usearch_container
    threads: 1
    resources:
        mem_mb=scaled(2048, 0),
        runtime=scaled(30, 0),
    message:
        "Merging usearch abundance tables"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail

        # usearch fails on empty tables, leave them out
        tables=$(for t in {input}; do if [ "$(wc -l <"$t")" -gt 1 ]; then echo "$t"; fi; done | paste -sd,)
        if [ -z "$tables" ]; then
            echo "Error: All abundance tables are empty"
            exit 1
        fi

        usearch -otutab_merge "$tables" -output "{output}.unsorted"
        (
            head -n 1 "{output}.unsorted"
            tail -n +2 "{output}.unsorted" | sort
        ) >"{output}"
        rm "{output}.unsorted"
        """
