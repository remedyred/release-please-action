#!/usr/bin/env node

import {getGitHubInstance} from './utilities/GitHub'
import {runManifest} from './actions/run-manifest'
import {outputReleases} from './actions/output-releases'
import {outputPRs} from './actions/output-prs'
import {manifestInstance} from './utilities/Manifest'
import {GITHUB_RELEASE_COMMAND, GITHUB_RELEASE_PR_COMMAND, MANIFEST_COMMANDS} from './common'
import {useInputs} from './utilities/inputs'
import core from '@actions/core'

async function main() {
	const {command} = useInputs()

	if (MANIFEST_COMMANDS.includes(command)) {
		return await runManifest()
	}
	const github = await getGitHubInstance()

	// First we check for any merged release PRs (PRs merged with the label
	// "autorelease: pending"):
	if (!command || command === GITHUB_RELEASE_COMMAND) {
		const manifest = await manifestInstance(github)
		outputReleases(await manifest.createReleases())
	}

	// Next we check for PRs merged since the last release, and groom the
	// release PR:
	if (!command || command === GITHUB_RELEASE_PR_COMMAND) {
		const manifest = await manifestInstance(github)
		outputPRs(await manifest.createPullRequests())
	}
}

main().catch(error => {
	core.setFailed(`release-please failed: ${error.message}`)
})
