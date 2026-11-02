#!/usr/bin/env python3
"""Convert a QIIME formatted reference database to a savont database.

QIIME format is a fasta file and a tab separated taxonomy file with lines like:
  FLASV1.1417<TAB>k__Bacteria; p__Chloroflexi; c__Anaerolineae; ...; s__Ca_Amarolinea_dominans

savont has no generic custom database format, but reads any taxonomy in the
EMU database layout (species_taxid.fasta + taxonomy.tsv), so that is written.

Usage:
  qiime2savont.py <seqs.fa[.gz]> <taxonomy.txt[.gz]> <output_dir>

Example (MiDAS):
  qiime2savont.py MiDAS5.3_20240320/FLASVs.fa MiDAS5.3_20240320/tax_complete_qiime.txt midas-5.3
  savont classify -i savont-out -d midas-5.3
"""
import gzip
import os
import sys

# taxonomy.tsv columns, savont uses species to superkingdom
COLUMNS = ["tax_id", "species", "genus", "family", "order", "class", "phylum",
           "clade", "superkingdom", "subspecies", "species_subgroup", "species_group"]
# QIIME rank prefixes, both k__/d__ style and the older D_0__ (SILVA) style
PREFIXES = {"k": "superkingdom", "d": "superkingdom", "p": "phylum", "c": "class",
            "o": "order", "f": "family", "g": "genus", "s": "species"}
LEVELS = ["superkingdom", "phylum", "class", "order", "family", "genus", "species"]


def open_text(path):
    return gzip.open(path, "rt") if path.endswith(".gz") else open(path)


def parse_lineage(lineage):
    ranks = {}
    for i, taxon in enumerate(t.strip() for t in lineage.split(";")):
        prefix, sep, name = taxon.partition("__")
        if not sep:
            # no prefixes, ranks by position
            rank, name = (LEVELS[i] if i < len(LEVELS) else None), taxon
        elif prefix.startswith("D_"):
            rank = LEVELS[int(prefix[2:])] if int(prefix[2:]) < len(LEVELS) else None
        else:
            rank = PREFIXES.get(prefix.lower())
        if rank and name:
            ranks[rank] = name
    return ranks


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    fasta, taxonomy, out_dir = sys.argv[1:]
    os.makedirs(out_dir, exist_ok=True)

    # savont takes the ID until the first ":" of the fasta headers
    taxa = set()
    with open_text(taxonomy) as f, open(os.path.join(out_dir, "taxonomy.tsv"), "w") as out:
        out.write("\t".join(COLUMNS) + "\n")
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            seq_id, lineage = line.rstrip("\n").split("\t")[:2]
            seq_id = seq_id.strip().replace(":", "_")
            ranks = parse_lineage(lineage)
            taxa.add(seq_id)
            out.write("\t".join([seq_id] + [ranks.get(c, "") for c in COLUMNS[1:]]) + "\n")

    n_seqs = 0
    missing = 0
    with open_text(fasta) as f, open(os.path.join(out_dir, "species_taxid.fasta"), "w") as out:
        keep = False
        for line in f:
            if line.startswith(">"):
                seq_id = line[1:].split()[0].replace(":", "_")
                keep = seq_id in taxa
                if keep:
                    n_seqs += 1
                    out.write(f">{seq_id}\n")
                else:
                    missing += 1
            elif keep:
                out.write(line)

    # marker file used by savont to detect the database type
    with open(os.path.join(out_dir, ".savont_db"), "w") as out:
        out.write("emu-1")

    print(f"Wrote {n_seqs} sequences with taxonomy to {out_dir}")
    if missing:
        print(f"Left out {missing} sequences without taxonomy", file=sys.stderr)


if __name__ == "__main__":
    main()
