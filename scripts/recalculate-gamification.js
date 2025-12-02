// Recalculate Gamification Levels and Badges
// Node.js script to call the backend API

const http = require('http');

const backendUrl = 'http://localhost:3000';

console.log('========================================');
console.log('Recalculating Gamification Levels and Badges');
console.log('========================================');
console.log('');

// First check if backend is running
const checkBackend = () => {
  return new Promise((resolve, reject) => {
    const req = http.get(`${backendUrl}/health`, (res) => {
      if (res.statusCode === 200) {
        console.log('✓ Backend is running');
        resolve();
      } else {
        reject(new Error(`Backend returned status ${res.statusCode}`));
      }
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Backend health check timeout'));
    });
  });
};

// Call recalculate API
const recalculate = () => {
  return new Promise((resolve, reject) => {
    const postData = '';
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/gamification/recalculate/all',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 300000 // 5 minutes timeout
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          resolve(result);
        } catch (err) {
          reject(new Error(`Failed to parse response: ${err.message}`));
        }
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
    
    req.write(postData);
    req.end();
  });
};

// Main execution
(async () => {
  try {
    await checkBackend();
    console.log('');
    console.log('Calling API: POST /api/gamification/recalculate/all');
    console.log('');
    
    const result = await recalculate();
    
    if (result.ok) {
      console.log('✓ Recalculation completed!');
      console.log('');
      console.log('Results:');
      console.log(`  Users updated: ${result.data.usersUpdated}`);
      console.log(`  Badges unlocked: ${result.data.badgesUnlocked}`);
      console.log('');
      console.log('========================================');
    } else {
      console.error('✗ Failed:', result.error);
      process.exit(1);
    }
  } catch (err) {
    console.error('✗ Error:', err.message);
    process.exit(1);
  }
})();

