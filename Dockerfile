# Creating a new stage. This stage will install the dependencies related to project
FROM --platform=linux/amd64 node:16-alpine AS deps
# A shared library which is requried for process.dlopen is missing in alpine image. So you need
# to run below command in order avoid any issues that might occur due to that.
RUN apk add --no-cache libc6-compat
# Setting the current working directory as /app
WORKDIR /app
# Copying the package.json files from this project folder to this deps stage
COPY package.json package-lock.json* ./
# Installing the dependencies based on the copied files
RUN npm ci


# Creating a new stage. This stage will build the project
FROM --platform=linux/amd64 node:16-alpine AS builder
# Setting the current working directory as /app
WORKDIR /app
# Copying node modules from previous stage to this stage
COPY --from=deps /app/node_modules ./node_modules
# Copying source code from this project folder to this this stage
COPY . .
# building the project
RUN npm run build


# Creating a new stage. This stage will run the project
FROM --platform=linux/amd64 node:16-alpine AS runner
# Setting the current working directory as /app
WORKDIR /app
# This will improve the performance of the application
ENV NODE_ENV production
# Creating a new user group
RUN addgroup --system --gid 1001 group1
# Creating a new user
RUN adduser --system --uid 1001 user1
# Copying the public folder from builder stage to current stage 
COPY --from=builder /app/public ./public
# Copying the traced files from builder stage to current stage
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
# Switching the current user to a non root user
USER user1
# Setting the PORT environment variable
ENV PORT 3000
# Specifying the listening port
EXPOSE $PORT
# Specifying the command that needs to get executed when the container is running
CMD ["node", "server.js"]