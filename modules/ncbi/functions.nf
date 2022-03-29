@Grab(group='commons-net', module='commons-net', version='2.0')
import java.nio.file.Paths
import org.apache.commons.net.ftp.FTPClient

//  Utility functions

String findRefseqFasta(String species, String assembly) {
    def basedir = findRefseqBaseDir(species, assembly)
    if (!basedir) { return null }
    new FTPClient().with {
        connect "ftp.ncbi.nih.gov"
        enterLocalPassiveMode()
        login "anonymous", ""
        changeWorkingDirectory basedir
        // If the params define a custom analysis set (only relevant
        // in humans), then move into that directory and look for a
        // fna file
        if (params.analysis_set != "base") {
            def potential_dirs = listFiles()
            .findAll { it.isDirectory() | it.isSymbolicLink() }
            .find { it.getName() ==~ /.*_seqs_for_alignment_pipelines/ }
            if (!potential_dirs) return null
            changeWorkingDirectory potential_dirs.getName()
            def fna = listFiles().find { it.getName() ==~ /.*(${params.analysis_set}).fna.gz$/ }
            return fna ? "ftp://ftp.ncbi.nih.gov${printWorkingDirectory()}/${fna.getName()}" : null
        } else {
            def fna = listFiles().find { it.getName() ==~ /.*[^(_cds_from)]_genomic.fna.gz$/ }
            return fna ? "ftp://ftp.ncbi.nih.gov${basedir}/${fna.getName()}" : null
        }
    }
}

String findNcbiAnnotation(String species, String assembly, String suffix) {
    def basedir = findRefseqBaseDir(species, assembly)
    if (!basedir) { return null }
    new FTPClient().with {
        connect "ftp.ncbi.nih.gov"
        enterLocalPassiveMode()
        login "anonymous", ""
        changeWorkingDirectory basedir
        if (params.analysis_set != "base") {
            def potential_dirs = listFiles()
            .findAll { it.isDirectory() | it.isSymbolicLink() }
            .find { it.getName() ==~ /.*_seqs_for_alignment_pipelines/ }
            if (!potential_dirs) return null
            changeWorkingDirectory potential_dirs.getName()
            def path = listFiles().find { it.getName() ==~ /.*refseq_annotation.${suffix}.gz/ }
            if (path) {
                return "ftp://ftp.ncbi.nih.gov${printWorkingDirectory()}/${path.getName()}"
            } else {
                changeWorkingDirectory basedir
            }
        }
        path = listFiles().find { it.getName() ==~ /.*_genomic.${suffix}.gz/ }
        return path ? "ftp://ftp.ncbi.nih.gov${printWorkingDirectory()}/${path.getName()}" : null
    }
}

String findRefSeqGff(String species, String assembly) {
    findNcbiAnnotation(species, assembly, "gff")
}

String findRefSeqGtf(String species, String assembly) {
    findNcbiAnnotation(species, assembly, "gtf")
}

String findAssemblyReport(String species, String assembly) {
    def basedir = findRefseqBaseDir(species, assembly)
    if (!basedir) { return null }
    def path
    new FTPClient().with {
        connect "ftp.ncbi.nih.gov"
        enterLocalPassiveMode()
        login "anonymous", ""
        changeWorkingDirectory basedir
        path = listFiles().find { it.getName() ==~ /.*_assembly_report.txt/ }
    }
    return path ? "ftp://ftp.ncbi.nih.gov${basedir}/${path.getName()}" : null
}

String findRefseqBaseDir(String species, String assembly = null) {
    new FTPClient().with {
        connect "ftp.ncbi.nih.gov"
        enterLocalPassiveMode()
        login "anonymous", ""
        changeWorkingDirectory "genomes/refseq"

        // To save time searching through the ftp directories, we can
        // shortcut by moving directly into the "vertebrate_mammalian"
        // directory.
        if (species == "Homo_sapiens" | species == "Mus_musculus") {
            changeWorkingDirectory "vertebrate_mammalian"
        } else {
            // The species directories are organised by kingdom, so we
            // look in each folder for the given species
            def kingdom_directory = listFiles()
                .findAll { it.isDirectory() }
                .find { dir ->
                    listFiles(dir.getName())
                        .findAll { it.isDirectory() }
                        .collect { it.getName() }
                        .any { it == params.species }
                }
                if (!kingdom_directory) return null
            changeWorkingDirectory kingdom_directory.getName()
        }
        changeWorkingDirectory params.species

        // If we are given an assembly version and assembly patch, we should
        // be able to find the assembly folder uniquely. If no assembly version
        // is found, use the "latest" as defined by NCBI.
        def assembly_dir = null
        if (assembly) {
            changeWorkingDirectory "all_assembly_versions"
            assembly_dir = listFiles()
            .findAll { it.isDirectory() | it.isSymbolicLink() }
            .find { it.getName() ==~ /.*${assembly}$/ }
        } else {
            changeWorkingDirectory "latest_assembly_versions"
            assembly_dir = listFiles()
            .findAll()
            .sort { it.getTimestamp() }
            .last()
        }

        return assembly_dir ? "${printWorkingDirectory()}/${assembly_dir.getName()}" : null
    }
}