import javaposse.jobdsl.plugin.*;
def jobDslBuildStep = new ExecuteDslScripts(
                            targets: "pipelines_dsl_bootstrap.groovy",
                            usingScriptText: false,
                            ignoreExisting: false,
                            removedJobAction: RemovedJobAction.DELETE,
                            removedViewAction: RemovedViewAction.IGNORE
                            );
