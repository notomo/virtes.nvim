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
