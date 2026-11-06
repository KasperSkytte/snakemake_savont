"""Write the reads of FASTQ files (gzipped or not) to stdout in one pass.

Files that are cut off, fx the last file of a run that was stopped or a single
file per sample that wasn't written completely, are used up to their last
complete read instead of failing the whole sample, as a partial read would
make cutadapt stop with an error. Empty, cut off and corrupt files are noted on
stderr (the log of the rule).
"""

import sys
import zlib

CHUNK = 1 << 20


def gzip_chunks(fh):
    """Yield the decompressed data of a (multi-member) gzip file. Raises
    EOFError if it is cut off or zlib.error if it is corrupt"""
    d = zlib.decompressobj(31)
    data = fh.read(CHUNK)
    while data:
        yield d.decompress(data)
        while d.eof and d.unused_data:
            rest = d.unused_data
            d = zlib.decompressobj(31)
            yield d.decompress(rest)
        data = fh.read(CHUNK)
    if not d.eof:
        raise EOFError("unexpected end of file")


def complete_read(rest):
    """True if rest is a complete read that only lacks the final newline"""
    lines = rest.split(b"\n")
    return len(lines) == 4 and len(lines[1]) == len(lines[3])


def cat_fastq(path, out):
    lines = 0
    rest = b""  # data after the last complete read (4 lines)
    error = None
    with open(path, "rb") as fh:
        gzipped = fh.read(2) == b"\x1f\x8b"
        fh.seek(0)
        source = gzip_chunks(fh) if gzipped else iter(lambda: fh.read(CHUNK), b"")
        try:
            for data in source:
                rest += data
                n = rest.count(b"\n")
                if n < 4:
                    continue
                cut = len(rest)
                for _ in range(n % 4 + 1):
                    cut = rest.rfind(b"\n", 0, cut)
                out.write(rest[: cut + 1])
                lines += n - n % 4
                rest = rest[cut + 1 :]
        except (EOFError, zlib.error) as e:
            error = e
    if rest and not error and complete_read(rest):
        out.write(rest + b"\n")
        lines += 4
        rest = b""
    if lines == 0 and not rest and not error:
        print(f"WARNING: {path} is empty, 0 reads", file=sys.stderr)
    elif error or rest:
        # a cut off file only loses its last, incomplete read, but the reads
        # after a corrupt part of a gzip file can't be read at all
        discarded = "1 incomplete read" if rest else "0 reads"
        if isinstance(error, zlib.error):
            discarded = ("1 incomplete read and " if rest else "") + (
                "the rest of the file after the corrupt part (number of reads unknown)"
            )
            what = f"is corrupt ({error})"
        else:
            what = "is cut off"
        print(
            f"WARNING: {path} {what}: used {lines // 4} complete reads, "
            f"discarded {discarded}",
            file=sys.stderr,
        )


def main():
    out = sys.stdout.buffer
    for path in sys.argv[1:]:
        cat_fastq(path, out)
    out.flush()


if __name__ == "__main__":
    main()
