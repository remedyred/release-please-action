import {getGitHubInstance} from '../utilities/GitHub'
import {Bootstrapper} from 'release-please/build/src/Bootstrapper'
import {useInputs} from '../utilities/inputs'

export async function bootstrap() {
	const {
		configFile,
		manifestFile,
		path,
		releaseType,
		versioning,
		bumpMinorPreMajor,
		bumpPatchForMinorPreMajor,
		releaseAs,
		skipGithubRelease,
		draft,
		prerelease,
		draftPullRequest,
		component,
		packageName,
		includeComponentInTag,
		includeVInTag,
		pullRequestTitlePattern,
		pullRequestHeader,
		tagSeparator,
		separatePullRequests,
		labels,
		releaseLabels,
		extraLabels,
		initialVersion,
		changelogSections,
		changelogPath,
		changelogType,
		changelogHost,
		versionFile,
		extraFiles,
		snapshotLabels,
		skipSnapshot
	} = useInputs()
	// github: GitHub, targetBranch: string, manifestFile?: string, configFile?: string, initialVersionString?: string
	const github = await getGitHubInstance()
	const bootstrapper = new Bootstrapper(github, github.repository.defaultBranch, manifestFile, configFile)
	const pullRequest = await bootstrapper.bootstrap(path, {
		releaseType,
		versioning,
		bumpMinorPreMajor,
		bumpPatchForMinorPreMajor,
		releaseAs,
		skipGithubRelease,
		draft,
		prerelease,
		draftPullRequest,
		component,
		packageName,
		includeComponentInTag,
		includeVInTag,
		pullRequestTitlePattern,
		pullRequestHeader,
		tagSeparator,
		separatePullRequests,
		labels,
		releaseLabels,
		extraLabels,
		initialVersion,
		changelogSections,
		changelogPath,
		changelogType,
		changelogHost,
		versionFile,
		extraFiles,
		snapshotLabels,
		skipSnapshot
	})
}
