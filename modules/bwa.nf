params.bwa_module = 'bwa/0.7.17'

def mugqicPrefix = ~/^mugqic\//
def toolPrefix = params.bwa_module - mugqicPrefix

process Index {
    publishDir path: { "${params.publish_basedir}/indices/${toolPrefix}" }, saveAs: { filename -> filename.equals('versions.yml') ? null : filename }, mode: params.publish_dir_mode
    module params.bwa_module
    memory '8G'
    time '6h'

    input:
    path(genome)

    output:
    path("*")

    """
    bwa index $genome
    bwa | awk '/Version:/ {print "    bwa:", \$2}' >> versions.yml
    """
}

workflow IndexBWA {
    take: fasta

    main:
    fasta | Index
}