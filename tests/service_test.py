import unittest
import backend
import json
from collections import namedtuple
from backend.auth.models import User
from backend.service.models import Business, Service, Performer, Appointment
from backend import db
from datetime import datetime, date, time
from pytz import utc

class ServiceTestCase(unittest.TestCase):
    def setUp(self):
        backend.testing = True
        self.app = backend.app.test_client()

    def create_user_token(self, email, password):
        r = self.app.post('/register', data=json.dumps({
            "email": email,
            "password": password,
            "role": "user"
        }), headers={'Content-Type': 'application/json'})
        data = self.app.post('/login', data=json.dumps({
            "email": email,
            "password": password
        }), headers={'Content-Type': 'application/json'}).data
        x = json.loads(data, object_hook=lambda d: namedtuple(
            'X', d.keys())(*d.values()))
        return x.access_token

    def test_reg_business(self):
        r = self.app.post('/register', data=json.dumps({
            "email": "my@business.mail",
            "password": "pipka",
            "role": "business"
        }), headers={'Content-Type': 'application/json'})
        data = self.app.post('/login', data=json.dumps({
            "email": "my@business.mail",
            "password": "pipka"
        }), headers={'Content-Type': 'application/json'}).data
        x = json.loads(data, object_hook=lambda d: namedtuple(
            'X', d.keys())(*d.values()))
        token = x.access_token
        r = self.app.post('/business', data=json.dumps({
            "name": "Whitepowerordiebutwhy?",
            "address": "Some adress",
            "phone": "+132283228"
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })
        assert b"Bee" in r.data
        return token

    def test_get_business(self):
        token = self.test_reg_business()
        r = self.app.get(
            '/business', headers={'Authorization': ('Bearer {0}'.format(token))})
        assert b"3228" in r.data

    def test_update_business(self):
        token = self.test_reg_business()
        r = self.app.put('/business', data=json.dumps({
            "name": "tolerance"
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })
        r = self.app.get(
            '/business', headers={'Authorization': ('Bearer {0}'.format(token))})
        assert b"tolerance" in r.data

    def test_delete_business(self):
        token = self.test_reg_business()
        t = len(db.session.query(Business).all())
        r = self.app.delete('/business', headers={
            'Authorization': ('Bearer {0}'.format(token))
        })
        t = t - len(db.session.query(Business).all())
        assert t == 1

    def test_reg_service(self):
        token = self.test_reg_business()
        r = self.app. r = self.app.post('/service', data=json.dumps({
            "name": "Rape your mother",
            "price": 1337,
            "duration": '1:00:00',
            'description': 'take giant dildo(cock) and rape your mothers asshole using it',
            'performers': []
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })
        assert b"Bee" in r.data
        return token

    def test_get_service(self):
        token = self.test_reg_service()
        service = db.session.query(Service).first()
        r = self.app.get(
            '/service/{0}'.format(service.id), headers={'Authorization': ('Bearer {0}'.format(token))}
        )
        assert b"dildo" in r.data

    def test_get_business_with_service(self):
        token = self.test_reg_service()
        r = self.app.get(
            '/business', headers={'Authorization': ('Bearer {0}'.format(token))}
        )
        assert b"3228" in r.data

    def test_update_service(self):
        token = self.test_reg_service()
        service = db.session.query(Service).first()
        r = self.app.put('/service/{0}'.format(service.id), data=json.dumps({
            "name": "Clean your mother",
            "price": 1337,
            "duration": '1:00:00',
            'description': 'take giant sponge(with soap) and clean your mothers body using it',
            'performers': []
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })
        service = db.session.query(Service).first()
        r = self.app.get(
            '/service/{0}'.format(service.id), headers={'Authorization': ('Bearer {0}'.format(token))}
        )
        assert b"sponge" in r.data

    def test_delete_service(self):
        token = self.test_reg_service()
        t = len(db.session.query(Service).all())
        service = db.session.query(Service).first()
        r = self.app.delete('/service/{0}'.format(service.id), headers={
            'Authorization': ('Bearer {0}'.format(token))
        })
        t = t - len(db.session.query(Service).all())
        assert t == 1

    def test_reg_performer(self):
        token = self.test_reg_business()

        r = self.app.post('/performer', data=json.dumps({
            'name': "Mother Rapist",
            'phone': "8-800-555-35-35",
            'description': 'Raping lonely mothers professional',
            'services': []
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })
        assert b"Bee" in r.data
        return token

    def test_update_performer(self):
        token = self.test_reg_performer()
        p = db.session.query(Performer).filter(
            Performer.name == "Mother Rapist").first().id
        r = self.app.put('/performer/{}'.format(p), data=json.dumps({
            'name': "Mother Rapist",
            'phone': "8-800-555-35-35",
            'description': 'Raping lonely mothers professional'
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })
        assert b"Bee" in r.data

    def test_get_performer(self):
        token = self.test_reg_performer()
        performer = db.session.query(Performer).first()
        r = self.app.get(
            '/performer/{0}'.format(performer.id), headers={'Authorization': ('Bearer {0}'.format(token))}
        )
        assert b"Rapist" in r.data

    def performer_reg_pattern(self, obj, token):
        return self.app.post('/performer', data=json.dumps(obj), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })

    def service_reg_pattern(self, obj, token):
        return self.app.post('/service', data=json.dumps(obj), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })

    def service_update_pattern(self, obj, serv_id, token):
        return self.app.put('/service/{0}'.format(serv_id), data=json.dumps(obj), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })

    def business_get_patern(self, token):
        r = self.app.get(
            '/business', headers={'Authorization': ('Bearer {0}'.format(token))})
        return r.data

    def test_business_get_with_all_relations(self):
        token = self.test_reg_business()
        performer1 = {"name": "Mother Rapist1",
                      "phone": "8-801-555-35-35",
                      'description': 'Raping lonely mothers professional 1',
                      'services': []}
        performer2 = {"name": "Mother Rapist2",
                      "phone": "8-802-555-35-35",
                      'description': 'Raping lonely mothers professional 2',
                      'services': []}
        performer3 = {"name": "Father Rapist3",
                      "phone": "8-803-555-35-35",
                      'description': 'Raping lonely fathers professional 3',
                      'services': []}
        performer4 = {"name": "Father Rapist4",
                      "phone": "8-804-555-35-35",
                      'description': 'Raping lonely fathers professional 4',
                      'services': []}
        performer5 = {"name": "Mother and Father Rapist5",
                      "phone": "8-805-555-35-35",
                      'description': 'Raping lonely mothers and fathers professional 5',
                      'services': []}

        self.performer_reg_pattern(performer1, token)
        self.performer_reg_pattern(performer2, token)
        self.performer_reg_pattern(performer3, token)
        self.performer_reg_pattern(performer4, token)
        self.performer_reg_pattern(performer5, token)

        p1 = db.session.query(Performer).filter(
            Performer.name == "Mother Rapist1").first().id
        p2 = db.session.query(Performer).filter(
            Performer.name == "Mother Rapist2").first().id
        p3 = db.session.query(Performer).filter(
            Performer.name == "Father Rapist3").first().id
        p4 = db.session.query(Performer).filter(
            Performer.name == "Father Rapist4").first().id
        p5 = db.session.query(Performer).filter(
            Performer.name == "Mother and Father Rapist5").first().id

        service1 = {"name": "Rape your mother",
                    "price": 1337,
                    "duration": '1:00:00',
                    'description': 'take giant dildo(cock) and rape your mothers asshole using it',
                    'performers': [p1]}
        service2 = {"name": "Rape your father",
                    "price": 1488,
                    "duration": '1:00:00',
                    'description': 'take giant dildo(dick) and rape your fathers asshole using it',
                    'performers': [p3, p1]}

        self.service_reg_pattern(service1, token)
        self.service_reg_pattern(service2, token)

        s1 = db.session.query(Service).filter(
            Service.name == "Rape your mother").first().id
        s2 = db.session.query(Service).filter(
            Service.name == "Rape your father").first().id
        r = self.app.get(
            '/service', headers={'Authorization': ('Bearer {0}'.format(token))}
        )
        print(r.data)
        r = self.service_update_pattern({
            'performers': [p1, p2, p5]
        }, s1, token)
        res = self.business_get_patern(token)
        r = self.service_update_pattern({
            'performers': [p3, p4, p5]
        }, s2, token)
        res = self.business_get_patern(token)
        obj = json.loads(res)
        assert set([p4, p3, p5]) == set(obj['services'][1]['performers'])

    def test_appointment(self):
        token = self.test_reg_business()
        r = self.service_reg_pattern({
            'name': 'Service',
            'price': 100,
            'duration': '0:30:00',
            'description': 'Common service'
        }, token)
        s = db.session.query(Service).filter(
            Service.name == 'Service').first().id
        r = self.performer_reg_pattern({
            'name': 'Performer',
            'phone': '+3889087628',
            'description': 'Common performer',
            'services': [s]
        }, token)
        p = db.session.query(Performer).filter(
            Performer.name == 'Performer').first().id
        email = 'a@bbb.cc'
        password = '123'
        user_token = self.create_user_token(email, password)
        time_date =datetime.utcnow().isoformat()
        r = self.app.post('/appointment', data=json.dumps({
            "service_id": s,
            "performer_id": p,
            'is_confirmed': False,
            'date': time_date,
            'notes': 'Common appointment'
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(user_token))
        })
        assert b"Bee" in r.data
        a = db.session.query(Appointment).filter(
            Appointment.service_id == s).first().id
        r = self.app.get('/appointment/{}'.format(a), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(user_token))
        })
        assert b'Common' in r.data

        time_date = datetime.utcnow().isoformat()
        r = self.app.put('/appointment/{0}'.format(a), data=json.dumps({
            "service_id": s,
            "performer_id": p,
            'is_confirmed': False,
            'date': time_date,
            'notes': 'Uncommon appointment'
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(user_token))
        })
        assert b'Bee' in r.data
        r = self.app.get('/appointment/{}'.format(a), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(user_token))
        })
        assert b'Uncommon' in r.data
        r = self.app.delete('/appointment/{}'.format(a), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(user_token))
        })
        assert not Appointment.get(a)

    def test_calc_vacant_hours(self):
        token = self.test_reg_business()
        r = self.service_reg_pattern({
            'name': 'Service',
            'price': 100,
            'duration': '0:30:00',
            'description': 'Common service'
        }, token)
        s = db.session.query(Service).filter(
            Service.name == 'Service').first().id
        r = self.performer_reg_pattern({
            'name': 'Performer',
            'phone': '+3889087628',
            'description': 'Common performer',
            'services': [s],
            'work_beg': time(hour=8, minute=0).isoformat(),
            'work_end': time(hour=18, minute=0).isoformat(),
            'lunch_beg': time(hour=11, minute=0).isoformat(),
            'lunch_end': time(hour=12, minute=0).isoformat(),
            'non_working_days': []
        }, token)
        p = db.session.query(Performer).filter(
            Performer.name == 'Performer').first().id
        email = 'a@bbb.cc'
        password = '123'
        user_token = self.create_user_token(email, password)
        time_date = utc.localize(datetime.combine(
            date.today(), time(hour=13, minute=30))).isoformat()
        r = self.app.post('/appointment', data=json.dumps({
            "service_id": s,
            "performer_id": p,
            'is_confirmed': False,
            'date': time_date,
            'notes': 'Common appointment',
            'coordx': 0.0,
            'coordy': 0.0
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(user_token))
        })
        a = db.session.query(Appointment).filter(
            Appointment.service_id == s).first().id
        r = self.app.get('/appointment/{}'.format(a), headers={
            'Authorization': ('Bearer {0}'.format(user_token))
        })
        assert b'notes' in r.data
        xdate = datetime.utcnow().isoformat()
        r = self.app.get('/performer/{0}/available_time'.format(p), query_string={
            "service_id": s,
            'date': xdate,
            'coordx': 1.0,
            'coordy': 1.0
        }, headers={
            'Authorization': ('Bearer {0}'.format(user_token))
        })
        assert b'8:00:00' in r.data
        user_id = db.session.query(User).first().id
        r = self.app.post('/appointment', data=json.dumps({
            "service_id": s,
            "performer_id": p,
            'is_confirmed': False,
            'date': time_date,
            'user_id': user_id,
            'notes': 'Common appointment 1',
            'coordx': 0.0,
            'coordy': 0.0
        }), headers={
            'Content-Type': 'application/json',
            'Authorization': ('Bearer {0}'.format(token))
        })
        r = self.app.get('/appointment', query_string={
            'service_id': s,
            'date': utc.localize(datetime.now()).isoformat()
        }, headers={
            'Authorization': ('Bearer {0}'.format(token))
        })
        assert b'Common appointment' in r.data

    def tearDown(self):
        db.session.query(User).delete()
        db.session.commit()


if __name__ == '__main__':
    unittest.main()
