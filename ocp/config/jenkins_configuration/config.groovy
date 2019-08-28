import static jenkins.model.Jenkins.instance as jenkins
import jenkins.model.JenkinsLocationConfiguration

import jenkins.branch.OrganizationFolder
import org.jenkinsci.plugins.github_branch_source.GitHubSCMNavigator
import org.jenkinsci.plugins.github_branch_source.BranchDiscoveryTrait
import org.jenkinsci.plugins.github_branch_source.OriginPullRequestDiscoveryTrait
import org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait
import jenkins.plugins.git.traits.RefSpecsSCMSourceTrait
import hudson.model.*
import org.jenkinsci.plugins.scriptsecurity.scripts.*

try {

    def githubOrg = '${GITHUBORG}'

    // Delete Openshift demo-job
    def matchedJobs = jenkins.items.findAll { job ->
      job.name =~ /OpenShift Sample/
    }

    if (!matchedJobs.isEmpty()) {
        println '--> Deleting following jobs:'
        matchedJobs.each { job ->
            println job.name
            job.delete()
        }
    }

    // Configure Github Branch Source plugin
    println '--> Creating organization folder'
    // Create the top-level item if it doesn't exist already.
    def folder = jenkins.items.isEmpty() ? jenkins.createProject(OrganizationFolder, 'Cegeka') : jenkins.items[0]
    // Set up GitHub source.
    def navigator = new GitHubSCMNavigator(githubOrg)
    navigator.credentialsId = '${PROJECT}-github-credentials' // Loaded above in the GitHub section.

    navigator.traits = [
        // Too many repos to scan everything. This trims to a svelte 265 repos at the time of writing.
        new jenkins.scm.impl.trait.WildcardSCMSourceFilterTrait('puppet-monorepo', ''),
        new jenkins.scm.impl.trait.RegexSCMHeadFilterTrait('(^PR-.*)|master'), // we're only interested in PR branches, nothing else
        new BranchDiscoveryTrait(3),
        new ForkPullRequestDiscoveryTrait(2,new ForkPullRequestDiscoveryTrait.TrustContributors()),
        new OriginPullRequestDiscoveryTrait(1), // Merge pull request with the target branch
        new RefSpecsSCMSourceTrait('+refs/heads/master:refs/remotes/@{remote}/master')
    ]

    folder.navigators.replace(navigator)


    def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()
    jenkinsLocationConfiguration.setUrl('https://puppetserver-jenkins.apps.openshift.cegeka.com')
    jenkinsLocationConfiguration.save()


    println '--> Saving Jenkins config'
    jenkins.save()

    println '--> Scheduling GitHub organization scan'

    Thread.start {
        sleep 30000 // 30 seconds
        println '--> Running GitHub organization scan'
        folder.scheduleBuild()
    }
    // Initial number of executors is 1, let's increase the number of executors to 2
    Hudson hudson = Hudson.getInstance()
    hudson.setNumExecutors(10)
    hudson.save()

    toApprove=['method hudson.model.Job getBuilds',
               'method hudson.model.Run getNumber',
               'method hudson.model.Run isBuilding',
               'method java.io.File exists',
               'method java.io.File mkdirs',
               'method jenkins.model.Jenkins getItemByFullName java.lang.String',
               'new java.io.File java.lang.String',
               'staticMethod jenkins.model.Jenkins getInstance',
               'staticMethod org.codehaus.groovy.runtime.DefaultGroovyMethods take java.util.List int']
    toApprove.each {pending -> ScriptApproval.get().approveScript(pending)}

    println '--> Configuration of jenkins is done'
}
catch(Throwable exc) {
    println '!!! Error configuring jenkins'
    org.codehaus.groovy.runtime.StackTraceUtils.sanitize(new Exception(exc)).printStackTrace()
    println '!!! Shutting down Jenkins to prevent possible mis-configuration from going live'
    jenkins.cleanUp()
    System.exit(1)
}
