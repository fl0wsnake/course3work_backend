import unittest
import backend
from backend import db
from backend.auth.models import User


class AuthTestCase(unittest.TestCase):
    def setUp(self):
        backend.testing = True
        self.app = backend.app.test_client()
        user = User(email="manick@sosi.huy", role="user")
        db.session.query(User).delete()
        db.session.commit()
        db.session.add(user)
        user.set_password("loh")
        db.session.commit()

    def test_auth_ok(self):
        r = self.app.post('/login', data='{"email":"manick@sosi.huy","password":"loh"}', headers={
                          'Content-Type': 'application/json'})
        assert b"access_token" in r.data

    def test_auth_fail(self):
        r = self.app.post('/login', data='{"email":"manick@sosi.huy","password":"lol"}', headers={
                          'Content-Type': 'application/json'})
        assert b"Failed to" in r.data


if __name__ == '__main__':
    unittest.main()
