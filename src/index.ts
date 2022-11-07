#!/usr/bin/env node

import {cli} from '@snickbit/node-cli'
import {beforeExit} from '@snickbit/node-utilities'
import {out} from '@snickbit/out'

cli().name('@remedyred/release-please').run(async () => {
	out.info('Starting Release Please...')
	beforeExit(() => {
		out.info('Exiting Release Please...')
	})
})
