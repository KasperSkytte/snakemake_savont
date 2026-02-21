rule sintax_classify:
    input:
        os.path.join(config["output_dir"], "final_asvs_clean.fasta"),
    output:
        os.path.join(config["output_dir"], "final_asvs_clean.sintax"),
    log:
        os.path.join(config["log_dir"], "03-classify", "sintax_classify.log"),
    message:
        "Predicting taxonomy of ASVs using SINTAX"
    resources:
        mem_mb=4096,
        runtime=60,
        cpus_per_task=config["max_threads"],
    container:
        "docker://ghcr.io/kasperskytte/snakemake_savont:main"
    conda:
        "../envs/snakemake_savont.yml"
    threads: config["max_threads"]
    params:
        db=config["db_sintax"],
        classify_sintax_args=config["classify_sintax_args"],
    shell:
        """
        exec &> "{log}"
        set -euxo pipefail

        usearch -sintax \
          "{input}" \
          -db "{params.db}" \
          -tabbedout "{output}" \
          -threads "{threads}" \
          {params.classify_sintax_args}
        sort -V "{output}" -o "{output}"
      """


rule savont_classify:
    input:
        os.path.join(config["output_dir"], "savont_output", "final_asvs.fasta"),
    output:
        species=os.path.join(
            config["output_dir"], "savont_output", "species_abundance.tsv"
        ),
        genus=os.path.join(config["output_dir"], "savont_output", "genus_abundance.tsv"),
        savont_latest_log=temp("savont_classify_latest.log"),
    log:
        os.path.join(config["log_dir"], "03-classify", "savont_classify.log"),
    message:
        "Predicting taxonomy of ASVs using savont"
    resources:
        mem_mb=8192,
        runtime=60,
        cpus_per_task=config["max_threads"],
    container:
        "docker://ghcr.io/kasperskytte/snakemake_savont:main"
    conda:
        "../envs/snakemake_savont.yml"
    threads: config["max_threads"]
    params:
        classify_savont_db=config["classify_savont_db"],
        classify_savont_db_download_dir=config["classify_savont_db_download_dir"],
        classify_savont_args=config["classify_savont_args"],
    shell:
        """
        exec &> "{log}"
        set -euxo pipefail

        if [ "{params.classify_savont_db}" == "silva" ]; then
            db_dir="{params.classify_savont_db_download_dir}/{params.classify_savont_db}_db"
        elif [ "{params.classify_savont_db}" == "emu" ]; then
            db_dir="{params.classify_savont_db_download_dir}/{params.classify_savont_db}_default"
        else
            echo "Error: valid options for classify_savont_db in the config file are: \"emu\" or \"silva\""
            exit 1
        fi
        if [ ! -d "$db_dir" ]; then
            echo "{params.classify_savont_db} database does not exist in {params.classify_savont_db_download_dir}, downloading..."
            savont download --location {params.classify_savont_db_download_dir} --{params.classify_savont_db}-db
        fi

        savont classify \
          --input-dir "$(dirname {input})" \
          --output-dir "$(dirname {input})" \
          --{params.classify_savont_db}-db "$db_dir" \
          --threads {threads} \
          {params.classify_savont_args}
        
        #echo "test: {output.species}, {output.genus}"
      """
