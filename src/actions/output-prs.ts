import core from '@actions/core'

export function outputPRs(prs) {
	prs = prs.filter(pr => pr !== undefined)
	if (prs.length) {
		core.setOutput('pr', prs[0])
		core.setOutput('prs', JSON.stringify(prs))
	}
}
