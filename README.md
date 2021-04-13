# lyrx2sld
REST service for the conversion of ArcGIS Pro styling (format .lyrx) to GeoServer (format .sld). The service encapsulates the [bridge-style](https://github.com/camptocamp/bridge-style) Python libary and runs in Docker

## Local build and deploy
```
docker build -t lyrx2sld .
docker run -p 80:80 lyrx2sld
```
lyrx data should then be sent as JSON to http://localhost/lyrx2sld/ through a POST request. The converted sld styling is sent back in the response content
