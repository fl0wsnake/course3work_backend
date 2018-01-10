from backend import db
import hashlib


def hash(password):
    return hashlib.sha512(password + "secret_salt")


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(256), nullable=True)
    role = db.Column(db.String(80), nullable=False)
    appointments = db.relationship('Appointment', back_populates='user')

    def set_password(self, password):
        self.password = hash(password).hexdigest()

    def check_password(self, password):
        return self.password == hash(password).hexdigest()

    @staticmethod
    def get(user_id):
        return db.session.query(User).get(user_id)
