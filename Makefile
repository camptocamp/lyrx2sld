include config.mk

.PHONY: help
help: ## Display this help message
	@echo "Usage: make <target>"
	@echo
	@echo "Available targets:"
	@grep --extended-regexp --no-filename '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "	%-20s%s\n", $$1, $$2}'

docker-compose-up: ## Start docker composition
docker-compose-up:
	docker build -t lyrx2sld .
	docker-compose up -d
	sleep 5 # wait a bit on services
	touch $@

init-db: ## Create db and schema, add postgis extension
init-db: docker-compose-up
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -c 'CREATE DATABASE $(PG_DATABASE);'
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -d $(PG_DATABASE) -c 'CREATE EXTENSION postgis;'
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -d $(PG_DATABASE) -c 'CREATE SCHEMA '$(PG_SCHEMA)';'
	touch $@

init-geoserver: ## Create workspace and add postgis datastore to GeoServer
init-geoserver: init-db
	curl -u admin:geoserver -POST -H "Content-type: text/xml"  -d "<workspace><name>$(GEOSERVER_WORKSPACE)</name></workspace>"  $(GEOSERVER_URL)"rest/workspaces"
	curl -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "$$DATASTORE_XML" $(GEOSERVER_URL)"rest/workspaces/"$(GEOSERVER_WORKSPACE)"/datastores"
	touch $@

.PHONY: serve
serve: ## Start docker composition and initialize DB and GeoServer
serve: init-geoserver

.PHONY: convert
convert: ## Convert a style from lyrx to sld (input files set in config.mk) and upload it to GeoServer
convert: serve
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -d $(PG_DATABASE) -a -f $(BASE_PATH)/$(SQL_SCRIPT)
	curl -H 'Content-Type: application/json' --location -d @$(BASE_PATH)/$(LYRX_FILE) $(LYRX2SLD_URL) -o $(BASE_PATH)/output.zip
	curl -u admin:geoserver -XPOST -H "Content-type: application/zip" --data-binary @$(BASE_PATH)/output.zip $(GEOSERVER_URL)rest/styles

.PHONY: update
update: ## Convert again the lyrx and update the already existing "Default Styler" style.
	curl -H 'Content-Type: application/json'--location -d @$(BASE_PATH)/$(LYRX_FILE) $(LYRX2SLD_URL) -o $(BASE_PATH)/output.zip
	curl -u admin:geoserver -XPUT -H "Content-type: application/zip" --data-binary @$(BASE_PATH)/output.zip $(GEOSERVER_URL)rest/styles/Default%20Styler

.PHONY: stop
stop: ## Stop composition
stop: clean-all
	rm -f docker-compose-up
	docker-compose down

.PHONY: clean
clean: ## Delete style from GeoServer
	curl -u admin:geoserver -XDELETE $(GEOSERVER_URL)rest/styles/Default%20Styler || true

.PHONY: clean-all
clean-all: ## Reset db and GeoServer
clean-all: clean
	rm -f init-db
	rm -f init-geoserver
	curl -u admin:geoserver -X DELETE $(GEOSERVER_URL)rest/workspaces/$(GEOSERVER_WORKSPACE)?recurse=true -H  "accept: application/json" -H  "content-type: application/json"
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -c 'DROP DATABASE $(PG_DATABASE);'
