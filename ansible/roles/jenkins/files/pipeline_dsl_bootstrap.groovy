import jenkins.*;
import jenkins.model.*;
import hudson.model.*;
import hudson.triggers.SCMTrigger;
import hudson.plugins.git.GitSCM;
import hudson.plugins.git.BranchSpec;
import com.cloudbees.plugins.credentials.domains.Domain;
import com.cloudbees.plugins.credentials.CredentialsScope;
import com.cloudbees.plugins.credentials.SystemCredentialsProvider;
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl;
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey;
import javaposse.jobdsl.plugin.*;
import com.cloudbees.jenkins.plugins.awscredentials.*;
import hudson.security.csrf.DefaultCrumbIssuer;
import hudson.markup.RawHtmlMarkupFormatter;

jenkins = Jenkins.instance;
// two is enough for master since we have slaves
jenkins.setNumExecutors(1);
jenkins.setCrumbIssuer(new DefaultCrumbIssuer(true));

jenkins.setMarkupFormatter(new RawHtmlMarkupFormatter(false))
jenkins.save()

def p = AgentProtocol.all()
p.each { x ->
    if (x.name?.contains("CLI")) {
        p.remove(x)
    }
}

def removal = { lst ->
    lst.each { x ->
        if (x.getClass().name.contains("CLIAction")) {
            lst.remove(x)
        }
    }
}

def j = Jenkins.instance
removal(j.getExtensionList(RootAction.class))
removal(j.actions)
// Disable script security
GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class).useScriptSecurity=false
GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class).save()
jenkins.save();

String pipelineScripts = '''
  pipelineJob('Hygieia Job') {
    logRotator(-1, 20, -1, -1)
    configure {
         it / definition / lightweight(true)
    }
    concurrentBuild(false)
    definition {
        cpsScm {
            scm {
                scriptPath ('Jenkinsfile')
                git {
                    branches('master')
                    remote {
                        url ('https://github.com/aetorres/Hygieia.git')
                        
                    }
                }
            }
        }
    }
}

 '''


dsl = new hudson.model.FreeStyleProject(jenkins, "pipeline-dsl-bootstrap");
gitTrigger1 = new SCMTrigger("* * * * *");
dsl.addTrigger(gitTrigger1);

def jobDslBuildStep = new ExecuteDslScripts(
                            scriptText: pipelineScripts,
                             usingScriptText: true,
                            // ignoreExisting: false,
                            // removedJobAction: RemovedJobAction.DELETE,
                            // removedViewAction: RemovedViewAction.IGNORE
                            );

dsl.getBuildersList().add(jobDslBuildStep);


jenkins.add(dsl, "pipeline-dsl-bootstrap");

def job1 = jenkins.getItem(dsl.name)
job1.scheduleBuild()