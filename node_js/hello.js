// hello.js

// Import the built-in HTTP module
const http = require('http');

// Define the server port
const PORT = 3000;

// Create the HTTP server
const server = http.createServer((req, res) => {
    try {
        res.statusCode = 200; // HTTP OK
        res.setHeader('Content-Type', 'text/plain');
        res.end('Hello, World!\n');
    } catch (error) {
        console.error('Server error:', error);
        res.statusCode = 500;
        res.end('Internal Server Error');
    }
});

// Start listening on the defined port
server.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}/`);
});
