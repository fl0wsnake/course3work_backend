from backend import db
from sqlalchemy.types import TIMESTAMP
from sqlalchemy_utils import UUIDType
from datetime import timedelta, datetime
import uuid
import re


class Business(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=True, unique=True)
    phone = db.Column(db.String(80), nullable=True)
    address = db.Column(db.String(256), nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey(
        'user.id',
        onupdate="CASCADE",
        ondelete="CASCADE"
    ), nullable=False)
    services = db.relationship("Service", back_populates='business')
    performers = db.relationship("Performer", back_populates='business')

    def to_obj(self):
        return {
            'id': self.id,
            'name': self.name,
            'address': self.address,
            'phone': self.phone,
            'performers': list(map(lambda x: x.to_obj(), self.performers)),
            'services': list(map(lambda x: x.to_obj(), self.services))
        }

    @staticmethod
    def get(user_id):
        return db.session.query(Business).filter(Business.user_id == user_id).first()


performer_service = db.Table('performer_service',
                             db.Column('performer_id', db.Integer, db.ForeignKey(
                                 'performer.id',
                                 onupdate="CASCADE",
                                 ondelete="CASCADE"
                             ), primary_key=True),
                             db.Column('service_id', db.Integer, db.ForeignKey(
                                 'service.id',
                                 onupdate="CASCADE",
                                 ondelete="CASCADE"
                             ), primary_key=True)
                             )


class Performer(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80))
    services = db.relationship('Service', secondary=performer_service,
                               back_populates='performers', lazy='dynamic')
    phone = db.Column(db.String(80), nullable=True)
    photo_id = db.Column(UUIDType(binary=False), db.ForeignKey(
        'image.id',
        onupdate="CASCADE",
        ondelete="SET NULL"
    ), nullable=True)
    description = db.Column(db.String(256))
    business_id = db.Column(db.Integer, db.ForeignKey(
        'business.id',
        onupdate="CASCADE",
        ondelete="CASCADE"
    ), nullable=False)
    work_beg = db.Column(db.Interval, nullable=False, default=timedelta(hours=9))
    work_end = db.Column(db.Interval, nullable=False, default=timedelta(hours=18))
    lunch_beg = db.Column(db.Interval, nullable=False, default=timedelta(hours=12))
    lunch_end = db.Column(db.Interval, nullable=False, default=timedelta(hours=13))
    non_working_days = db.Column(
        db.ARRAY(db.Integer), nullable=False, default=[])
    business = db.relationship("Business", back_populates='performers')
    appointments = db.relationship('Appointment', back_populates='performer')

    def to_obj(self):
        return {
            'id': self.id,
            'name': self.name,
            'phone': self.phone,
            'photo': self.photo_id,
            'description': self.description,
            'services': list(map(lambda x: x.id, self.services))
        }

    def get_working_hours(self):
        if not self.work_beg:
            return timedelta(hours=9), timedelta(hours=18)
        return self.work_beg, self.work_end

    def get_lunch_hours(self):
        if not self.lunch_beg:
            return timedelta(hours=12), timedelta(hours=13)
        return self.lunch_beg, self.lunch_end

    @staticmethod
    def get(performer_id):
        return db.session.query(Performer).get(performer_id)


class Service(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80))
    description = db.Column(db.String(256))
    price = db.Column(db.Float, nullable=True)
    duration = db.Column(db.Interval, nullable=True)
    performers = db.relationship('Performer', secondary=performer_service,
                                 back_populates='services', lazy='dynamic')
    business_id = db.Column(db.Integer, db.ForeignKey(
        'business.id',
        onupdate="CASCADE",
        ondelete="CASCADE"
    ), nullable=False)
    business = db.relationship("Business", back_populates='services')
    appointments = db.relationship('Appointment', back_populates='service')

    def to_obj(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'price': self.price,
            'duration': str(self.duration),
            'performers': list(map(lambda x: x.id, self.performers))
        }

    @staticmethod
    def get(service_id):
        return db.session.query(Service).get(service_id)


class Appointment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    service_id = db.Column(db.Integer, db.ForeignKey(
        'service.id',
        onupdate="CASCADE",
        ondelete="CASCADE"
    ), nullable=False)
    performer_id = db.Column(db.Integer, db.ForeignKey(
        'performer.id',
        onupdate="CASCADE",
        ondelete="CASCADE"
    ), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey(
        'user.id',
        onupdate="CASCADE",
        ondelete="CASCADE"
    ), nullable=True)
    is_confirmed = db.Column(db.Boolean, nullable=False)
    date = db.Column(TIMESTAMP(timezone=True), default=datetime(
        1, 1, 1, 1, 0, 0), nullable=False)
    notes = db.Column(db.String(256))

    coordx = db.Column(db.Float)
    coordy = db.Column(db.Float)

    performer = db.relationship('Performer', back_populates='appointments')
    service = db.relationship('Service', back_populates='appointments')
    user = db.relationship('User', back_populates='appointments')

    @staticmethod
    def get(appointment_id):
        return db.session.query(Appointment).get(appointment_id)

    def to_obj(self):
        return {
            'id': self.id,
            'user_id' : self.user_id,
            'performer_id': self.performer_id,
            'service_id': self.service_id,
            'is_confirmed': self.is_confirmed,
            'date': self.date.isoformat(),
            'notes': self.notes
        }


class Image(db.Model):
    def __init__(self, data):
        self.id = uuid.uuid1()
        self.data = re.sub('^data:image/.+;base64,', '', data).decode('base64')
    id = db.Column(UUIDType(binary=False), primary_key=True)
    data = db.Column(db.LargeBinary, nullable=False)
