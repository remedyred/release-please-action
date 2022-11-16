import {GitHub, OctokitAPIs} from 'release-please/build/src/github'
import {Logger} from 'release-please'
import {useInputs} from './inputs'

interface ProxyOption {
	host: string
	port: number
}

interface GitHubCreateOptions {
	owner: string
	repo: string
	defaultBranch?: string
	apiUrl?: string
	graphqlUrl?: string
	octokitAPIs?: OctokitAPIs
	token?: string
	logger?: Logger
	proxy?: ProxyOption
}

export function getGitHubInstance() {
	const {token, defaultBranch, apiUrl, graphqlUrl, repoUrl, proxyServer} = useInputs()
	const [owner, repo] = repoUrl.split('/')

	let proxy
	if (proxyServer) {
		const [host, port] = proxyServer.split(':')
		proxy = {host, port}
	}
	const githubCreateOpts: GitHubCreateOptions = {
		proxy,
		owner,
		repo,
		apiUrl,
		graphqlUrl,
		token
	}
	if (defaultBranch) {
		githubCreateOpts.defaultBranch = defaultBranch
	}
	return GitHub.create(githubCreateOpts)
}
