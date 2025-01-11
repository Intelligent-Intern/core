FROM registry.kreuzung1.de/intelligent-intern/python-app-base:latest
RUN useradd -m appuser
WORKDIR /app
COPY entrypoint.sh /entrypoint/entrypoint.sh
RUN chmod +x /entrypoint/entrypoint.sh
ENV PYTHONPATH="/app"
ENV FLASK_ENV=development
ENV FLASK_APP=app.py
ENV PATH="/home/appuser/.local/bin:${PATH}"
RUN chown -R appuser:appuser /app
USER appuser
EXPOSE 5000
