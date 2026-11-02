# Configuration
The configuration file `config.yaml` is used to set various options used throughout the workflow.

| Option | Default value | Description |
| ---: | :---: | :--- |
| `input_dir` | `".test/nanopore_run_xyz123/fastq_pass"` | The input folder is expected to contain a subfolder for each sampleID/barcode, in which all fastq files (`.fastq`, `.fq`, optionally gzipped) will be concatenated, and the subfolder names used as sample IDs downstream. For nanopore this is usually the "fastq_pass" folder with demultiplexed reads. Subfolders named "unclassified" are ignored. |
| `output_dir` | `"output"` | Folder for the results. |
| `tmp_dir` | `"tmp"` | Folder for temporary files, which are deleted after a succesful run. |
| `log_dir` | `"logs"` | Folder for logs for each rule. |
| `threads` | `16` | Max number of threads to use for any individual rule. |
| `max_mem_mb` | `250000` | Max memory (MB) to request for any individual job. Memory is estimated from the input size and increased when a job is retried. |
| `pool_samples` | `False` | `True`: generate one set of ASVs from the reads of all samples pooled (`savont asv --pooled-samples`), which may recover more low-abundance ASVs, but needs much more memory. `False`: generate ASVs for each sample individually, which are merged by `savont export` afterwards. The results are the same tables for all samples either way. |
| `cutadapt_args` | `"-g AGAGTTTGATCMTGGCTCAG...CCAGCAGCCGCGGTAAT --revcomp --discard-untrimmed -e 0.15 -m 400 -M 600"` | Options passed on to `cutadapt` directly to trim primers and orient reads. Input, output, and threads are added automatically. The default is for the 27F/534R (V1-V3) primers. Set to `""` to skip trimming. |
| `min_reads` | `100` | Samples with fewer reads after trimming are left out of ASV generation (savont fails on samples with almost no reads). |
| `savont_asv_args` | `"--min-read-length 400 --max-read-length 600"` | Options passed on to the `savont asv` command directly, except input, output, and threads. Remember to set read lengths if not full-length 16S. |
| `classify_savont` | `True` | Whether to classify the ASVs using `savont classify` (alignment based, best at species level). |
| `savont_db` | `"databases/silva-138.2"` | Path to a savont database folder for `savont classify` and `savont sintax`. If it doesn't exist and is named one of the savont databases (`emu-1`, `silva-138.2`, `greengenes2-2024.09`, `unite-10.0`) it is downloaded. Use `scripts/qiime2savont.py` to convert QIIME formatted databases like MiDAS. |
| `classify_savont_args` | `""` | Options passed on to the `savont classify` command directly, except input, output, database, and threads. |
| `classify_sintax` | `True` | Whether to classify the ASVs using `usearch -sintax`. |
| `sintax_db` | `"databases/MiDAS5.3_20240320/FLASVs_w_sintax.fa"` | Path to the taxonomic reference database in SINTAX format (fasta or `.udb`) used by `usearch -sintax`. |
| `classify_sintax_args` | `"-strand both -sintax_cutoff 0.8"` | Options passed on to the `usearch -sintax` command directly, except input, output, database, and threads. |
| `classify_savont_sintax` | `False` | Whether to classify the ASVs using `savont sintax` with `savont_db`. Genus level only, it does not classify to species. |
| `classify_savont_sintax_args` | `""` | Options passed on to the `savont sintax` command directly, except input, output, database, and threads. |
| `abund_usearch` | `True` | Whether to also estimate ASV abundances by mapping the trimmed reads of each sample to the ASVs using `usearch -otutab`. The savont abundance table is always made, as `savont export` is needed to merge the ASVs anyway. |

Have a look in the `.test` directory for minimal example files.
