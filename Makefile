include config.mk

init-db: ## Create db and schema, add postgis extension
	psql -h localhost -U postgres -c 'CREATE DATABASE geodata;'
	psql -h localhost -U postgres -d geodata -c 'CREATE EXTENSION postgis;'
	psql -h localhost -U postgres --d geodata -c 'CREATE SCHEMA '$(PG_SCHEMA)';'
	touch $@

init-geoserver: ## Create workspace and add postgis datastore to GeoServer
init-geoserver: init-db
	curl -u admin:geoserver -POST -H "Content-type: text/xml"  -d "<workspace><name>$(GEOSERVER_WORKSPACE)</name></workspace>"  $(GEOSERVER_URL)"rest/workspaces"
	curl -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "$$DATASTORE_XML" $(GEOSERVER_URL)"rest/workspaces/"$(GEOSERVER_WORKSPACE)"/datastores"
	touch $@

.PHONY: serve
serve: ## Start docker composition
serve: init-geoserver
	docker-compose up -d

.PHONY: convert
convert: ## Convert a style from lyrx to sld (input files set in config.mk) and upload it to GeoServer
convert: serve
	psql -h localhost -U postgres -d geodata -a -f $(BASE_PATH)/$(SQL_SCRIPT)
	curl --location -d @$(BASE_PATH)/$(LYRX_FILE) $(LYRX2SLD_URL) -o $(BASE_PATH)/output.zip
	curl -u admin:geoserver -XPOST -H "Content-type: application/zip" --data-binary @$(BASE_PATH)/output.zip $(GEOSERVER_URL)rest/styles

.PHONY: clean
clean: ## Delete style from GeoServer
	curl -u admin:geoserver -XDELETE $(GEOSERVER_URL)rest/styles/Default+Styler.json

.PHONY: clean-all
clean-all: ## Reset db and GeoServer
clean-all: clean
	rm -f init-db
	rm -f init-geoserver
	curl -u admin:geoserver -X DELETE $(GEOSERVER_URL)rest/workspaces/$(GEOSERVER_WORKSPACE)?recurse=true -H  "accept: application/json" -H  "content-type: application/json"
	psql -h localhost -U postgres -c 'DROP DATABASE geodata;'