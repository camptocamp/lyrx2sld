# -*- coding: utf-8 -*-

from unittest import TestCase

import json
import requests
from xml.etree import ElementTree
import ast


class SLDParser():

    def __init__(self, content):
        self.xml = content
        self.root = ElementTree.fromstring(self.xml)
        self.data = {}
        self.parse()

    def get_subelements(self, element):
        data = {}
        for subelement in element:
            tag = subelement.tag.split("}")[1]
            text = subelement.text.strip()
            if text:
                try:
                    data[tag] = ast.literal_eval(text)
                except:
                    data[tag] = text
            else:
                data[tag] = self.get_subelements(subelement)
        return data

    def parse(self):
        for element in self.root:
            tag = element.tag.split("}")[1]
            self.data[tag] = self.get_subelements(element)

    def as_dict(self):
        return self.data

class TestService(TestCase):

    def test_point_symbology_replace_esri(self):
        with open("./tests/data/bauinventarobjekte/input.lyrx") as f:
            obj = json.load(f)
        response = requests.post("http://localhost/v1/lyrx2sld?replaceesri=true", json=obj, timeout=30)
        data = SLDParser(response.text).as_dict()
        point_symbolizer = data['NamedLayer']['UserStyle']['FeatureTypeStyle']['Rule']['PointSymbolizer']
        self.assertEqual(response.status_code, 200)
        self.assertEqual(data['NamedLayer']['Name'], 'Bauinventarobjekte')
        self.assertEqual(point_symbolizer['Graphic']['Mark']['WellKnownName'], 'circle')