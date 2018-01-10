from flask import Blueprint, request, jsonify, abort, Response
from sqlalchemy import and_
from flask_jwt_extended import get_jwt_claims
from backend.service.models import Business, Service, Performer, performer_service, Appointment, Image
from backend import db, app
from backend.utils.decorators import login_required, json_required, business_required
from backend.utils.schedule import calc_vacant_hours, get_schedule
from datetime import datetime, timedelta
from dateutil.parser import parse
from cerberus import Validator
from pytz import utc


REGEX_PHONE = '^\+([0-9]){7,15}$'
REGEX_EMAIL = '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
businesses = Blueprint('businesses', __name__)
business_required_fields = [
    'name',
    'phone'
]
business_possible_fields = [
    'address',
    'id'
]
test = Blueprint('test', __name__)


@test.route('/user-protected', methods=['GET'])
@login_required(roles=['user', 'admin'])
def user_protected():
    role = get_jwt_claims()['role']
    return jsonify({'role': role}), 200


@test.route('/admin-protected', methods=['GET'])
@login_required(roles=['admin'])
def admin_protected():
    return jsonify({'role': get_jwt_claims()['role']}), 200


def add(obj, data):
    for key, val in data.iteritems():
        setattr(obj, key, val)
    db.session.add(obj)
    db.session.commit()
    return jsonify({"msg": "Mr Bee flies around"}), 200


def get(obj):
    if not obj:
        return jsonify({"msg": "{0} doesn't exist".format(type(obj).__name__)}), 404
    return jsonify(obj.to_obj()), 200


def update(obj, data):
    if not obj:
        return jsonify({"msg": "{0} doesn't exist".format(type(obj).__name__)}), 404
    for key, val in data.iteritems():
        if val:
            setattr(obj, key, val)
    db.session.commit()
    return jsonify({"msg": "Mr Bee flies around"}), 200


def delete(obj):
    if not obj:
        return jsonify({"msg": "{0} doesn't exist".format(type(obj).__name__)}), 404
    db.session.delete(obj)
    db.session.commit()
    return jsonify({"msg": "Mr Bee flies around"}), 200


@businesses.route('/business/all', methods=['GET'])
@login_required(roles=['business','user'])
def get_businesses():
    return jsonify([x.to_obj() for x in db.session.query(Business).all()]), 200

@businesses.route('/business', methods=['POST'])
@login_required(roles=['business'])
@json_required
def create_business():
    v = Validator(purge_unknown=True)
    schema = {
        'name': {
            'type': 'string',
            'required': True
        },
        'phone': {
            'type': 'string',
            'required': True
            # 'regex': REGEX_PHONE
        },
        'address': {
            'type': 'string'
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    business = db.session.query(Business).filter(
        Business.name == req_data['name']).first()
    if business:
        return jsonify({"msg": "Business already exists"}), 400
    business = Business(user_id=get_jwt_claims()['id'])
    return add(business, req_data)


@businesses.route('/business', methods=['GET'])
@login_required(roles=['business'])
def get_business():
    return get(Business.get(user_id=get_jwt_claims()['id']))


@businesses.route('/business', methods=['PUT'])  # Check data
@login_required(roles=['business'])
@json_required
def update_business():
    v = Validator(purge_unknown=True)
    schema = {
        'name': {
            'type': 'string'
        },
        'phone': {
            'type': 'string'
            # 'regex': REGEX_PHONE
        },
        'address': {
            'type': 'string'
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    return update(Business.get(get_jwt_claims()['id']), req_data)


@businesses.route('/business', methods=['DELETE'])
@login_required(roles=['business'])
def delete_business():
    return delete(Business.get(get_jwt_claims()['id']))


services = Blueprint('services', __name__)
service_required_fields = [
    'name',
    'price',
    'description'
]
service_possible_fields = [
    'duration',
    'performers',
    'id'
]

@services.route('/service', methods=['GET'])
@login_required(roles=['business','user'])
def get_services():
    return jsonify([x.to_obj() for x in db.session.query(Service).all()]), 200

@services.route('/service', methods=['POST'])
@login_required(roles=['business'])
@json_required
def create_service():
    v = Validator(purge_unknown=True)
    schema = {
        'name': {
            'type': 'string',
            'required': True
        },
        'price': {
            'coerce': float,
            'required': True
        },
        'description': {
            'type': 'string',
            'required': True
        },
        'duration': {
            'required': True,
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'performers': {
            'type': 'list'
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    service = db.session.query(Service).filter(
        Service.name == req_data['name']).first()
    if service:
        return jsonify({"msg": "Service already exists"}), 400
    service = Service(business_id=Business.get(get_jwt_claims()['id']).id)
    msg = add(service, {key: req_data[key]
                        for key in req_data if key != 'performers'})
    try:
        if 'performers' in req_data.keys() and len(req_data['performers']) > 0:
            db.session.execute(performer_service.insert(), [
                {'performer_id': x, 'service_id': service.id} for x in req_data['performers']
            ])
            db.session.commit()
    except:
        db.session.rollback()
        return jsonify({"msg": "Probably performers parameter is invalid"}), 400
    return msg


@services.route('/service/<curr_id>', methods=['GET'])
@business_required(model=Service)
def get_service(curr_id):
    return get(Service.get(curr_id))


@services.route('/service/<curr_id>', methods=['PUT'])
@json_required
@business_required(model=Service)
def update_service(curr_id):
    v = Validator(purge_unknown=True)
    schema = {
        'name': {
            'type': 'string'
        },
        'price': {
            'type': 'float'
        },
        'description': {
            'type': 'string'
        },
        'duration': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute),
        },
        'performers': {
            'type': 'list'
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    service = Service.get(curr_id)
    if not service:
        return jsonify({"msg": "{0} doesn't exist".format(type(service).__name__)}), 400
    if 'performers' in req_data.keys():
        old_performers = set(map(lambda x: x.id, service.performers))
        new_performers = set(req_data['performers'])
        to_remove = old_performers.difference(new_performers)
        to_add = new_performers.difference(old_performers)
        try:
            if len(to_remove):
                db.session.execute(performer_service.delete()
                                   .where(and_(performer_service.c.service_id == curr_id, performer_service.c.performer_id.in_(to_remove))))
            if len(to_add):
                db.session.execute(performer_service.insert(), [
                    {'performer_id': x, 'service_id': curr_id} for x in to_add
                ])
        except:
            db.session.rollback()
            return jsonify({"msg": "Probably performers parameter is invalid"}), 400
    return update(service, {key: req_data[key] for key in req_data if key != 'performers'})


@services.route('/service/<curr_id>', methods=['DELETE'])
@business_required(model=Service)
def delete_service(curr_id):
    return delete(Service.get(curr_id))


performers = Blueprint('performers', __name__)
performer_required_fields = [
    'name',
    'phone',
    'description'
]
performer_possible_fields = [
    'services',
    'id',
    'photo'
]


@performers.route('/performer', methods=['POST'])
@json_required
@login_required(roles=['business'])
def create_performer():
    v = Validator(purge_unknown=True)
    schema = {
        'name': {
            'type': 'string',
            'required': True
        },
        'phone': {
            'type': 'string',
            'required': True
            # 'regex' : REGEX_PHONE
        },
        'description': {
            'type': 'string',
            'required': True
        },
        'photo': {
        },
        'services': {
            'type': 'list'
        },
        'work_beg': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'work_end': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'lunch_beg': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'lunch_end': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'non_working_days': {
            'type': 'list',
            'default': []
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    performer = db.session.query(Performer).filter(
        Performer.name == req_data['name']).first()
    if performer:
        return jsonify({"msg": "Performer already exists"}), 400
    performer = Performer(business_id=Business.get(
        get_jwt_claims()['id']).id)

    if ('photo' in req_data.keys()) and req_data['photo']:
        photo = Image(data=req_data['photo'])
        db.session.add(photo)
        db.session.commit()
        performer.photo_id = photo.id

    msg = add(performer, {key: req_data[key]
                          for key in req_data if key not in ['services', 'photo']})
    try:
        if ('services' in req_data.keys()) and (len(req_data['services']) > 0):
            db.session.execute(performer_service.insert(), [
                {'performer_id': performer.id, 'service_id': x} for x in req_data['services']
            ])
            db.session.commit()
    except:
        return jsonify({"msg": "Probably services parameter is invalid"}), 400

    return msg


@performers.route('/image/<curr_id>', methods=['GET'])
def get_image(curr_id):
    image = db.session.query(Image).get(curr_id).data
    return Response(image, mimetype="image/jpeg")


@performers.route('/performer/<curr_id>', methods=['GET'])
@business_required(model=Performer)
def get_performer(curr_id):
    return get(Performer.get(curr_id))


@performers.route('/performer/<curr_id>', methods=['PUT'])
@json_required
@business_required(model=Performer)
def update_performer(curr_id):
    v = Validator(purge_unknown=True)
    schema = {
        'name': {
            'type': 'string'
        },
        'phone': {
            'type': 'string'
            # 'regex' : REGEX_PHONE
        },
        'description': {
            'type': 'string'
        },
        'newPhoto': {
        },
        'services': {
            'type': 'list'
        },
        'work_beg': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'work_end': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'lunch_beg': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'lunch_end': {
            'coerce': lambda x: timedelta(hours=parse(x).hour, minutes=parse(x).minute)
        },
        'non_working_days': {
            'type': 'list',
            'default': []
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    performer = Performer.get(curr_id)
    if not performer:
        return jsonify({"msg": "{0} doesn't exist".format(type(performer).__name__)}), 400
    if 'services' in req_data.keys():
        old_services = set(list(map(lambda x: x.id, performer.services)))
        new_services = set(req_data['services'])
        to_remove = old_services.difference(new_services)
        to_add = new_services.difference(old_services)
        try:
            if len(to_remove) > 0:
                db.session.execute(performer_service.delete().where(and_(
                    performer_service.c.performer_id == curr_id, performer_service.c.service_id.in_(to_remove))))
            if len(to_add) > 0:
                db.session.execute(performer_service.insert(), [
                    {'performer_id': curr_id, 'service_id': x} for x in to_add
                ])
        except:
            db.session.rollback()
            return jsonify({"msg": "Probably performers parameter is invalid"}), 400

    if 'photo' in req_data.keys():
        if performer.photo_id:
            Image.query.filter(Image.id == performer.photo_id).delete()

        if req_data['photo']:
            photo = Image(data=req_data['photo'])
            db.session.add(photo)
            db.session.commit()
            performer.photo_id = photo.id

    return update(performer, {key: req_data[key]
                              for key in req_data if key not in ['services', 'photo']})


@performers.route('/performer/<curr_id>', methods=['DELETE'])
@business_required(model=Performer)
def delete_performer(curr_id):
    return delete(Performer.get(curr_id))


@performers.route('/performer/<curr_id>/available_time', methods=['GET'])
@login_required(roles=['user', 'business'])
def get_performer_available_time(curr_id):
    v = Validator(purge_unknown=True)
    schema = {
        'service_id': {
            'required': True,
            'coerce': int
        },
        'coordx': {
            'required': True,
            'coerce': float
        },
        'coordy': {
            'required': True,
            'coerce': float
        },
        'date': {
            'required': True,
            'coerce': lambda x: parse(x).date()
        }
    }
    req_data = v.validated(request.args.to_dict(), schema)
    if not req_data:
        abort(400, v.errors)
    return jsonify([[str(x[0]), str(x[1])] for x in calc_vacant_hours(
        perf_id=curr_id,
        serv_id=req_data['service_id'],
        coord=(req_data['coordx'], req_data['coordy']),
        xdate=req_data['date']
    )]), 200


appointments = Blueprint('appointments', __name__)


@appointments.route('/appointment', methods=['GET'])
@login_required(roles=['business'])
def business_schedule_get():
    v = Validator(purge_unknown=True)
    schema = {
        'service_id': {
            'default': None,
            'coerce': lambda x: int(x) if x else x,
            'nullable': True
        },
        'performer_id': {
            'default': None,
            'coerce': lambda x: int(x) if x else x,
            'nullable': True
        },
        'date': {
            'default': None,
            'coerce': lambda x: parse(x) if x else x,
            'nullable': True
        }
    }
    req_data = v.validated(request.args.to_dict(), schema)
    if not req_data:
        abort(400, v.errors)
    business = db.session.query(Business).filter(
        Business.user_id == get_jwt_claims()['id']).first()
    perf_id = req_data['performer_id']
    if perf_id and Performer.get(perf_id).business_id != business.id:
        abort(403)
    serv_id = req_data['service_id']
    if serv_id and Service.get(serv_id).business_id != business.id:
        abort(403)
    return jsonify(get_schedule(business_id=business.id, kwargs=req_data)), 200


@appointments.route('/appointment', methods=['POST'])
@login_required(roles=['user', 'business'])
@json_required
def create_appointment():
    v = Validator(purge_unknown=True)
    schema = {
        'service_id': {
            'coerce': int,
            'required': True
        },
        'performer_id': {
            'coerce': int,
            'required': True
        },
        'date': {
            'coerce': lambda x: parse(x).isoformat(),
            'required': True
        },
        'user_id': {
            'coerce': lambda x: int(x) if x else None,
            'default': None,
            'nullable': True
        },
        'notes': {
            'type': 'string'
        },
        'coordx': {
            'type': 'float'
        },
        'coordy': {
            'type': 'float'
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    user_id = get_jwt_claims()['id']
    if get_jwt_claims()['role'] == 'business':
        business = db.session.query(Business).filter(
            Business.user_id == user_id).first()
        if business.id != Performer.get(req_data['performer_id']).business_id:
            abort(403)
        if business.id != Service.get(req_data['service_id']).business_id:
            abort(403)
        user_id = req_data['user_id']
    appointment = Appointment(user_id=user_id, is_confirmed=False)
    return add(appointment, {key: req_data[key]
                             for key in req_data if key != 'user_id'})


@appointments.route('/appointment/<curr_id>', methods=['GET'])
@login_required(roles=['user', 'business'])
def get_appointment(curr_id):
    user_id = get_jwt_claims()['id']
    appointment = Appointment.get(curr_id)
    if not appointment:
        abort(404)
    if get_jwt_claims()['role'] == 'user':
        if appointment.user.id != user_id:
            abort(403)
    else:
        if appointment.service.business.id != db.session.query(Business).filter(Business.user_id == user_id).first().id:
            abort(403)
    return get(appointment)


@appointments.route('/appointment/<curr_id>', methods=['PUT'])
@login_required(roles=['user', 'business'])
@json_required
def update_appointment(curr_id):
    v = Validator(purge_unknown=True)
    schema = {
        'service_id': {
            'coerce': int,
        },
        'performer_id': {
            'coerce': int,
        },
        'date': {
            'coerce': lambda x: parse(x).isoformat(),
        },
        'notes': {
            'type': 'string'
        },
        'coordx': {
            'type': 'float'
        },
        'coordy': {
            'type': 'float'
        }
    }
    req_data = v.validated(request.get_json(), schema)
    if not req_data:
        abort(400, v.errors)
    user_id = get_jwt_claims()['id']
    appointment = Appointment.get(curr_id)
    if not appointment:
        abort(404)
    if get_jwt_claims()['role'] == 'user':
        if appointment.user.id != user_id:
            abort(403)
    else:
        business = appointment.service.business
        if business.id != db.session.query(Business).filter(Business.user_id == user_id).first().id:
            abort(403)
        if 'performer_id' in req_data.keys():
            if business.id != Performer.get(req_data['performer_id']).business_id:
                abort(403)
        if 'service_id' in req_data.keys():
            if business.id != Service.get(req_data['service_id']).business_id:
                abort(403)
    return update(appointment, req_data)


@appointments.route('/appointment/<curr_id>', methods=['DELETE'])
@login_required(roles=['user', 'business'])
def delete_appoinment(curr_id):
    user_id = get_jwt_claims()['id']
    appointment = Appointment.get(curr_id)
    if not appointment:
        abort(404)
    if get_jwt_claims()['role'] == 'user':
        if appointment.user.id != user_id:
            abort(403)
    else:
        if appointment.service.business.id != db.session.query(Business).filter(Business.user_id == user_id).first().id:
            abort(403)
    return delete(appointment)
