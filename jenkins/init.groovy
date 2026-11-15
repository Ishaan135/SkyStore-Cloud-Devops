import jenkins.model.*
import hudson.security.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.*
import hudson.triggers.SCMTrigger

def j = Jenkins.get()
// Demo login: admin / admin
def realm = new HudsonPrivateSecurityRealm(false)
realm.createAccount('admin', 'admin')
j.setSecurityRealm(realm)
def strat = new FullControlOnceLoggedInAuthorizationStrategy()
strat.setAllowAnonymousRead(true)
j.setAuthorizationStrategy(strat)

if (j.getItem('SkyStore-Pipeline') == null) {
  def job = j.createProject(WorkflowJob, 'SkyStore-Pipeline')
  def scm = new GitSCM('file:///srv/skystore')
  scm.branches = [new BranchSpec('*/main')]
  job.definition = new CpsScmFlowDefinition(scm, 'Jenkinsfile')
  job.save()
}
var job = j.getItem('SkyStore-Pipeline')
if (job.getLastBuild() == null) {
  job.scheduleBuild2(5)   // first build runs automatically
}
j.save()
