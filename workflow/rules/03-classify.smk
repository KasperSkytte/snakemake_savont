rule savont_db:
    output:
        touch(os.path.join(config["tmp_dir"], "03-classify", "db.done")),
    log:
        os.path.join(config["log_dir"], "03-classify", "savont_db.log"),
    conda:
        "../envs/savont.yml"
    container:
        savont_container
    threads: config["threads"]
    resources:
        mem_mb=scaled(8192, 0),
        runtime=scaled(60, 0),
    params:
        db=config["savont_db"],
        build_index="yes" if config["classify_savont"] else "no",
    message:
        "Preparing database for savont"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail
        db="{params.db}"

        # savont databases (emu-1, silva-138.2, ...) are downloaded if missing
        if [ ! -d "$db" ]; then
            savont download --location "$(dirname "$db")" --dbs "$(basename "$db")"
        fi

        # savont classify builds a minimap2 index of the database on first use.
        # Do it once here by classifying a dummy ASV, instead of in every
        # classify job at the same time
        if [ "{params.build_index}" = "yes" ] && ! ls "$db"/*.mmi; then
            dummy="$(dirname "{output}")/dummy"
            mkdir -p "$dummy"
            printf ">final_asv_0_depth_1\\n%s\\n" "$(printf 'ACGT%.0s' $(seq 50))" >"$dummy/final_asvs.fasta"
            savont classify --input-dir "$dummy" --db "$db" --threads {threads}
            rm -rf "$dummy"
        fi
        """


# per run, before merging, as savont export merges the taxonomy as well
rule savont_classify:
    input:
        asvs=os.path.join(config["tmp_dir"], "02-asv", "{run}", "final_asvs.fasta"),
        db=os.path.join(config["tmp_dir"], "03-classify", "db.done"),
    output:
        mappings=temp(
            os.path.join(config["tmp_dir"], "02-asv", "{run}", "asv_mappings.tsv")
        ),
        genus=temp(
            os.path.join(config["tmp_dir"], "02-asv", "{run}", "genus_abundance.tsv")
        ),
    log:
        os.path.join(config["log_dir"], "03-classify", "{run}.log"),
    conda:
        "../envs/savont.yml"
    container:
        savont_container
    threads: config["threads"]
    resources:
        # mostly the database index, ~2GB for SILVA
        mem_mb=scaled(4096, 0),
        runtime=scaled(60, 0),
    params:
        db=config["savont_db"],
        classify_savont_args=config["classify_savont_args"],
    message:
        "{wildcards.run}: Classifying ASVs using savont classify"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail

        if [ -s "{input.asvs}" ]; then
            savont classify \
                --input-dir "$(dirname "{input.asvs}")" \
                --db "{params.db}" \
                --threads {threads} \
                {params.classify_savont_args}
            # not used, already in the rule log
            rm -f "$(dirname "{input.asvs}")"/{{species_abundance.tsv,savont_*.log}}
        fi
        # empty outputs if there are no ASVs
        touch {output}
        """


# on the merged ASVs, like usearch -sintax
rule savont_sintax:
    input:
        asvs=result("asvs.fasta"),
        db=os.path.join(config["tmp_dir"], "03-classify", "db.done"),
    output:
        result("taxonomy_savont_sintax.tsv"),
    log:
        os.path.join(config["log_dir"], "03-classify", "savont_sintax.log"),
    conda:
        "../envs/savont.yml"
    container:
        savont_container
    threads: config["threads"]
    resources:
        mem_mb=scaled(2048, 0),
        runtime=scaled(60, 0.5),
    params:
        db=config["savont_db"],
        classify_savont_sintax_args=config["classify_savont_sintax_args"],
        tmp_dir=os.path.join(config["tmp_dir"], "03-classify", "savont_sintax"),
    message:
        "Classifying ASVs using savont sintax"
    shell:
        """
        exec &>"{log}"
        set -euxo pipefail

        mkdir -p "{params.tmp_dir}"
        cp "{input.asvs}" "{params.tmp_dir}/final_asvs.fasta"
        savont sintax \
            --input-dir "{params.tmp_dir}" \
            --db "{params.db}" \
            --threads {threads} \
            {params.classify_savont_sintax_args}
        # depth is meaningless for the merged ASVs
        cut -f1,3- "{params.tmp_dir}/asv_mappings.tsv" >"{output}"
        rm -rf "{params.tmp_dir}"
        """
