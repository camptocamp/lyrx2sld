# -*- coding: utf-8 -*-

from unittest import TestCase

import json
import io
import os
import zipfile
import requests
from xml.etree import ElementTree
import ast

APP_ENDPOINT = "http://localhost/v1/lyrx2sld"


class SLDParser():

    def __init__(self, content):
        self.xml = content
        self.root = ElementTree.fromstring(self.xml)
        self.data = {}
        self.parse()

    def strip_tag(self, tag):
        try:
            return tag.split("}")[1]
        except IndexError:
            return tag

    def get_subelements(self, element):
        data = {}
        for subelement in element:
            tag = self.strip_tag(subelement.tag)
            attrib = subelement.attrib
            text = (subelement.text or "").strip()
            if attrib:
                data[tag] = dict()
                for item in attrib:
                    data[tag][self.strip_tag(item)] = attrib[item]
            elif text:
                try:
                    data[tag] = ast.literal_eval(text)
                except (SyntaxError, ValueError):
                    data[tag] = text
            else:
                data[tag] = self.get_subelements(subelement)
        return data

    def parse(self):
        for element in self.root:
            tag = self.strip_tag(element.tag)
            self.data[tag] = self.get_subelements(element)

    def as_dict(self):
        return self.data


def get_style_from_zip_response(content):
    with zipfile.ZipFile(io.BytesIO(content)) as z:
        with z.open('style.sld') as f:
            sld = f.read().decode('utf-8')
            data = SLDParser(sld).as_dict()
            return data

def input_test_file(filename):
    return os.path.join(os.path.dirname(__file__), "data", filename)

def expected_test_file(filename):
    return os.path.join(os.path.dirname(__file__), "expected", filename)

class TestService(TestCase):

    def test_point_symbology(self):
        with open(input_test_file("input.lyrx")) as f:
            obj = json.load(f)
        response = requests.post(APP_ENDPOINT, json=obj, timeout=30)
        self.assertEqual(response.status_code, 200)
        data = get_style_from_zip_response(response.content)
        point_symbolizer = data['NamedLayer']['UserStyle']['FeatureTypeStyle']['Rule']['PointSymbolizer']
        self.assertEqual(data['NamedLayer']['Name'], 'Bauinventarobjekte')
        self.assertEqual(point_symbolizer['Graphic']['Mark']['WellKnownName'], 'ttf://ESRI Default Marker#0x21')

    def test_point_symbology_replace_esri(self):
        with open(input_test_file("input.lyrx")) as f:
            obj = json.load(f)
        response = requests.post(f"{APP_ENDPOINT}?replaceesri=true", json=obj, timeout=30)
        self.assertEqual(response.status_code, 200)
        data = get_style_from_zip_response(response.content)
        point_symbolizer = data['NamedLayer']['UserStyle']['FeatureTypeStyle']['Rule']['PointSymbolizer']
        self.assertEqual(data['NamedLayer']['Name'], 'Bauinventarobjekte')
        self.assertEqual(point_symbolizer['Graphic']['Mark']['WellKnownName'], 'circle')

    def test_icon_conversion(self):
        with open(input_test_file("withicons.lyrx"), encoding="utf-8") as f:
            obj = json.load(f)
        response = requests.post(APP_ENDPOINT, json=obj, timeout=30)
        self.assertEqual(response.status_code, 200)
        style = get_style_from_zip_response(response.content)
        icon_file = style['NamedLayer']['UserStyle']['FeatureTypeStyle']['Rule']['PointSymbolizer']['Graphic']['ExternalGraphic']['OnlineResource']['href']
        with zipfile.ZipFile(io.BytesIO(response.content)) as z:
            zipped_files = {zipinfo.filename for zipinfo in z.infolist()}
            self.assertEqual({"style.sld", icon_file}, zipped_files)
            with open(expected_test_file("icon.png"), "rb") as f:
                expected = f.read()
            with z.open(icon_file) as f:
                output = f.read()
            self.assertEqual(expected, output)
