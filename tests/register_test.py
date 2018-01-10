import unittest
import backend
import json
from collections import namedtuple
from backend.auth.models import User
from backend import db


class RegisterTestCase(unittest.TestCase):
    def setUp(self):
        backend.testing = True
        self.app = backend.app.test_client()
        db.session.query(User).delete()
        db.session.commit()

    def test_reg(self):
        rreg = self.app.post(
            '/register', data='{"email":"biba@s.padlivoy","password":"kek","role":"user"}', headers={'Content-Type': 'application/json'})
        rlog = self.app.post(
            '/login', data='{"email":"biba@s.padlivoy","password":"kek"}', headers={'Content-Type': 'application/json'})
        assert (b"Mr Bee" in rreg.data) and (b"access_token" in rlog.data)

    def test_prot_route_success(self):
        self.app.post('/register', data='{"email":"very@deep.throat","password":"pipka","role":"user"}', headers={
                      'Content-Type': 'application/json'})
        data = self.app.post('/login', data='{"email":"very@deep.throat","password":"pipka"}', headers={
                             'Content-Type': 'application/json'}).data
        x = json.loads(data, object_hook=lambda d: namedtuple(
            'X', d.keys())(*d.values()))
        token = x.access_token
        r = self.app.get(
            '/user-protected', headers={'Authorization': ('Bearer {0}'.format(token))})
        assert b"user" in r.data

    def test_prot_route_failure(self):
        self.app.post('/register', data='{"email":"less@deep.throat","password":"pipka","role":"user"}', headers={
                      'Content-Type': 'application/json'})
        data = self.app.post('/login', data='{"email":"less@deep.throat","password":"pipka"}', headers={
                             'Content-Type': 'application/json'}).data
        x = json.loads(data, object_hook=lambda d: namedtuple(
            'X', d.keys())(*d.values()))
        token = x.access_token
        r = self.app.get(
            '/admin-protected', headers={'Authorization': ('Bearer {0}'.format(token))})
        assert b"denied" in r.data


if __name__ == '__main__':
    unittest.main()
