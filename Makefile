.PHONY: test validate-skill

test:
	bash tests/skills/compose-architecture/run-tests.sh

validate-skill:
	./scripts/validate-skill.sh
