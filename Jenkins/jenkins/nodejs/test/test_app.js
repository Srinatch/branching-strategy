const assert = require('assert');
const greet = require('../app');

assert.strictEqual(greet(), "Hello from Jenkins Node.js Pipeline!");

console.log("Test passed!");