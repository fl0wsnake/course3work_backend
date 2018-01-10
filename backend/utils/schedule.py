from datetime import timedelta, datetime
from interval import Interval, IntervalSet
from backend.service.models import Performer, Service, Appointment
from sqlalchemy import cast, Date
from sqlalchemy.sql import select
from backend import db
from dateutil.parser import parse
from pytz import utc, timezone, reference
from tzlocal import get_localzone


def to_interval(beg, end):
    return Interval(beg.seconds / 60, end.seconds / 60)


def to_time(inter):
    return timedelta(minutes=inter.lower_bound),\
        timedelta(minutes=inter.upper_bound)


def printf(time_tuple):
    print("{0} - {1}".format(time_tuple[0], time_tuple[1]))


intervals = [
    (timedelta(hours=1, minutes=5),
     timedelta(hours=1, minutes=30)),
    (timedelta(hours=3, minutes=15),
     timedelta(hours=4, minutes=20)),
    (timedelta(hours=2, minutes=35),
     timedelta(hours=5, minutes=45)),
    (timedelta(hours=4, minutes=10),
     timedelta(hours=7, minutes=35)),
    (timedelta(hours=7, minutes=15),
     timedelta(hours=7, minutes=40)),
    (timedelta(hours=6, minutes=0),
     timedelta(hours=7, minutes=5)),
    (timedelta(hours=10, minutes=10),
     timedelta(hours=15, minutes=35)),
    (timedelta(hours=5, minutes=0),
     timedelta(hours=6, minutes=25)),
    (timedelta(hours=7, minutes=30),
     timedelta(hours=9, minutes=55)),
    (timedelta(hours=1, minutes=15),
     timedelta(hours=1, minutes=52)),
    (timedelta(hours=9, minutes=15),
     timedelta(hours=10, minutes=70))
]


working_hours = [
    (timedelta(hours=8, minutes=0),
     timedelta(hours=18, minutes=0))
]

lunch = [
    (timedelta(hours=12, minutes=0),
     timedelta(hours=13, minutes=0))
]

appointments = [
    (timedelta(hours=9, minutes=30),
     timedelta(hours=10, minutes=0)),
    (timedelta(hours=14, minutes=0),
     timedelta(hours=15, minutes=30)),
    (timedelta(hours=17, minutes=15),
     timedelta(hours=17, minutes=45))
]


def merge_timelines(working=[], busy=[]):
    return [to_time(x) for x in IntervalSet([
        to_interval(beg, end) for beg, end in working
    ]) - IntervalSet([
        to_interval(beg, end)
        for beg, end in busy
    ])]


# print("Quick maths")
# for x in merge_timelines(intervals + working_hours):
#     printf(x)
# print("-")
# for x in merge_timelines(lunch + appointments):
#     printf(x)
# print("=")
# for x in merge_timelines(intervals + working_hours, lunch + appointments):
#     printf(x)


def get_travel_time(coordx=(0, 0), coordy=(0, 0)):
    return timedelta(minutes=30)


def get_schedule(business_id, **kwargs):
    s = select([Appointment])\
        .select_from(Appointment.__table__.join(Performer.__table__))\
        .where(Performer.__table__.c.business_id == business_id)
    data = kwargs['kwargs']
    if data['service_id']:
        s = s.where(Appointment.__table__.c.service_id == data['service_id'])
    if data['performer_id']:
        s = s.where(Appointment.__table__.c.performer_id ==
                    data['performer_id'])
    if data['date']:
        s = s.where(cast(Appointment.__table__.c.date, Date)
                    == data['date'].isoformat())
    else:
        s = s.where(Appointment.__table__.c.date > datetime.utcnow())
    # if not data['service_id'] and not data['performer_id'] and not data['date']:
    #     return [x.to_obj() for x in db.session.query(Appointment).filter(Appointment.performer.business_id == business_id)]
    # if not data['service_id'] and not data['performer_id']:
    #     return [x.to_obj() for x in db.session.query(Appointment).filter(Appointment.performer.business_id == business_id, 
    #         cast(Appointment.date, Date) == data['date'])]
    return map(lambda x: x.to_obj(), db.session.query(Appointment).from_statement(s))


def calc_vacant_hours(perf_id, serv_id, coord, xdate):
    local_tz = timezone('Europe/Moscow')
    print(local_tz)
    performer = Performer.get(perf_id)
    if performer.non_working_days and \
    (xdate.isoweekday() in performer.non_working_days):
        return []
    duration = Service.get(serv_id).duration
    tasks = db.session.query(Appointment).filter(
        Appointment.performer_id == perf_id,
        cast(Appointment.date, Date) == xdate
    )
    busy = []
    for task in tasks:
        local_date = task.date.astimezone(local_tz)
        time_to_location = get_travel_time((task.coordx, task.coordy), coord) if coord else timedelta(minutes=0)
        time_tuple = timedelta(
            hours=local_date.hour,
            minutes=local_date.minute
        ) - time_to_location - duration, timedelta(
            hours=local_date.hour,
            minutes=local_date.minute
        ) + task.service.duration + time_to_location
        busy.append(time_tuple)
    working = [performer.get_working_hours()]
    busy.append(performer.get_lunch_hours())
    return merge_timelines(working, busy)


# for x in reduce(lambda acc, x: acc | x, [
#         to_interval(beg, end) for beg, end in working_hours]):
#     print(x)

# for x in reduce(lambda acc, x: acc | x, [
#         to_interval(beg, end) for beg, end in lunch + appointments]):
#     print(x)

# for x in reduce(lambda acc, x: acc | x, [
#         to_interval(beg, end) for beg, end in lunch + appointments]).inverse():
#     print(x)


# def calc_working_hours(working=[], busy=[]):
#     return [to_time(inter) for inter in (
#         reduce(lambda acc, x: acc | x, [
#             to_interval(beg, end) for beg, end in working
#         ]) & reduce(lambda acc, x: acc | x, [
#             to_interval(beg, end) for beg, end in busy
#         ]).inverse()
#     )]


# for x in calc_working_hours(working_hours, lunch + appointments):
#     printf(x)


#
# class Period():
#     def __init__(self, xdate, xtime, duration):
#         self.beginning = datetime.combine(xdate, xtime)
#         self.duration = timedelta(minutes=duration)

#     def end(self):
#         return self.beginning + self.duration


# def printf(data):
#     print("\n{0} schedule:".format(data[0].beginning.date()))
#     for it in data:
#         print("{0} - {1}".format(it.beginning.time(), it.end().time()))


# timeline = [
#     Period(date.today(), time(hour=1, minute=5), 25),
#     Period(date.today(), time(hour=3, minute=15), 80),
#     Period(date.today(), time(hour=2, minute=35), 190),
#     Period(date.today(), time(hour=4, minute=10), 205),
#     Period(date.today(), time(hour=7, minute=15), 25),
#     Period(date.today(), time(hour=6, minute=0), 65),
#     Period(date.today(), time(hour=10, minute=10), 325),
#     Period(date.today(), time(hour=5, minute=0), 85),
#     Period(date.today(), time(hour=7, minute=30), 145),
#     Period(date.today(), time(hour=1, minute=15), 37),
#     Period(date.today(), time(hour=9, minute=15), 70)
# ]

# intervals = [to_interval(timedelta(hours=per.beginning.hour, minutes=per.beginning.minute),
#                          timedelta(hours=per.end().hour,
#                                    minutes=per.end().minute)) for per in timeline]


# def merge_timeline(intervals):
#     if not len(intervals):
#         return intervals
#     intervals.sort(key=lambda x: x.beginning)
#     result = []
#     for i in range(len(intervals) - 1):
#         if intervals[i].end() < intervals[i + 1].beginning:
#             result.append(intervals[i])
#         else:
#             intervals[i + 1].duration = max(intervals[i + 1].end(),
#                                             intervals[i].end()) - intervals[i].beginning
#             intervals[i + 1].beginning = intervals[i].beginning
#         if (len(intervals) - 2 == i):
#             result.append(intervals[i + 1])

#     return result


# printf(timeline)
# timeline.sort(key=lambda x: x.beginning)
# printf(timeline)
# printf(merge_timeline(timeline))
