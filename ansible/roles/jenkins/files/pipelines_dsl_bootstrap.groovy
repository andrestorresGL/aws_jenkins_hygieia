#!/usr/bin/env groovy
mavenJob('Build Hygieia Images') {
    logRotator(-1, 10)
    jdk('java8')
    scm {
        github('aetorres/Hygieia', 'master')
    }
    triggers {
        githubPush()
    }
   preBuildSteps {
        shell("mvn docker:build")
    }
    publishers {
        postBuildScripts {
            steps {
                shell('''
                docker login -u atorresd -p *23Andres**
                docker push atorresd/hygieia-ui
                docker push atorresd/hygieia-score-collector
                docker push atorresd/hygieia-nexus-iq-collector
                docker push atorresd/hygieia-hspm-cmdb-collector
                docker push atorresd/hygieia-gitlab-scm-collector
                docker push atorresd/hygieia-subversion-scm-collector
                docker push atorresd/hygieia-github-scm-collector

                docker push atorresd/hygieia-bitbucket-scm-collector
                docker push atorresd/hygieia-appdynamics-collector
                docker push atorresd/hygieia-chat-ops-collector

                docker push atorresd/hygieia-versionone-collector
                docker push atorresd/hygieia-jira-feature-collector
                docker push atorresd/hygieia-xldeploy-collector
                docker push atorresd/hygieia-udeploy-collector
                docker push atorresd/hygieia-sonar-codequality-collector
                docker push atorresd/hygieia-jenkins-codequality-collector
                docker push atorresd/hygieia-jenkins-cucumber-test-collector
                docker push atorresd/hygieia-jenkins-build-collector
                docker push atorresd/hygieia-bamboo-build-collector
                docker push atorresd/hygieia-artifactory-artifact-collector
                docker push atorresd/hygieia-apiaudit
                docker push atorresd/hygieia-api
            ''')
            }
            onlyIfBuildSucceeds(true)
           
        }
    }
}