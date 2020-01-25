from python:2.7
ADD requirements.txt .

RUN pip install -r requirements.txt

ADD app.py .

EXPOSE 80
ENTRYPOINT python app.py
