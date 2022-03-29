
params.uri = false

process CreateSequenceDictionary {
    publishDir path: { "${params.publish_basedir}" }, saveAs: { filename -> filename.equals('versions.yml') ? null : filename }, mode: params.publish_dir_mode
    module 'gatk/4.2.2.0'
    memory '8G'
    time '10m'

    input:
    path(fasta)

    output:
    path("*.dict")
    path("versions.yml"), emit: versions

    script:
    def uri = params.uri ? "--URI ${params.uri}" : ""
    """
    gatk CreateSequenceDictionary --REFERENCE $fasta --SPECIES $params.species ${uri}
    gatk --version | awk '/HTSJDK Version:/ {print "    htsjdk:", \$2}' >> versions.yml''
    gatk --version | awk '/Picard Version:/ {print "    picard:", \$2}' >> versions.yml''
    """
}