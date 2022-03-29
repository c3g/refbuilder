process DownloadKrakenV1 {
    tag {url.getBaseName()}
    publishDir "/bnt/datashare/staging/databases/krakenv1", mode: 'copy'

    input:
    path(url)

    output:
    path("*")

    "tar -xvf $url"
}

process DownloadKrakenV2 {
    tag {url.getBaseName()}
    publishDir "/bnt/datashare/staging/databases/krakenv2", mode: 'copy'

    input:
    path(url)

    output:
    path("*")

    "tar -xvf $url"
}

workflow KrakenV1 {
    Channel.from([
        "https://ccb.jhu.edu/software/kraken/dl/minikraken_20171019_4GB.tgz",
        "https://ccb.jhu.edu/software/kraken/dl/minikraken_20171101_4GB_dustmasked.tgz",
        "https://ccb.jhu.edu/software/kraken/dl/minikraken_20171019_8GB.tgz",
        "https://ccb.jhu.edu/software/kraken/dl/minikraken_20171101_8GB_dustmasked.tgz"
    ]) | DownloadKrakenV1
}

workflow KrakenV2 {
    Channel.from([
        "ftp://ftp.ccb.jhu.edu/pub/data/kraken2_dbs/old/minikraken2_v1_8GB_201904.tgz",
        "ftp://ftp.ccb.jhu.edu/pub/data/kraken2_dbs/old/minikraken2_v2_8GB_201904.tgz"
    ]) | DownloadKrakenV2
}

workflow Kraken {
    KrakenV1()
    KrakenV2()
}