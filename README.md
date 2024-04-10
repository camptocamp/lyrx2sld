# lyrx2sld
lyrx2sld is a REST service for the conversion of ArcGIS Pro styling (format .lyrx) to GeoServer (format .sld, encapsulated in a .zip archive together with legend images, if any). The service encapsulates a styling library (see below for details) and runs in Docker.

## Styling library
The service encapsulates the [bridge-style](https://github.com/camptocamp/bridge-style) library, which is written in Python and originally designed to be able to be used in plugins for ArcGis Desktop and QGIS Desktop, with the goal of allowing users to publish layer symbology to GeoServer.
For that purpose, this library uses the [Geostyler](https://github.com/geostyler) JSON representation as a common internal representation format. 
To meet the goals of lyrx2sld, this library was enhanced regarding its capabilities of interpreting the Lyrx format.
See the [Cartographic Information Model documentation](https://github.com/Esri/cim-spec/tree/master/docs/v2) for information about Lyrx.

Note that the styling library is currently not directly related to the [Geostyler projects](https://github.com/geostyler), but its logic might in the future be migrated to TypeScript to be able to function as a Geostyler project.

## Local build and deploy
Be sure to clone the repository with the ```--recursive``` option, to also obtain the [bridge-style](https://github.com/camptocamp/bridge-style) as a submodule. If you have already cloned the repository without this option, do a ```git submodule update --remote``` to download the submodule.
```
docker build -t lyrx2sld .
docker run --rm -d --name lyrx2sld -p 80:80 lyrx2sld
```

### Alternative: using image from dockerhub
```
docker run --rm -d --name lyrx2sld -p 80:80 camptocamp/lyrx2sld:latest
```

### Usage
lyrx data should be sent as a file to http://localhost/v1/lyrx2sld/ through a POST request. The converted SLD styling is sent back in the response content (content type: application/x-zip-compressed). Example using `curl`:
```
curl --location -d @/path/to/input.lyrx -H 'Content-Type: application/json' -o /path/to/output.zip "http://localhost/v1/lyrx2sld/"
```

Optional request parameter: `replaceesri` to replace ESRI font markers with standard symbols, to be set to `true` or `false` (default):
```
curl --location -d @/path/to/input.lyrx -H 'Content-Type: application/json' -o /path/to/output.zip  "http://localhost/v1/lyrx2sld/?replaceesri=true"
```
Warnings and errors from bridge-style are written to the logs - to view them:
```
docker logs lyrx2sld
```

If the conversion fails, the response contains a JSON object (content type: application/json) with the warnings and errors that occured.

## Docker composition
In order to test the resulting SLD in GeoServer with postgis layers, this repo also contains a docker-compose file with the following services:
 * postgres database (port 5342)
 * GeoServer(port 8080)
 * lyrx2sld (port 80)

Requirements: `docker-compose`, `make`, `curl`, `psql`

The docker-composition is managed through `make` targets. First, copy the template configuration file with `cp config.mk.tmpl config.mk` and edit the variables in `config.mk` were necessary. Start the composition and initialize GeoServer and the DB with
```
make serve
```

The GeoServer GUI will be available at http://localhost:8080/geoserver/ (credential admin / geoserver).

With the `convert` target you can convert a symbology and upload it to GeoServer. First prepare a folder with the lyrx style file and a SQL script with the layer data and set the variables `BASE_PATH`, `SQL_SCRIPT` and `LYRX_FILE` in `config.mk`. Then run
```
make convert
```

The SLD file will be saved in the same folder and sent to GeoServer. In the GeoServer GUI, you'll then need to publish the layer and to link it to the new style. The style will be named `Defaut Styler`.

Further `make` targets are:
- `update` To convert again the style and update the newly created style in GeoServer.
- `clean` To delete the newly created style from GeoServer (works only if no layer use this style).
- `clean-all` To delete the DB and the GeoServer workspace.
- `stop` To stop the composition.

To get a list of all targets and their description run
```
make help
```

If you require ESRI fonts for your styles, they need to be installed on your system and the variable `ESRI_FONT_PATH` in the `.env` file has to point to the correct path.
