import unittest
from backend import db
from backend.auth.models import User


class DbTestCase(unittest.TestCase):
    def setUp(self):
        db.session.query(User).delete()
        db.session.commit()

    def test_response(self):
        res = db.engine.execute('select 1+1 as sum')
        row = res.fetchone()
        assert row[0] == 2

    def test_user(self):
        user = User(email="padliva", role="user")
        db.session.add(user)
        users = db.session.query(User).all()
        assert len(users) == 1


if __name__ == '__main__':
    unittest.main()
