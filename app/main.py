from typing import List

import traceback
import json

from pydantic import BaseModel
from fastapi import FastAPI, HTTPException, status
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

import logging

from bridgestyle.arcgis import togeostyler
from bridgestyle.sld import fromgeostyler

LOG = logging.getLogger(__name__)

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

@app.post("/lyrx2sld/")
async def lyrx_to_sld(lyrx: Lyrx, replaceesri = True):
    
    options = {'tolowercase': True, 'replaceesri': replaceesri}
    warnings = []

    try:
        geostyler, _, w = togeostyler.convert(lyrx.dict(), options)
        if w: warnings.append(w)
        converted, w = fromgeostyler.convert(geostyler, options)
        if w: warnings.append(w)
        success = True
        errors = []
        return {'success': success,
                'sld': converted,
                'warnings': warnings,
                'errors': errors
                }

    except Exception as e:
        converted = ''
        success = False
        errors = traceback.format_exception(None, e, e.__traceback__)
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=jsonable_encoder({'success': success,
                    'sld': converted,
                    'warnings': warnings,
                    'errors': errors})
            )
