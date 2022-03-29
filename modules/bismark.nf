params.bowtie_module = 'bowtie2/2.4.4'
params.bismark_module = 'mugqic/bismark/0.21.0'
params.publishMode = 'copy'

def mugqicPrefix = ~/^mugqic\//
def toolPrefix = params.bismark_module - mugqicPrefix

process Index {
    publishDir path: { "${params.publish_basedir}/indices/${toolPrefix}" }, saveAs: { filename -> filename.equals('versions.yml') ? null : filename }, mode: params.publish_dir_mode
    module params.bismark_module
    module params.bowtie_module
    memory '12G'
    time '2d'

    input:
    path("genome/*")

    output:
    path("*")
    path("versions.yml"), emit: versions

    """
    bismark_genome_preparation genome
    bismark --version | awk '/Version:/ {print "    bismark:", \$3}' >> versions.yml'
    bowtie2 --version | awk '/version/ {print "    bowtie:", \$3}' >> versions.yml'
    """
}

workflow IndexBismark {
    take: fasta

    main:
    fasta | Index
}