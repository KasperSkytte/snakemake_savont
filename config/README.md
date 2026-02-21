# Configuration
The configuration file `config.yaml` is used to set various options used throughout the workflow.

| Option | Default value | Description |
| ---: | :---: | :---: |
| `input_dir` | `".test/nanopore_run_xyz123/fastq_pass"` | The input folder is expected to contain a subfolder for each sampleID/barcode, in which all fastq files will be concatenated, and the subfolder names used as sample IDs downstream. For nanopore this is usually the "fastq_pass" folder with demultiplexed reads. |
| `output_dir` | `"output"` | Folder for the results. |
| `tmp_dir` | `"tmp"` | Folder for temporary files, which are deleted by default after a succesful run. |
| `log_dir` | `"logs"` | Folder for logs for each rule. |
| `savont_asv_args` | `"--minimum-base-quality 25 --quality-value-cutoff 98 --min-read-length 400 --max-read-length 700"` | Options passed on to the `savont asv` command directly, except input, output, and threads. |
| `classify_sintax` | `True` | Whether to classify the ASVs using `usearch -sintax`. |
| `db_sintax` | `".test/db_sintax.fa"` | Path to the taxonomic reference database used to classify the ASVs in SINTAX format. |
| `classify_sintax_args` | `"-strand both -sintax_cutoff 0.8"` | Options passed on to the `usearch -sintax` command directly, except input, output, database, and threads. |
| `classify_savont` | `True` | Whether to classify the ASVs using `savont classify`. |
| `classify_savont_db` | `"silva"` | Which database to use for `savont classify`. Valid options are `"silva"` or `"emu"`. Required database files will be automatically downloaded if not present in `classify_savont_db_download_dir`. |
| `classify_savont_db_download_dir` | `./databases` | Folder for database files used for `savont classify`. |
| `classify_savont_args` | `""` | Options passed on to the `savont classify` command directly, except input, output, database, and threads. |
| `max_threads` | `32` | Max number of threads to use for any individual rule. Ensure this is a factor of the `--cores` value specified when running the workflow to avoid waste. |
| `sample_sep` | `"_"` | Separator used for the `usearch -otutab` and `fastx_relabel` commands. |
| `cutadapt_args` | `"-g AGRGTTYGATYMTGGCTCAG...GTTTGGCACCTCGATGTCG --revcomp --discard-untrimmed"` | Options passed on to `cutadapt` directly. Input, output, and threads are added automatically. This is required for trimming and orienting reads correctly according to primers. To skip the `cutadapt` step simply set this to `""`. |
| `rarefy_abund_table` | `False` | Whether to also produce a rarefied abundance table or not. |
| `rarefy_sample_size` | `2000` | Rarefy abundance table to an equal sample size. Both a rarefied and an unrarefied abundance table will be generated. |

Have a look in the `.test` directory for minimal example files.
