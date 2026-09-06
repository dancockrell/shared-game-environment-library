# SPDX-License-Identifier: GPL-3.0-or-later
import json
import struct
import unittest

import glb_geometry as audit


class GeometryAuditTests(unittest.TestCase):
    def setUp(self):
        self.triangle = [(0, 0, 0), (1, 0, 0), (0, 1, 0)]
        self.binary = struct.pack("<9f3H", *sum((list(p) for p in self.triangle), []), 0, 1, 2)
        self.doc = {"buffers": [{"byteLength": len(self.binary)}],
                    "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": 36},
                                    {"buffer": 0, "byteOffset": 36, "byteLength": 6}],
                    "accessors": [{"bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC3"},
                                  {"bufferView": 1, "componentType": 5123, "count": 3, "type": "SCALAR"}],
                    "meshes": [{"primitives": [{"attributes": {"POSITION": 0}, "indices": 1}]}]}

    def glb(self):
        payload = json.dumps(self.doc).encode()
        payload += b" " * (-len(payload) % 4)
        binary = self.binary + b"\0" * (-len(self.binary) % 4)
        return (struct.pack("<5I", 0x46546C67, 2, 28 + len(payload) + len(binary), len(payload), 0x4E4F534A)
                + payload + struct.pack("<2I", len(binary), 0x004E4942) + binary)

    def test_roundtrip_and_cyclic_order(self):
        doc, binary = audit.read(self.glb())
        result = audit.compare(doc, binary, [self.triangle[1:] + self.triangle[:1]])
        self.assertEqual(result["triangles"], 1)

    def test_winding_and_multiplicity_rejected(self):
        for triangles in ([list(reversed(self.triangle))], [self.triangle, self.triangle]):
            with self.assertRaises(ValueError):
                audit.compare(self.doc, self.binary, triangles)

    def test_same_bounds_wrong_geometry_rejected(self):
        # Same x/y bounds and triangle count, but a different triangle.
        wrong = [(0, 0, 0), (1, 1, 0), (0, 1, 0)]
        with self.assertRaises(ValueError):
            audit.compare(self.doc, self.binary, [wrong])

    def test_invalid_binary_and_external_buffer(self):
        with self.assertRaises(ValueError):
            audit.read(self.glb()[:-1])
        self.doc["buffers"][0]["uri"] = "not-allowed.bin"
        with self.assertRaises(ValueError):
            audit.read(self.glb())

    def test_accessor_crossing_view_rejected(self):
        self.doc["bufferViews"][0]["byteLength"] = 24
        with self.assertRaises(ValueError):
            audit.compare(self.doc, self.binary, [self.triangle])

    def test_nonfinite_and_bad_index_rejected(self):
        for binary in (struct.pack("<f", float("nan")) + self.binary[4:],
                       self.binary[:-2] + struct.pack("<H", 3)):
            with self.assertRaises(ValueError):
                audit.compare(self.doc, binary, [self.triangle])

    def test_interleaved_vertex_buffer(self):
        self.binary = b"".join(struct.pack("<4f", *p, 123) for p in self.triangle) + self.binary[36:]
        self.doc["bufferViews"][0].update(byteLength=48, byteStride=16)
        self.doc["bufferViews"][1]["byteOffset"] = 48
        self.assertEqual(audit.compare(self.doc, self.binary, [self.triangle])["triangles"], 1)


if __name__ == "__main__":
    unittest.main()
