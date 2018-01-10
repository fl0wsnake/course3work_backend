import unittest
import backend


class IndexTestCase(unittest.TestCase):
    def setUp(self):
        backend.testing = True
        self.app = backend.app.test_client()

    def test_response(self):
        rv = self.app.get('/')
        assert b'Tvoya' in rv.data


if __name__ == '__main__':
    unittest.main()
