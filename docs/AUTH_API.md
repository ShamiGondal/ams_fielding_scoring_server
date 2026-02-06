# Authentication API Documentation

## Overview
The authentication system provides secure login, token-based authentication, and user management for the Cricket Fielding Scoring System.

## Base URL
`http://localhost:3001/api/auth`

---

## Endpoints

### 1. Admin Login
**POST** `/api/auth/admin-login`

Login with hardcoded admin credentials.

**Request Body:**
```json
{
  "email": "admin@pcb.com.pk",
  "password": "your_password"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "email": "admin@pcb.com.pk",
    "role": "admin"
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

---

### 2. User Login
**POST** `/api/auth/user-login`

Login for regular users with database verification.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 5,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "Analyst Scorer",
    "roleId": 2,
    "isSupervisor": false
  }
}
```

**Error Responses:**
- **401 Unauthorized:** Invalid credentials
- **403 Forbidden:** Email not verified

---

### 3. Reset Password
**POST** `/api/auth/reset-password`

Reset user password (requires email and userId for verification).

**Request Body:**
```json
{
  "email": "user@example.com",
  "userId": 5,
  "newPassword": "newPassword123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset successfully",
  "userId": 5
}
```

**Error Response (404 Not Found):**
```json
{
  "success": false,
  "message": "User not found with provided email and ID"
}
```

---

### 4. Verify Token
**GET** `/api/auth/verify-token`

Verify if a JWT token is valid.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Token is valid",
  "user": {
    "id": 5,
    "email": "user@example.com",
    "role": "Analyst Scorer",
    "type": "user"
  }
}
```

**Error Responses:**
- **401 Unauthorized:** No token provided / Invalid token / Token expired

---

### 5. Logout
**POST** `/api/auth/logout`

Logout endpoint (client-side token removal).

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logout successful. Please remove token from client."
}
```

---

## Authentication Flow

### Login Flow
```
1. User sends credentials to /api/auth/user-login
2. Server verifies credentials against database
3. Server generates JWT token (expires in 72h)
4. Client stores token in localStorage/sessionStorage
5. Client includes token in Authorization header for protected routes
```

### Protected Route Access
```
1. Client sends request with Authorization header
2. Server verifies token using middleware
3. Server checks user role/permissions
4. Server processes request or returns 401/403
```

---

## Middleware

### verifyToken
Verifies JWT token in Authorization header.

**Usage:**
```javascript
router.get('/protected', verifyToken, (req, res) => {
  // req.user contains decoded token data
  res.json({ user: req.user });
});
```

### isAdmin
Checks if user has admin privileges.

**Usage:**
```javascript
router.get('/admin-only', verifyToken, isAdmin, (req, res) => {
  // Only admins can access
});
```

### isSupervisor
Checks if user is admin or supervisor.

**Usage:**
```javascript
router.get('/supervisor-only', verifyToken, isSupervisor, (req, res) => {
  // Admins and supervisors can access
});
```

### hasRole
Checks if user has specific role(s).

**Usage:**
```javascript
router.get('/scorer-only', verifyToken, hasRole(['Analyst Scorer']), (req, res) => {
  // Only users with 'Analyst Scorer' role can access
});
```

---

## Security Features

1. **Password Hashing:** bcrypt with salt (10 rounds)
2. **JWT Tokens:** Signed with secret, 72-hour expiry
3. **Input Validation:** express-validator for all inputs
4. **Email Verification:** Required for user login
5. **Role-Based Access Control:** Admin, Supervisor, User roles
6. **CORS Protection:** Configured for allowed origins

---

## Error Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad Request (validation errors) |
| 401 | Unauthorized (invalid/expired token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found (user/resource not found) |
| 500 | Internal Server Error |

---

## Example Usage

### Login and Access Protected Route

```javascript
// 1. Login
const loginResponse = await fetch('http://localhost:3001/api/auth/user-login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'password123'
  })
});

const { token } = await loginResponse.json();

// 2. Store token
localStorage.setItem('token', token);

// 3. Access protected route
const dataResponse = await fetch('http://localhost:3001/api/users/5', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const userData = await dataResponse.json();
```

---

## Token Structure

```json
{
  "id": 5,
  "email": "user@example.com",
  "role": "Analyst Scorer",
  "roleId": 2,
  "type": "user",
  "iat": 1738562162,
  "exp": 1738821362
}
```
