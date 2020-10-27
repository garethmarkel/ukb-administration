#!/usr/bin/env nextflow
nextflow.preview.dsl=2
params.version=false
params.help=false
version='0.0.1'
timestamp='2019-11-18'
if(params.version) {
    System.out.println("")
    System.out.println("Run Set Analysis - Version: $version ($timestamp)")
    exit 1
}


