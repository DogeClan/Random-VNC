# Start from a lightweight Python base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install required packages for VNC and other dependencies
RUN apt-get update && \
    apt-get install -y \
    x11vnc \
    xvfb \
    novnc \
    websockify \
    && pip install Flask==2.1.1 \
    && rm -rf /var/lib/apt/lists/*

# Create the Flask application code directly in the Dockerfile
RUN echo 'from flask import Flask, render_template, request\n\
import os\n\
\n\
app = Flask(__name__)\n\
\n\
@app.route("/")\n\
def index():\n\
    return render_template("index.html")\n\
\n\
@app.route("/share", methods=["POST"])\n\
def share():\n\
    url = request.form.get("url")\n\
    return render_template("index.html", shared_url=url)\n\
\n\
if __name__ == "__main__":\n\
    app.run(host="0.0.0.0", port=5000)' > app.py

# Create the HTML template directly in the Dockerfile
RUN mkdir templates && \
    echo '<!DOCTYPE html>\n\
<html lang="en">\n\
<head>\n\
    <meta charset="UTF-8">\n\
    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n\
    <title>VNC URL Sharing</title>\n\
</head>\n\
<body>\n\
    <h1>Share a URL with VNC</h1>\n\
    <form action="/share" method="POST">\n\
        <label for="url">Enter URL:</label>\n\
        <input type="text" id="url" name="url" required>\n\
        <button type="submit">Share</button>\n\
    </form>\n\
    {% if shared_url %}\n\
        <h2>Access the shared URL on VNC:</h2>\n\
        <p>{{ shared_url }}</p>\n\
        <iframe src="http://localhost:6080/" style="width:100%; height:400px;" frameborder="0"></iframe>\n\
    {% endif %}\n\
</body>\n\
</html>' > templates/index.html

# Expose the necessary ports
EXPOSE 5000 5900 6080

# Run both the Flask application and the VNC server
CMD /usr/bin/xvfb-run --server-args="-screen 0, 1280x720x24" x11vnc -display :0 -nopw -forever -repeat & \
    /usr/bin/websockify --web /usr/share/novnc 6080 localhost:5900 & \
    python app.py
