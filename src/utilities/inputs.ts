import {isEmpty, isNullDefined, JSONParse, parse} from '@snickbit/utilities'
import {CONFIG_FILE, GITHUB_API_URL, GITHUB_GRAPHQL_URL, MANIFEST_FILE} from '../common'
import core from '@actions/core'

export const inputs = {
	command: getInput('command'),
	configFile: getInput('config-file', CONFIG_FILE),
	manifestFile: getInput('manifest-file', MANIFEST_FILE),
	signoff: getInput('signoff'),
	fork: !!getInput('fork'),
	defaultBranch: getInput('default-branch', 'main'),
	repoUrl: getInput('repo-url', process.env.GITHUB_REPOSITORY),
	apiUrl: getInput('github-api-url', GITHUB_API_URL),
	graphqlUrl: getInput('github-graphql-url', GITHUB_GRAPHQL_URL).replace(/\/graphql$/, ''),
	token: ghInput('token', {required: true}),
	proxyServer: getInput('proxy-server'),
	bumpMinorPreMajor: !!getInput('bump-minor-pre-major'),
	bumpPatchForMinorPreMajor: !!getInput('bump-patch-for-minor-pre-major'),
	monorepoTags: !!getInput('monorepo-tags'),
	packageName: getInput('package-name'),
	path: getInput('path'),
	releaseType: getInput('release-type'),
	changelogPath: getInput('changelog-path'),
	changelogSections: [], // calculated below
	changelogHost: getInput('changelog-host'),
	changelogTypes: getInput('changelog-types'),
	versionFile: getInput('version-file'),
	extraFiles: getMultiInput('extra-files'),
	pullRequestTitlePattern: getInput('pull-request-title-pattern'),
	draft: !!getInput('draft'),
	draftPullRequest: !!getInput('draft-pull-request'),
	changelogType: getInput('changelog-notes-type'),
	versioning: getInput('versioning-strategy'),
	releaseAs: getInput('release-as'),
	skipGithubRelease: !!getInput('skip-github-release'),
	prerelease: !!getInput('prerelease'),
	component: getInput('component'),
	includeVInTag: !!getInput('include-v-in-tag'),
	tagSeparator: getInput('tag-separator'),
	snapshotLabels: getMultiInput('snapshot-labels'),
	bootstrapSha: getInput('bootstrap-sha'),
	lastReleaseSha: getInput('last-release-sha'),
	alwaysLinkLocal: !!getInput('always-link-local'),
	separatePullRequests: !!getInput('separate-pull-requests'),
	plugins: getMultiInput('plugins'),
	labels: getMultiInput('labels'),
	releaseLabels: getMultiInput('release-labels'),
	skipLabeling: !!getInput('skip-labeling'),
	sequentialCalls: !!getInput('sequential-calls'),
	groupPullRequestTitlePattern: getInput('group-pull-request-title-pattern'),
	releaseSearchDepth: getInput('release-search-depth') as number,
	commitSearchDepth: getInput('commit-search-depth') as number,
	includeComponentInTag: !!getInput('include-component-in-tag'),
	pullRequestHeader: getInput('pull-request-header'),
	extraLabels: getMultiInput('extra-labels'),
	initialVersion: getInput('initial-version', '0.0.0'),
	skipSnapshot: !!getInput('skip-snapshot')
}

export function useInputs() {
	return inputs
}

inputs.changelogSections = JSONParse(inputs.changelogTypes) as string[]

interface GetInputOptions {
	fallback?: any
	as?: 'boolean' | 'number' | 'string'
	required?: boolean
	multiline?: boolean
}

export function ghInput<T = any>(key: string, options: GetInputOptions & {multiline: true}): T[]
export function ghInput<T = any>(key: string, options?: GetInputOptions): T
export function ghInput<T = any>(key: string, options?: GetInputOptions): T {
	return parse(options?.multiline
		? core.getMultilineInput(key, {required: options?.required})
		: core.getInput(key, {required: options?.required}))
}

export function getInput<T = string>(key: string, fallback: T, options: GetInputOptions & {multiline: true}): T[]
export function getInput<T = string>(key: string, fallback?: T, options?: GetInputOptions): T
export function getInput<T = string>(key: string, fallback?: T, options?: GetInputOptions): T | T[] {
	const value = ghInput(key, {...options, fallback})

	if (isNullDefined(value) || isEmpty(value)) {
		return fallback
	}

	return value
}

export function getMultiInput<T = string>(key: string, fallback?: T, options?: GetInputOptions): T[] {
	return getInput(key, fallback, {...options, multiline: true})
}

export function getManifestInput() {
	const {manifestFile, configFile, signoff} = useInputs()
	return {configFile, manifestFile, signoff}
}
