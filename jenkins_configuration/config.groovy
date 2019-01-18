import static jenkins.model.Jenkins.instance as jenkins
import jenkins.model.JenkinsLocationConfiguration

import jenkins.branch.OrganizationFolder
import org.jenkinsci.plugins.github_branch_source.BranchDiscoveryTrait
import org.jenkinsci.plugins.github_branch_source.GitHubSCMNavigator
import org.jenkinsci.plugins.github_branch_source.OriginPullRequestDiscoveryTrait

try {

    def githubOrg = 'cegeka'

    // Delete Openshift demo-job
    def matchedJobs = jenkins.items.findAll { job ->
      job.name =~ /OpenShift Sample/
    }

    if (!matchedJobs.isEmpty()) {
        println "--> Deleting following jobs:"
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
    navigator.credentialsId = 'ci00053160-puppetserver-github-credentials' // Loaded above in the GitHub section.

    navigator.traits = [
        // Too many repos to scan everything. This trims to a svelte 265 repos at the time of writing.
        new jenkins.scm.impl.trait.WildcardSCMSourceFilterTrait('puppet-monorepo', ''),
        new jenkins.scm.impl.trait.RegexSCMHeadFilterTrait('^PR-.*'), // we're only interested in PR branches, nothing else
        new BranchDiscoveryTrait(2), // only branches that are also filed as PR
        new OriginPullRequestDiscoveryTrait(2), // Take only head
    ]

    folder.navigators.replace(navigator)


    def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()
    jenkinsLocationConfiguration.setUrl("https://jenkins-ci00053160-puppetserver.apps.openshift.cegeka.com")
    jenkinsLocationConfiguration.save()


    println '--> Saving Jenkins config'
    jenkins.save()

    println '--> Scheduling GitHub organization scan'

    Thread.start {
        sleep 30000 // 30 seconds
        println '--> Running GitHub organization scan'
        folder.scheduleBuild()
    }

    println "--> Configuration of jenkins is done"
}
catch(Throwable exc) {
    println '!!! Error configuring jenkins'
    org.codehaus.groovy.runtime.StackTraceUtils.sanitize(new Exception(exc)).printStackTrace()
    println '!!! Shutting down Jenkins to prevent possible mis-configuration from going live'
    jenkins.cleanUp()
    System.exit(1)
}

