# Folder, SQL data and lyrx file to convert
export BASE_PATH=
export SQL_SCRIPT=
export LYRX_FILE=

# DB schema for the geodata
export PG_SCHEMA=agis

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
