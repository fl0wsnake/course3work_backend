from flask import Blueprint, request, jsonify, abort
from flask_jwt_extended import create_access_token
from backend import db
from models import User
from backend.utils.decorators import json_required
from cerberus import Validator
auths = Blueprint('auths', __name__)

REGEX_EMAIL = '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'


@auths.route('/register', methods=['POST'])
@json_required
def register():
    v = Validator(purge_unknown=True)
    schema = {
        'email': {
            'type': 'string',
            'required': True
            # 'regex': REGEX_EMAIL
        },
        'password': {
            'required': True,
            'type': 'string'
        },
        'role': {
            'type': 'string',
            'required': True,
            'allowed': [
                'user',
                'business'
            ]
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    user = db.session.query(User).filter(
        User.email == req_data['email']).first()
    if user:
        return jsonify({"msg": "User already exists"}), 422
    user = User(email=req_data['email'], role=req_data['role'])
    db.session.add(user)
    user.set_password(req_data['password'])
    db.session.commit()
    return jsonify({"msg": "Mr Bee flies around"}), 200


@auths.route('/login', methods=['POST'])
@json_required
def login():
    v = Validator(purge_unknown=True)
    schema = {
        'email': {
            'type': 'string',
            'required': True
            # 'regex': REGEX_EMAIL
        },
        'password': {
            'required': True,
            'type': 'string'
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    user = User.query.filter(User.email == req_data['email']).first()
    if not (user and user.check_password(req_data['password'])):
        return jsonify({"msg": "Failed to log in"}), 401
    access_token = create_access_token(identity=user.id)
    return jsonify(access_token=access_token), 200
