FROM ghost:latest

# Install some utilities
RUN apt-get update && apt-get install -y \
    iputils-ping curl mailutils vim

# Set the working directory to the Ghost installation directory
WORKDIR /var/lib/ghost

# Copy the additional app files to the Ghost installation directory
# COPY <path to app files> .

# Set the ownership of the app files to the "ghost" user and group
# RUN chown -R ghost:ghost <path to app files>

# Expose the default Ghost port
EXPOSE 2368

# Start the Ghost server
#CMD ["npm", "start"]
