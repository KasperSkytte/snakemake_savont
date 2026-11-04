# Snakemake workflow: `snakemake_savont`

[![Snakemake](https://img.shields.io/badge/snakemake-≥9.0.0-brightgreen.svg)](https://snakemake.github.io)
[![Tests](https://github.com/KasperSkytte/snakemake_savont/actions/workflows/main.yml/badge.svg)](https://github.com/KasperSkytte/snakemake_savont/actions/workflows/main.yml)

Simple snakemake workflow for processing amplicon data sequenced on ONT or PacBio platforms, using [cutadapt](https://cutadapt.readthedocs.io) to trim primers, [savont](https://github.com/bluenote-1577/savont) to generate ASVs, and savont and/or [usearch](https://drive5.com/usearch) for taxonomic classification and abundance tables. ASVs can be generated from all samples pooled or from each sample individually (see `pool_samples` in the [configuration file](config/README.md)).

## Brief overview and description of steps (rules)
| File | Rule | Description |
| --- | --- | --- |
| `01-trim.smk` | `trim` | For each sample, concatenate all fastq files, trim primers and orient reads using `cutadapt`, and count reads before and after. |
| | `read_counts` | Gather read counts of all samples into `read_counts.tsv`. |
| `02-asv.smk` | `savont_asv` | Generate ASVs using `savont asv`, either once for all samples pooled (`--pooled-samples`) or once per sample. Samples with fewer than `min_reads` reads are left out. |
| `03-classify.smk` | `savont_db` | Download the savont database if needed, and build the database index once. Only if `savont classify` or `savont sintax` is used. |
| | `savont_classify` | (optional, off by default) Classify ASVs using `savont classify`. |
| | `savont_sintax` | (optional, off by default) Classify the merged ASVs using `savont sintax`. Genus level only, it does not classify to species. |
| `04-export.smk` | `savont_export` | Merge ASVs and abundances of all samples into QIIME2-compatible tables using `savont export`. |
| `05-usearch.smk` | `usearch_sintax` | (optional) Classify the merged ASVs using `usearch -sintax`. |
| | `usearch_abund` | (optional) For each sample, estimate ASV abundances by mapping the trimmed reads to the merged ASVs using `usearch -otutab`. Much faster per sample in parallel than for all samples at once. |
| | `usearch_merge_abund` | (optional) Merge the per-sample abundance tables using `usearch -otutab_merge`. |

Additional options can be passed on directly to the individual commands through the [configuration file](config/README.md).

## Output
All results are tables for all samples in `output_dir`, the same files whether the ASVs were made from all samples pooled or not (`pool_samples`):
 - `asvs.fasta`: ASV sequences
 - `abund_table_savont.tsv`: read counts per ASV per sample estimated by savont
 - `abund_table_usearch.tsv`: (optional) read counts per ASV per sample estimated by `usearch -otutab`
 - `taxonomy_savont.tsv`: (optional) taxonomy per ASV from `savont classify`
 - `taxon_counts_savont.tsv`: (optional) read counts per taxon (lineage) per sample from `savont classify`
 - `taxonomy_usearch_sintax.tsv`: (optional) taxonomy per ASV from `usearch -sintax`
 - `taxonomy_savont_sintax.tsv`: (optional) taxonomy per ASV from `savont sintax`
 - `read_counts.tsv`: number of reads per sample before and after trimming

The ASV IDs are the same in all tables.

## Usage
First install snakemake into a conda environment using the [environment.yml](environment.yml) file. Then deploy the workflow using [snakedeploy](https://snakemake.github.io/snakemake-workflow-catalog/docs/workflows/KasperSkytte/snakemake_savont.html), adjust the [config file](config/README.md), then run, fx:
```
release="v2.0.0"
mamba env create --file https://raw.githubusercontent.com/KasperSkytte/snakemake_savont/refs/tags/${release}/environment.yml
mamba activate snakemake_savont
snakedeploy deploy-workflow https://github.com/KasperSkytte/snakemake_savont . --tag ${release}
# now adjust the config file, then run the workflow with fx:
snakemake --sdm apptainer --cores 32
```

The software used by the rules (savont, cutadapt, usearch) is provided either through containers (`--sdm apptainer`, using biocontainers images) or conda environments (`--sdm conda`, see `workflow/envs/`). With apptainer, make sure the folders with input data and databases are available inside the containers, fx with `--apptainer-args "--bind /path/to/data"` if they are not under the current working directory (snakemake does not mount your home folder in the containers).

### Cluster
On a HPC cluster submit each rule as a separate job using the SLURM profile in `profiles/slurm` (copied by snakedeploy, adjust it to your cluster), see `slurm_submit.sbatch`. Run snakemake from the folder containing `profiles/`. Memory and runtime are estimated from the input size of each job, and failed jobs (fx due to running out of memory) are retried with more resources (`retries` in the profile), up to `max_mem_mb`. Measured memory usage of `savont asv` is written to `logs/02-asv/*.benchmark.tsv`, use it to adjust if needed, fx with `--set-resources savont_asv:mem_mb=128000`.

Running each sample individually (`pool_samples: False`) uses far less memory per job and runs samples in parallel. Pooling all samples is a single large job (more than 55GB for 92 samples with ~150MB gzipped reads each).

## Custom databases (fx MiDAS)
savont can only use its own databases, but any database in QIIME format (a fasta file and a taxonomy file with lines like `ID<TAB>k__Bacteria; p__...; s__...`) can be converted to the savont (EMU) format using the standalone script `scripts/qiime2savont.py`, fx for MiDAS:
```
python3 scripts/qiime2savont.py MiDAS5.3_20240320/FLASVs.fa MiDAS5.3_20240320/tax_complete_qiime.txt databases/midas-5.3
```
then set `savont_db: "databases/midas-5.3"` in the config file. For `usearch -sintax` use the SINTAX formatted MiDAS fasta (`FLASVs_w_sintax.fa`) directly.
