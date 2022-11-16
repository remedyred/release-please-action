import {getGitHubInstance} from '../utilities/GitHub'
import {Manifest} from 'release-please/build/src/manifest'
import {outputReleases} from './output-releases'
import {outputPRs} from './output-prs'
import {checkManifest} from './check-manifest'
import {bootstrap} from './bootstrap'
import {getManifestInput, useInputs} from '../utilities/inputs'

export async function runManifest() {
	const {command} = useInputs()

	if (command === 'bootstrap' || !await checkManifest()) {
		return bootstrap()
	}

	// Create the Manifest and GitHub instance from
	// argument provided to GitHub action:
	const {fork, signoff} = useInputs()
	const manifestOpts = getManifestInput()
	const github = await getGitHubInstance()
	let manifest = await Manifest.fromManifest(github,
		github.repository.defaultBranch,
		manifestOpts.configFile,
		manifestOpts.manifestFile,
		{
			signoff,
			fork
		})
	// Create or update release PRs:
	outputPRs(await manifest.createPullRequests())
	if (command !== 'manifest-pr') {
		manifest = await Manifest.fromManifest(github,
			github.repository.defaultBranch,
			manifestOpts.configFile,
			manifestOpts.manifestFile,
			{
				signoff,
				fork
			})
		outputReleases(await manifest.createReleases())
	}
}
