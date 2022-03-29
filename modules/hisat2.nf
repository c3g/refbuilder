process ExtractSpliceSites {
    module 'histat2/2.2.1'

    input:
    path(gtf)

    "hisat2_extract_splice_sites.py "
}