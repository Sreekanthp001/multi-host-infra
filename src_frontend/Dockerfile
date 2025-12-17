# src_frontend/Dockerfile (Corrected)

# 1. Build Stage (Assuming you have a build step for your static files)
FROM node:20 as builder

WORKDIR /app

# Copy package.json and install dependencies
# COPY package*.json ./
# RUN npm install

# Copy application files and build
# COPY . .
# RUN npm run build --prod 

# 2. Nginx Stage
FROM nginx:alpine

# FIX 1: Copy the custom Nginx config file to the correct directory 
# This file must contain only the 'server { ... }' block.
# Assuming your custom config file is named 'default.conf' in the same directory.
COPY default.conf /etc/nginx/conf.d/default.conf

# FIX 2: Copy the built application files (e.g., HTML, CSS, JS) to Nginx's web root
# You must uncomment and update this line to copy your built UI files from the builder stage.
# COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

# FIX 3: CMD line is essential to start Nginx. 
# While the base image has a default CMD, specifying it ensures clarity and consistency.
# CMD [ "nginx", "-g", "daemon off;" ]