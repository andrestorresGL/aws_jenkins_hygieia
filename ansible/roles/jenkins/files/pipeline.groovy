pipelineJob('Test Hygieia') { 
    logRotator(-1, 50, -1, -1)
    configure {
         it / definition / lightweight(true)
    }
    
    concurrentBuild(false)
    definition {
        cps {
            script('/var/lib/jenkins/pipeline_dsl_bootstrap.groovy')
            sandbox(true)
        }
        }
}