# lyrx2sld
lyrx2sld is a REST service for the conversion of ArcGIS Pro styling (format .lyrx) to GeoServer (format .sld, encapsulated in a .zip archive together with legend images, if any). The service encapsulates a styling library (see below for details) and runs in Docker.

#### Styling library
The service encapsulates the [bridge-style](https://github.com/camptocamp/bridge-style) library, which is written in Python and originally designed to be able to be used in plugins for ArcGis Desktop and QGIS Desktop, with the goal of allowing users to publish layer symbology to GeoServer.
For that purpose, this library uses the [Geostyler](https://github.com/geostyler) JSON representation as a common internal representation format. 
To meet the goals of lyrx2sld, this library was enhanced regarding its capabilities of interpreting the Lyrx format.
See the [Cartographic Information Model documentation](https://github.com/Esri/cim-spec/tree/master/docs/v2) for information about Lyrx.

Note that the styling library is currently not directly related to the [Geostyler projects](https://github.com/geostyler), but its logic might in the future be migrated to TypeScript to be able to function as a Geostyler project.

#### Local build and deploy
Be sure to clone the repository with the ```--recursive``` option, to also obtain the [bridge-style](https://github.com/camptocamp/bridge-style) as a submodule. If you have already cloned the repository without this option, do a ```git submodule update --remote``` to download the submodule.
```
docker build -t lyrx2sld .
docker run --rm -d --name lyrx2sld -p 80:80 lyrx2sld
```

#### Alternative: using image from dockerhub
```
docker run --rm -d --name lyrx2sld -p 80:80 camptocamp/lyrx2sld:latest
```

#### Usage
lyrx data should be sent as JSON to http://localhost/v1/lyrx2sld/ through a POST request. The converted sld styling is sent back in the response content (content type: application/x-zip-compressed). Example using `curl`:
```
curl --location -d @/path/to/input.json http://localhost/v1/lyrx2sld/ -o /path/to/output.zip
```

Optional request parameter: `replaceesri` to replace ESRI font markers with standard symbols, to be set to `true` or `false` (default):
```
curl --location -d @/path/to/input.json "http://localhost/v1/lyrx2sld/?replaceesri=true" -o /path/to/output.zip
```
Warnings and errors from bridge-style are written to the logs - to view them:
```
docker logs lyrx2sld
```

If the conversion fails, the response contains a JSON object (content type: application/json) with the warnings and errors that occured.
