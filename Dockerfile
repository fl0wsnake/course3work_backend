FROM python:2
WORKDIR /app
COPY setup.py setup.py
RUN pip install watchdog
RUN pip install -e .
ENV FLASK_APP backend 
ENV FLASK_DEBUG 1
EXPOSE 5000
