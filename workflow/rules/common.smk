import os
import glob

# each subfolder in input_dir is a sample
samples = sorted(
    sample
    for sample in os.listdir(config["input_dir"])
    if os.path.isdir(os.path.join(config["input_dir"], sample))
    and "unclassified" not in sample.lower()
)

# savont asv is run once on all samples pooled, or once per sample
runs = ["pooled"] if config["pool_samples"] else samples

savont_container = "docker://quay.io/biocontainers/savont:0.8.0--hec9b1f2_2"
cutadapt_container = "docker://quay.io/biocontainers/cutadapt:5.2--py312hfabe715_2"
usearch_container = "docker://quay.io/biocontainers/usearch:11.0.667--h9ee0642_0"


def result(name):
    return os.path.join(config["output_dir"], name)


def scaled(base, per_input_mb, cap=None):
    """Resource (mem_mb or runtime) scaled by the input size and the attempt
    number, so jobs that fail (e.g. due to OOM) are retried with more"""

    def f(wildcards, input, attempt):
        value = (base + per_input_mb * input.size_mb) * attempt
        return int(min(value, cap) if cap else value)

    return f


def sample_fastqs(wildcards):
    files = []
    for ext in ("fastq", "fq", "fastq.gz", "fq.gz"):
        files += glob.glob(
            os.path.join(config["input_dir"], wildcards.sample, "**", f"*.{ext}"),
            recursive=True,
        )
    return sorted(files)


def run_samples(wildcards):
    return samples if wildcards.run == "pooled" else [wildcards.run]
