params.genome_source = "Ensembl"
params.species = "Homo_sapiens"
params.assembly = "GRCh38"
params.ensembl_release = "104"

params.genome_url = "ftp://ftp.ensembl.org/pub/release-${params.ensembl_release}/fasta/${params.species.toLowerCase()}/dna/${params.species}.${params.assembly}.dna_rm.primary_assembly.fa.gz"

workflow ImportGenome {
    Channel.fromPath(params.genome_url) | collectFile(storeDir: "/bnt/datashare/staging/by-organism/${params.species}/${params.genome_source}/release-${params.ensembl_release}/${params.assembly}")
}