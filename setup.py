from setuptools import setup, find_packages

setup(
    name='backend',
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        'flask',
        'Flask-SQLAlchemy',
        'Flask-Migrate',
        'psycopg2',
        'flask-JWT-extended',
        'flask-cors',
        'sqlalchemy_utils',
        'interval',
        'cerberus',
        'pytz',
        'tzlocal'
    ],
    test_suite='tests',
)
