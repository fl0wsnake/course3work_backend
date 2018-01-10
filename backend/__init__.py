from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
import datetime

import os

app = Flask(__name__)

CORS(app)

app.config['JWT_SECRET_KEY'] = 'secret_sugar'

app.config['JWT_ACCESS_TOKEN_EXPIRES'] = datetime.timedelta(hours=24)


jwt = JWTManager(app)

app.config['SQLALCHEMY_DATABASE_URI'] = os.environ['DB_CONNECTION']
db = SQLAlchemy(app)

from backend.service.routes import test, businesses, services, performers, appointments
from backend.mocks.routes import mocks
from backend.auth.routes import auths

app.register_blueprint(test)
app.register_blueprint(businesses)
app.register_blueprint(mocks)
app.register_blueprint(auths)
app.register_blueprint(services)
app.register_blueprint(performers)
app.register_blueprint(appointments)


import backend.auth.jwt

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
