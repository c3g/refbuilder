params.blastdb_version = 5

process UpdateBlastDBLatest {
    module 'gcc'
    module 'blast+'
    cpus 4

    input:
    val(dbname)

    output:
    val(dbname)

    """
    mkdir -p ${params.blast_lastest_dir}
    cd ${params.blast_lastest_dir}
    update_blastdb.pl \
    --blastdb_version ${params.blastdb_version} \
    --num_threads ${task.cpus} \
    --decompress \
    $dbname
    """
}

process UpdateDiamond {
    module 'gcc'
    module 'diamond/2.0.13'
    cpus 1

    input:
    val dbname

    """
    cd ${params.blast_lastest_dir}
    if test -f "${dbname}.pdb"; then
        diamond prepdb -d $dbname
    fi
    """
}

workflow UpdateAllBlastDBs {
    db_names = ["nr", "nt", "taxdb", "Betacoronavirus", "swissprot"]
    Channel.from(db_names)
    | UpdateBlastDBLatest
    | UpdateDiamond
}