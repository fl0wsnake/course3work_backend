from functools import partial, wraps
from flask import jsonify, request
from flask_jwt_extended import get_jwt_claims, jwt_required
from backend import jwt, db


class FailType():
    only_field = None


fail = FailType()


def json_required(f=None):
    if f is None:
        return partial(json_required)

    @wraps(f)
    def decorated_function(*args, **kwargs):
        try:
            if request.json is None:
                return jsonify({"msg": "Missing JSON in request"}), 400
        except:
            return jsonify({"msg": "Invalid JSON request"}), 400
        return f(*args, **kwargs)

    return decorated_function


def login_required(f=None, roles=[]):
    if f is None:
        return partial(login_required, roles=roles)

    @wraps(f)
    @jwt_required
    def decorated_function(*args, **kwargs):
        if get_jwt_claims()['role'] not in roles:
            return jsonify({"msg": "Access denied"}), 403
        return f(*args, **kwargs)
    return decorated_function


def business_required(f=None, model=None):
    if f is None:
        return partial(business_required, model=model)

    @wraps(f)
    @login_required(roles=['business'])
    def decorated_function(*args, **kwargs):
        if get_jwt_claims()['id'] != model.get(kwargs['curr_id']).business.user_id:
            return jsonify({"msg": "Access denied"}), 403
        return f(*args, **kwargs)
    return decorated_function
