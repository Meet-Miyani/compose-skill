.PHONY: test validate-skill

test:
	bash tests/skills/compose-architecture/run-tests.sh

validate-skill:
	status=0; for skill in skills/*/; do ./scripts/validate-skill.sh "$$skill" || status=1; done; exit $$status
