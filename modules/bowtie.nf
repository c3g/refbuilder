params.bowtie_module = 'bowtie2/2.4.4'
params.publishMode = 'copy'

def mugqicPrefix = ~/^mugqic\//
def toolPrefix = params.bowtie_module - mugqicPrefix

process Index {
    publishDir path: { "${params.publish_basedir}/indices/${toolPrefix}" }, saveAs: { filename -> filename.equals('versions.yml') ? null : filename }, mode: params.publish_dir_mode
    module params.bowtie_module
    memory '8G'
    cpus 6

    input:
    path(genome)

    output:
    path("*")
    path("versions.yml"), emit: versions

    """
    bowtie2-build --threads ${task.cpus} --seed 1337 $genome $genome
    bowtie2 --version | awk '/version/ {print "    bowtie2:", \$3}' >> versions.yml
    """
}

workflow IndexBowtie {
    take: fasta

    main:
    fasta | Index
}
