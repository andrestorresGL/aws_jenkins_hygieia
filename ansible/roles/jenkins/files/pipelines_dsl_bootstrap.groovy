#!/usr/bin/env groovy
mavenJob('Build Hygieia Images') {
    logRotator(-1, 10)
    jdk('java8')
    scm {
        git {
            remote {
                name('origin')
                url('https://github.com/aetorres/Hygieia.git')
              }
            
            branch('master')
        }
    }   
    triggers {
        githubPush()
    }
   preBuildSteps {
        shell(''' mvn clean install package 
         mvn docker:build
         ''')
    }
    publishers {
        postBuildScripts {
            steps {
                shell('''
                docker login -u atorresd -p ******
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