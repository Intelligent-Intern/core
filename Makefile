down:
	sudo ./infra/makescripts/infra-down.sh

prepare:
	sudo ./infra/makescripts/infra-prepare.sh

up:
	sudo ./infra/makescripts/infra-up.sh

neo4j_restart:
	sudo ./infra/makescripts/neo4j-restart.sh

python_app_restart:
	sudo ./infra/makescripts/python-app-container-restart.sh

test:
	./app/tests/run.sh

deploy_base_lib:
	./service/core/iilib/deploy.sh