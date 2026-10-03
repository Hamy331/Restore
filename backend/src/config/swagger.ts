import swaggerJsdoc from 'swagger-jsdoc';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'ReStore API',
      version: '1.0.0',
      description: 'REST API documentation for the ReStore C2C marketplace.',
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Local Development Server',
      },
    ],
    tags: [
      { name: 'Auth', description: 'Authentication endpoints' },
      { name: 'Users', description: 'User management' },
      { name: 'Listings', description: 'Product listings' },
      { name: 'Chat', description: 'Real-time chat messaging' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        ErrorResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            error: { type: 'string', example: 'Error message description' },
          },
        },
        User: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            email: { type: 'string', format: 'email' },
            fullName: { type: 'string' },
            username: { type: 'string' },
            phone: { type: 'string', nullable: true },
            avatarUrl: { type: 'string', nullable: true },
            role: { type: 'string', enum: ['USER', 'ADMIN'] },
            status: { type: 'string', enum: ['ACTIVE', 'SUSPENDED', 'BANNED'] },
            ratingAverage: { type: 'number', format: 'float' },
            ratingCount: { type: 'integer' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
        },
        LoginRequest: {
          type: 'object',
          required: ['email', 'password'],
          properties: {
            email: { type: 'string', format: 'email', example: 'user@example.com' },
            password: { type: 'string', format: 'password', example: 'password123' },
          },
        },
        RegisterRequest: {
          type: 'object',
          required: ['email', 'password', 'username', 'fullName'],
          properties: {
            email: { type: 'string', format: 'email', example: 'user@example.com' },
            password: { type: 'string', format: 'password', example: 'password123' },
            username: { type: 'string', example: 'johndoe' },
            fullName: { type: 'string', example: 'John Doe' },
          },
        },
        ForgotPasswordRequest: {
          type: 'object',
          required: ['email'],
          properties: {
            email: { type: 'string', format: 'email', example: 'user@example.com' },
          },
        },
        VerifyOtpRequest: {
          type: 'object',
          required: ['email', 'otp'],
          properties: {
            email: { type: 'string', format: 'email', example: 'user@example.com' },
            otp: { type: 'string', example: '123456' },
          },
        },
        ResetPasswordRequest: {
          type: 'object',
          required: ['email', 'otp', 'newPassword'],
          properties: {
            email: { type: 'string', format: 'email', example: 'user@example.com' },
            otp: { type: 'string', example: '123456' },
            newPassword: { type: 'string', format: 'password', example: 'newpassword123' },
          },
        },
      },
    },
  },
  apis: ['./src/docs/swagger/*.yaml'], 
};

export const swaggerSpec = swaggerJsdoc(options);
