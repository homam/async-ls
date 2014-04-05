compositions = require \./compositions
lists = require \./lists

async = {
	compositions.returnA
	compositions.ffmapA
	compositions.bindA
	compositions.fbindA
	compositions.kcompA

	compositions.returnE
	compositions.fmapE
	compositions.ffmapE
	compositions.bindE
	compositions.fbindE
	compositions.kcompE
	compositions.foldE

	compositions.transformAE
	compositions.ftransformAE
	compositions.transformEA
	compositions.ftransformEA

	compositions.returnL
	compositions.bindL

	compositions.returnW
	compositions.bindW
	compositions.tellW

	compositions.returnWl
	compositions.bindWl

	lists.serial-map
	lists.parallel-map
	lists.parallel-map-limited

	lists.parallel-filter
	lists.serial-filter
	lists.parallel-limited-filter

	lists.parallel-any
	lists.serial-any
	lists.parallel-limited-any

	lists.parallel-all
	lists.serial-all
	lists.parallel-limited-all
}

async.VERSION = '0.0.1'
module.exports = async