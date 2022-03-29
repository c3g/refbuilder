import groovy.text.SimpleTemplateEngine

params.species = "Homo_sapiens"
params.assembly = null
params.analysis_set = "base"
params.publish_basedir = "${params.basedir}/genomes/${params.species}/NCBI/${params.assembly}/${params.analysis_set}"
params.latest = false
params.fasta = null
params.gff = null
params.gtf = null
params.assembly_report = null

include { findRefSeqGff; findRefSeqGtf; findAssemblyReport } from './functions'
include { findRefseqFasta          } from './functions'
include { IndexBWA                 } from "../bwa"
include { IndexBismark             } from "../bismark"
include { IndexBowtie              } from "../bowtie"
include { CreateSequenceDictionary } from '../gatk'

process GunzipIndexFasta {
    publishDir path: { params.publish_basedir }, saveAs: { filename -> filename.equals('versions.yml') ? null : filename }, mode: params.publish_dir_mode
    executor 'local'
    module 'samtools'
    memory '8G'
    time '1h'

    input:
    path(fasta)

    output:
    path("genome.fasta"),     emit: fasta
    path("genome.fasta.fai"), emit: fai
    path("versions.yml"),     emit: versions

    script:
    def preamble = getPreamble(fasta)
    """
    $preamble $fasta > genome.fasta
    samtools faidx genome.fasta
    samtools --version | awk '/samtools/ {print "    samtools:", \$2}' >> versions.yml
    """
}

process IndexAnnotation {
    publishDir path: { "${params.publish_basedir}/annotations/latest" }, saveAs: { filename -> filename.equals('versions.yml') ? null : filename }, mode: params.publish_dir_mode
    executor 'local'
    module 'tabix/0.2.6'
    memory '8G'
    time '10m'

    input:
    tuple path(annot), val(extension)

    output:
    path("*.gz"),         emit: annotation
    path("*.tbi"),        emit: index
    path("versions.yml"), emit: versions

    script:
    def preamble = getPreamble(annot)
    """
    $preamble $annot | bgzip -c > annotation.${extension}.gz
    tabix annotation.*.gz \\
    || (
        gunzip --stdout $annot | grep ^"#"
        gunzip --stdout $annot | grep -v ^"#" | sort  -t \$'\\t' -k1,1V -k4,4n -k5,5n
    ) | bgzip > annotation.${extension}.gz \\
    && tabix -p gff annotation.*.gz
    tabix | awk '/Version:/ {print "    tabix:", \$2}' >> versions.yml
    """
}

process MakeGenomeModulefile {
    publishDir path: { "${params.basedir}/modules/genomes/${params.species}/NCBI/${params.assembly}" }, mode: params.publish_dir_mode
    executor 'local'
    cache false

    input:
    val(fasta_path)

    output:
    file("${params.analysis_set}.lua")

    exec:
    def binding = [
        fasta_path : fasta_path,
        params     : params,
        workflow   : workflow
    ]

    def engine = new groovy.text.SimpleTemplateEngine()
    def raw = file("${baseDir}/assets/module.ncbi.template")
    def template = engine.createTemplate(raw.text).make(binding)
    def modulefile = new File("${task.workDir}/${params.analysis_set}.lua")
    log.info "Creating file '${task.workDir}/${params.analysis_set}.lua'"
    modulefile.text = template.toString()
}

workflow ImportGenome {
    gff_path        = params.gff             ?: findRefSeqGff(params.species, params.assembly)
    gtf_path        = params.gff             ?: findRefSeqGtf(params.species, params.assembly)
    fasta_path      = params.fasta           ?: findRefseqFasta(params.species, params.assembly)
    assembly_report = params.assembly_report ?: findAssemblyReport(params.species, params.assembly)

    if (!fasta_path) {
        log.warn "Could not find refseq path for NCBI genome ${params.species} ${params.assembly} (${params.analysis_set})"
        return
    }

    if (!gff_path) {
        log.warn "Could not find refseq gff annotations for NCBI genome ${params.species} ${params.assembly} (${params.analysis_set})"
        return
    }

    if (!gtf_path) {
        log.warn "Could not find refseq gtf annotations for NCBI genome ${params.species} ${params.assembly} (${params.analysis_set})"
        return
    }

    if (!assembly_report) {
        log.warn "Could not find assembly report for NCBI genome ${params.species} ${params.assembly} (${params.analysis_set})"
    }

    // Channel.from([[gff_path, "gff"], [gtf_path, "gtf"]]) | IndexAnnotation
    MakeGenomeModulefile(fasta_path)

    Channel.from(fasta_path) | GunzipIndexFasta
    GunzipIndexFasta.out.fasta | IndexBWA
    GunzipIndexFasta.out.fasta | IndexBowtie
    GunzipIndexFasta.out.fasta | CreateSequenceDictionary
    // // GunzipIndexFasta.out.fasta | IndexBismark

    // GunzipIndexFasta.out.versions
}

String getPreamble(input) {
    def preamble
    switch (input.toString()) {
        case ~/.*\.gz$/:
            preamble = "gunzip --stdout"
            break
        case ~/.*\.bz2$/:
            preamble = "bzip2 --decompress --stdout --fast"
            break
        default:
            preamble = "cat"
            break
    }
    return preamble
}