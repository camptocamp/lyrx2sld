# lyrx2sld
lyrx2sld is a REST service for the conversion of ArcGIS Pro styling (format .lyrx) to GeoServer (format .sld). The service encapsulates the [bridge-style](https://github.com/camptocamp/bridge-style) Python library and runs in Docker.

#### Local build and deploy
```
docker build -t lyrx2sld .
docker run --rm -d --name lyrx2sld -p 80:80 lyrx2sld
```

#### Alternative: using image from dockerhub
```
docker run --rm -d --name lyrx2sld -p 80:80 vuilleumierc/lyrx2sld:latest
```

#### Usage
lyrx data should be sent as JSON to http://localhost/v1/lyrx2sld/ through a POST request. The converted sld styling is sent back in the response content (content type: application/xml). Example using `curl`:
```
curl -d @/path/to/input.json http://localhost/v1/lyrx2sld/ -o /path/to/output.sld
```

Optional request parameter: `replaceesri` to replace ESRI font markers with standard symbols, to be set to `true` or `false` (default):
```
curl -d @/path/to/input.json "http://localhost/v1/lyrx2sld/?replaceesri=true" -o /path/to/output.sld
```
Warnings and errors from bridge-style are written to the logs - to view them:
```
docker logs lyrx2sld
```

If the conversion fails, the response contains a JSON object (content type: application/json) with the warnings and errors that occured.
