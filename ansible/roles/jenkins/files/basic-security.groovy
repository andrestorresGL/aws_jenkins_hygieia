
import hudson.security.*
import jenkins.model.*

def instance = Jenkins.getInstance()

def desc = instance.getDescriptor("hudson.tasks.Maven")
def minst =  new hudson.tasks.Maven.MavenInstallation("maven353", "/usr/local/maven");
desc.setInstallations(minst)
desc.save()


def dis = new hudson.model.JDK.DescriptorImpl();
dis.setInstallations( new hudson.model.JDK("jdk8", "/usr/java/jdk1.8.0_171-amd64"));
dis.save();

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()
