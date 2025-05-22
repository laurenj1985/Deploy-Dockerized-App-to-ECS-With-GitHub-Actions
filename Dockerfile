FROM python:3.11-slim

# Set working directory
WORKDIR /usr/src/app

# Copy app code
COPY app/ .

# Install Flask

RUN pip install flask

# Expose port
EXPOSE 3000

# Run the app
CMD ["python", "app.py"]
