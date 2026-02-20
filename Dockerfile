FROM condaforge/miniforge3:latest
LABEL io.github.snakemake.containerized="true"
LABEL io.github.snakemake.conda_env_hash="36f94c1a8520ef7da59b85eef6670ada0183fce45ab0e02dabebf541eb2b55df"

# Step 2: Retrieve conda environments

# Conda environment:
#   source: workflow/envs/snakemake_savont.yml
#   prefix: /conda-envs/8013a7cf1ccc34e6bd1189842818c6fc
#   name: snakemake_savont
#   channels:
#     - bioconda
#     - conda-forge
#   dependencies:
#     - gzip=1.13
#     - cutadapt=5.1
#     - usearch=11.0.667
#     - savont=0.3.2
RUN mkdir -p /conda-envs/8013a7cf1ccc34e6bd1189842818c6fc
COPY workflow/envs/snakemake_savont.yml /conda-envs/8013a7cf1ccc34e6bd1189842818c6fc/environment.yaml

# Step 3: Generate conda environments

RUN conda env create --prefix /conda-envs/8013a7cf1ccc34e6bd1189842818c6fc --file /conda-envs/8013a7cf1ccc34e6bd1189842818c6fc/environment.yaml && \
    conda clean --all -y
