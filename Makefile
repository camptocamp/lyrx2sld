include config.mk

# Folder, SQL data and lyrx file to convert
BASE_PATH ?= /to-define
SQL_SCRIPT ?= to.define
LYRX_FILE ?= to.define
export BASE_PATH
export SQL_SCRIPT
export LYRX_FILE

# DB schema for the geodata
PG_SCHEMA ?= agis
export PG_SCHEMA

# lyrx2sld URL
export LYRX2SLD_URL=http://localhost/v1/lyrx2sld/

# Config for GeoServer workspace and datastore
export GEOSERVER_URL=http://localhost:8080/geoserver/
export GEOSERVER_WORKSPACE=agis
define DATASTORE_XML
<dataStore>
	<name>postgis</name>
	<connectionParameters>
		<host>db</host>
		<port>5432</port>
		<database>geodata</database>
		<schema>$(PG_SCHEMA)</schema>
		<user>postgres</user>
		<passwd>postgres</passwd>
		<dbtype>postgis</dbtype>
	</connectionParameters>
</dataStore>
endef
export DATASTORE_XML

## Create db and schema, add postgis extension
init-db:
	psql -h localhost -U postgres -c 'CREATE DATABASE geodata;'
	psql -h localhost -U postgres -d geodata -c 'CREATE EXTENSION postgis;'
	psql -h localhost -U postgres --d geodata -c 'CREATE SCHEMA '$(PG_SCHEMA)';'
	touch $@

## Create workspace and add postgis datastore to GeoServer
init-geoserver: init-db
	curl -u admin:geoserver -POST -H "Content-type: text/xml"  -d "<workspace><name>$(GEOSERVER_WORKSPACE)</name></workspace>"  $(GEOSERVER_URL)"rest/workspaces"
	curl -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "$$DATASTORE_XML" $(GEOSERVER_URL)"rest/workspaces/"$(GEOSERVER_WORKSPACE)"/datastores"
	touch $@

## start docker composition
docker-compose-up:
	docker-compose up -d
	sleep 5 # wait a bit on services
	touch $@

## Stop composition 
.PHONY: stop
stop:
	docker-compose down
	rm -f docker-compose-up

## Start docker composition and init geoserver
.PHONY: serve
serve: docker-compose-up init-geoserver

## Convert a style from lyrx to sld (input files set in config.mk) and upload it to GeoServer
.PHONY: convert
convert: serve
	psql -h localhost -U postgres -d geodata -a -f $(BASE_PATH)/$(SQL_SCRIPT)
	curl --location -d @$(BASE_PATH)/$(LYRX_FILE) $(LYRX2SLD_URL) -o $(BASE_PATH)/output.zip
	curl -u admin:geoserver -XPOST -H "Content-type: application/zip" --data-binary @$(BASE_PATH)/output.zip $(GEOSERVER_URL)rest/styles

## Delete style from GeoServer
.PHONY: clean
clean: 
	curl -u admin:geoserver -XDELETE $(GEOSERVER_URL)rest/styles/Default+Styler.json

## Reset db and GeoServer
.PHONY: clean-all
clean-all: clean
	rm -f init-db
	rm -f init-geoserver
	curl -u admin:geoserver -X DELETE $(GEOSERVER_URL)rest/workspaces/$(GEOSERVER_WORKSPACE)?recurse=true -H  "accept: application/json" -H  "content-type: application/json"
	psql -h localhost -U postgres -c 'DROP DATABASE geodata;'
