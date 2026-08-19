# Pets App Node.js Backend

This is a simple Express.js REST API that serves as the backend for the Pets App Flutter application.

## Prerequisites
- Node.js installed

## Setup
1. Run `npm install` to install dependencies.
2. Copy `.env.example` to `.env` and configure your environment variables.

## Running the Server
- For development with auto-reload: `npm run dev`
- For production: `npm start`

The server will start on `http://localhost:5000` (or the port specified in `.env`).

## API Endpoints
- `GET /api/health` - Check if the API is running
- `GET /api/pets` - Get all pets
- `GET /api/pets/:id` - Get a pet by ID
- `POST /api/pets` - Create a pet
- `PUT /api/pets/:id` - Update a pet
- `DELETE /api/pets/:id` - Delete a pet
- `GET /api/applications` - Get all applications
- `GET /api/applications/:id` - Get an application by ID
- `POST /api/applications` - Create an application
- `PUT /api/applications/:id` - Update an application
- `DELETE /api/applications/:id` - Delete an application
