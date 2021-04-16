# lyrx2sld
REST service for the conversion of ArcGIS Pro styling (format .lyrx) to GeoServer (format .sld). The service encapsulates the [bridge-style](https://github.com/camptocamp/bridge-style) Python library and runs in Docker

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
lyrx data should be sent as JSON to http://localhost/v1/lyrx2sld/ through a POST request. The converted sld styling is sent back in the response content. Example using `curl`:
```
curl -d @/path/to/input.json http://localhost/v1/lyrx2sld/ -o /path/to/output.sld
```

Optional request parameter: `replaceesri` to replace ESRI font markers with standard symbols, to be set to `true` (default) or `false`:
```
curl -d @/path/to/input.json "http://localhost/v1/lyrx2sld/?replaceesri=false" -o /path/to/output.sld
```
