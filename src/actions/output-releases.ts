import core from '@actions/core'

export function outputReleases(releases) {
	releases = releases.filter(release => release !== undefined)
	const pathsReleased = []
	if (releases.length) {
		core.setOutput('releases_created', true)
		for (const release of releases) {
			const path = release.path || '.'
			if (path) {
				pathsReleased.push(path)
				// If the special root release is set (representing project root)
				// and this is explicitly a manifest release, set the release_created boolean.
				if (path === '.') {
					core.setOutput('release_created', true)
				} else {
					core.setOutput(`${path}--release_created`, true)
				}
			}
			for (let [key, val] of Object.entries(release)) {
				// Historically tagName was output as tag_name, keep this
				// consistent to avoid breaking change:
				if (key === 'tagName') {
					key = 'tag_name'
				}
				if (key === 'uploadUrl') {
					key = 'upload_url'
				}
				if (key === 'notes') {
					key = 'body'
				}
				if (key === 'url') {
					key = 'html_url'
				}
				if (path === '.') {
					core.setOutput(key, val)
				} else {
					core.setOutput(`${path}--${key}`, val)
				}
			}
		}
	}
	// Paths of all releases that were created, so that they can be passed
	// to matrix in next step:
	core.setOutput('paths_released', JSON.stringify(pathsReleased))
}
