from typing import List

import traceback

from pydantic import BaseModel
from fastapi import FastAPI, status, Response
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse

import logging

from bridgestyle.arcgis import togeostyler
from bridgestyle.sld import fromgeostyler


class Lyrx(BaseModel):
    type: str
    version: str
    build: int
    layers: List[str]
    layerDefinitions: List[dict]
    binaryReferences: List[dict]
    elevationSurfaces: List[dict]
    rGBColorProfile: str
    cMYKColorProfile: str


app = FastAPI()

LOG = logging.getLogger("app")


@app.post("/v1/lyrx2sld/")
async def lyrx_to_sld(lyrx: Lyrx, replaceesri: bool = True):

    options = {'tolowercase': True, 'replaceesri': replaceesri}
    warnings = []

    try:
        geostyler, _, w = togeostyler.convert(lyrx.dict(), options)
        if w:
            warnings.extend(w)
        converted, w = fromgeostyler.convert(geostyler, options)
        if w:
            warnings.extend(w)
        for warning in warnings:
            LOG.warning(warning)
        return Response(content=converted, media_type="application/xml")


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
