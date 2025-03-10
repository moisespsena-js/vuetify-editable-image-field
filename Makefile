build:
	./env.sh build_pj

.PHONY: dist
dist:
	./env.sh docker_build_pj


.PHONY: dist-clean
dist-clean:
	rm -rf dist

.PHONY: clean
clean:
	rm -rf node_modules .pnpm-store

dev:
	./env.sh pj_pnpm run dev