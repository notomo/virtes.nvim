VERSION :=
ROCKSPEC_FILE := rockspec/virtes-${VERSION}-1.rockspec

release: new_rockspec
	luarocks install dkjson
	luarocks upload ${ROCKSPEC_FILE} --temp-key=${LUAROCKS_API_KEY}
.PHONY: release

new_rockspec:
	luarocks new_version rockspec/virtes-x.x.x-1.rockspec --dir rockspec --tag=v${VERSION}
	cat ${ROCKSPEC_FILE}
	luarocks make ${ROCKSPEC_FILE}
.PHONY: new_rockspec

test:
	vusted --shuffle -v --helper=./spec/helper.lua
.PHONY: test

_init:
	luarocks write_rockspec --lua-versions=5.1
.PHONY: _init

bump:
	echo "version: " v${VERSION}
	test ! ${VERSION} = ""
	git tag -a v${VERSION} -m "Bump v"${VERSION}
	git push origin v${VERSION}
.PHONY: bump
