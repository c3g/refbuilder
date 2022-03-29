params.bwa_module = 'bwa-mem2/2.0'
params.publishMode = 'copy'

def mugqicPrefix = ~/^mugqic\//
def toolPrefix = params.bwa_module - mugqicPrefix

process Index {
    publishDir path: { "${params.publish_basedir}/indices/${toolPrefix}" }, saveAs: { filename -> filename.equals('versions.yml') ? null : filename }, mode: params.publish_dir_mode
    module params.bwa_module
    memory '5G'

    input:
    path(genome)

    output:
    path("*")
    path("versions.yml"), emit: versions

    """
    bwa-mem2 index $genome

    """
}