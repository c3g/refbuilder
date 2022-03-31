#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { UpdateAllBlastDBs } from "./modules/blast"
include { Kraken as GetKraken } from "./modules/kraken"

include { ImportGenome as ImportNCBI }                         from "./modules/ncbi/main"
include { ImportGenome as Homo_sapiens_NCBI_GRCh37 }           from "./modules/ncbi/main" addParams( assembly: "GRCh37.p13")
include { ImportGenome as Homo_sapiens_NCBI_GRCh38 }           from "./modules/ncbi/main" addParams( assembly: "GRCh38.p13")
include { ImportGenome as Homo_sapiens_NCBI_GRCh38_alignment } from "./modules/ncbi/main" addParams( assembly: "GRCh38.p13",  analysis_set: "no_alt_plus_hs38d1_analysis_set", lastest: true)
include { ImportGenome as Mouse_GRCm39 }                       from "./modules/ncbi/main" addParams( assembly: "GRCm39", species: "Mus_musculus" )

// The default (unnamed) workflow runs all the sub-workflows
workflow {
    Blast()
    Kraken()
    Ncbi()
}

// For creating a single genome at a time, providing parameters on the command line
// or via a nextflow.config file.

workflow NCBI { ImportNCBI() }

// Sub-workflows are defined here and can be run along using the `-entry`
//  argument. For example `nextflow run main -entry Kraken` runs only
//  the Kraken sub-workflow.

workflow Kraken { GetKraken() }

workflow Blast  { UpdateAllBlastDBs() }

workflow Ncbi  {
    Mouse_GRCm39()
    Homo_sapiens_NCBI_GRCh37()
    Homo_sapiens_NCBI_GRCh38()
    Homo_sapiens_NCBI_GRCh38_alignment()
    // Homo_sapiens_NCBI_GRCh37_alignment()
}