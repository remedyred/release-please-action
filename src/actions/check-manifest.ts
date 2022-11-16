import {useInputs} from '../utilities/inputs'
import glob from '@actions/glob'

export async function checkManifest(): Promise<boolean> {
	const {configFile, manifestFile} = useInputs()
	const patterns = [`**/${configFile}`, `**/${manifestFile}`]
	const globber = await glob.create(patterns.join('\n'))
	const files = await globber.glob()
	return files.length > 0
}
