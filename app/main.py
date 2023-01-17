import os
import io
import zipfile
from typing import List, Optional

from typing import List, Optional

import traceback
import yaml

from pydantic import BaseModel
from fastapi import FastAPI, status, Response
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse

import logging

from bridgestyle.arcgis import togeostyler
from bridgestyle.sld import fromgeostyler

# For debugging only, the IP must be one IP of your machine.
# import pydevd_pycharm
# pydevd_pycharm.settrace('172.17.0.1', port=5678, stdoutToServer=True, stderrToServer=True)


class Lyrx(BaseModel):
    type: str
    version: str
    build: int
    layers: Optional[List[str]]
    layerDefinitions: List[dict]
    binaryReferences: Optional[List[dict]]
    elevationSurfaces: Optional[List[dict]]
    rGBColorProfile: Optional[str]
    cMYKColorProfile: Optional[str]


app = FastAPI()

LOG = logging.getLogger("app")
with open('config.yaml') as f:
    config = yaml.load(f, Loader=yaml.FullLoader)
    logging.config.dictConfig(config)

@app.post("/v1/lyrx2sld/")
async def lyrx_to_sld(lyrx: Lyrx, replaceesri: bool = False):

    options = {'tolowercase': True, 'replaceesri': replaceesri}
    warnings = []

    try:
        geostyler, icons, w = togeostyler.convert(lyrx.dict(), options)
        warnings.extend(w)
        converted, wb = fromgeostyler.convert(geostyler, options)
        warnings.extend(w)

        s = io.BytesIO()
        z = zipfile.ZipFile(s, "w")

        for icon in icons:
            if icon:
                z.write(icon, os.path.basename(icon))
        z.writestr("style.sld", converted)
        z.close()

        for warning in warnings:
            LOG.warning(warning)

        return Response(
            content=s.getvalue(),
            media_type="application/x-zip-compressed",
            headers={
                'Content-Disposition': 'attachment;filename=style.zip'
                }
            )

    except Exception as e:
        errors = traceback.format_exception(None, e, e.__traceback__)
        for error in errors:
            LOG.error(error)
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=jsonable_encoder(
                {
                    'warnings': warnings,
                    'errors': errors
                })
            )
