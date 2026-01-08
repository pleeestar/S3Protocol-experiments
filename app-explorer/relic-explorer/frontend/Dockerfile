FROM node:18-alpine
WORKDIR /app
COPY package.json .
# Install dependencies inside container
RUN npm install
COPY . .
# For development (hot reload)
CMD ["npm", "run", "dev"]
