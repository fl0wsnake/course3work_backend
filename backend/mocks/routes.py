from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_claims


mocks = Blueprint(name='mocks', url_prefix='/mocks', import_name=__name__)


@mocks.route('/business', methods=['GET'])
def get_business():
    return jsonify({
        "id": "1",
        "name": "Mock business",
        "address": "Some address",
        "phone": "+132283228"
    }), 200


@mocks.route('/business/empty', methods=['GET'])
def empty_business():
    return '', 404
