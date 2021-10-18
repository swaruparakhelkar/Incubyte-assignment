FROM python:alpine3.7
ADD . /app
WORKDIR /app
RUN pip install -r /app/requirements.txt
CMD cd /app && python app.py
EXPOSE 5000