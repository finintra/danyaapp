const { exec } = require('child_process');

// Replace with a valid token
const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwibmFtZSI6Ik1pdGNoZWxsIEFkbWluIiwiZGV2aWNlSWQiOiJkZWE3N2VjZS0wOWY1LTRlMGYtYTk1MC00NGI1ZWNhZDFhNDIiLCJpYXQiOjE3NjE1MDAzNjMsImV4cCI6MTc2MTUyOTE2M30.Zi0RAX3trfuSqloKqDwgoxztrsLSJxa7P8F3B_HIrR4';

// Command to execute
const command = `curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -d "{\\"picking_barcode\\":\\"OUT/00001\\"}" http://localhost:3000/flf/api/v1/task/attach`;

console.log('Executing command:', command);

// Execute the command
exec(command, (error, stdout, stderr) => {
  if (error) {
    console.error(`Error: ${error.message}`);
    return;
  }
  if (stderr) {
    console.error(`Stderr: ${stderr}`);
    return;
  }
  console.log(`Stdout: ${stdout}`);
});
