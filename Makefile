APP := composekit

.PHONY: build test smoke validate-skill clean snapshot

build:
	go build -o bin/$(APP) .

test:
	go test ./...

smoke:
	./scripts/smoke-test.sh

validate-skill:
	./scripts/validate-skill.sh

clean:
	rm -rf bin dist tmp-smoke tmp-skills

snapshot:
	goreleaser release --snapshot --clean
