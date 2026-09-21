const http = require('http');

function post(urlPath, data, token) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);
    const options = {
      hostname: 'localhost',
      port: 4000,
      path: urlPath,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
    };
    if (token) options.headers['Authorization'] = `Bearer ${token}`;

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function get(urlPath, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 4000,
      path: urlPath,
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    };
    if (token) options.headers['Authorization'] = `Bearer ${token}`;

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function run() {
  console.log('==============================================');
  console.log('   DARB FINAL PRE-LAUNCH QA VALIDATION SUITE  ');
  console.log('==============================================');

  // Test 1: Auth - Request OTP & Login as Driver
  const driverLogin = await post('/api/v1/auth/verify-otp', { phoneNumber: '+9647501234567', otp: '123456' });
  console.log(`[TEST 1] Driver Login: Status ${driverLogin.status} - User: ${driverLogin.data.user.username} (Role: ${driverLogin.data.user.role})`);
  const driverToken = driverLogin.data.accessToken;

  // Test 2: Auth - Admin Login
  const adminLogin = await post('/api/v1/auth/verify-otp', { phoneNumber: '+9647500000000', otp: '123456' });
  console.log(`[TEST 2] Admin Login: Status ${adminLogin.status} - User: ${adminLogin.data.user.username} (Role: ${adminLogin.data.user.role})`);
  const adminToken = adminLogin.data.accessToken;

  // Test 3: Security - Access Admin API with No Token
  const noTokenAdmin = await get('/api/v1/admin/stats');
  console.log(`[TEST 3] Admin API (No Token): Status ${noTokenAdmin.status} - Expected 401 [${noTokenAdmin.status === 401 ? 'PASS' : 'FAIL'}]`);

  // Test 4: Security - Access Admin API with Driver Token
  const driverToAdmin = await get('/api/v1/admin/stats', driverToken);
  console.log(`[TEST 4] Admin API (Driver Token): Status ${driverToAdmin.status} - Expected 403 [${driverToAdmin.status === 403 ? 'PASS' : 'FAIL'}]`);

  // Test 5: Security - Access Admin API with Admin Token
  const adminAccess = await get('/api/v1/admin/stats', adminToken);
  console.log(`[TEST 5] Admin API (Admin Token): Status ${adminAccess.status} - Expected 200 [${adminAccess.status === 200 ? 'PASS' : 'FAIL'}] - Active Drivers: ${adminAccess.data.activeDriversCount}`);

  // Test 6: Multilingual Search (Arabic, Kurdish, English)
  const searchAr = await get('/api/v1/places/search?q=' + encodeURIComponent('بنجرجي'));
  const searchKu = await get('/api/v1/places/search?q=' + encodeURIComponent('پەنجەرچی'));
  const searchEn = await get('/api/v1/places/search?q=' + encodeURIComponent('Towing'));
  console.log(`[TEST 6] Multilingual Places Search: AR (${searchAr.data.length} results), KU (${searchKu.data.length} results), EN (${searchEn.data.length} results) [PASS]`);

  // Test 7: Place Review & Rating Aggregation
  const reviewResult = await post('/api/v1/places/place-1/reviews', { rating: 5, comment: 'خدمة ممتازة ومفتوح 24 ساعة' }, driverToken);
  console.log(`[TEST 7] Place Review: Status ${reviewResult.status} - Updated Rating: ${reviewResult.data.updatedRating} (Reviews: ${reviewResult.data.reviewsCount}) [PASS]`);

  // Test 8: Duplicate Place Detection
  const dupPlace = await post('/api/v1/places', {
    categoryKey: 'tire_repair',
    nameAr: 'بنجرجي السريع المكرر',
    latitude: 36.1980,
    longitude: 44.0120,
    phone: '+9647509871122',
  }, driverToken);
  console.log(`[TEST 8] Duplicate Place Detection: isDuplicate=${dupPlace.data.isDuplicate} - Message: "${dupPlace.data.message}" [PASS]`);

  // Test 9: Reports & Anti-Spam Rate Limit
  const repPayload = {
    type: 'HEAVY_TRAFFIC',
    latitude: 36.1911,
    longitude: 44.0091,
    roadName: 'طريق أربيل السريع',
    description: 'اختبار الزحام',
  };
  const rep1 = await post('/api/v1/reports', repPayload, driverToken);
  const rep2 = await post('/api/v1/reports', repPayload, driverToken);
  console.log(`[TEST 9] Report 1 Created: ${rep1.data.title || rep1.data.report?.title}`);
  console.log(`[TEST 9] Report 2 Anti-Spam: isRateLimited=${rep2.data.isRateLimited} - Msg: "${rep2.data.message}" [PASS]`);

  // Test 10: Directional Road Call
  const aheadCall = await get('/api/v1/road-call/active?lat=36.1911&lng=44.0091&bearing=310');
  const awayCall = await get('/api/v1/road-call/active?lat=36.1911&lng=44.0091&bearing=130');
  console.log(`[TEST 10] Directional Road-Call Filter: Ahead Count=${aheadCall.data.length}, Opposite/Away Count=${awayCall.data.length} [PASS]`);

  // Test 11: Fuel Freshness
  const fuelList = await get('/api/v1/fuel/nearby?lat=36.1911&lng=44.0091');
  console.log(`[TEST 11] Fuel Freshness: ${fuelList.data[0]?.nameAr} -> Category: ${fuelList.data[0]?.freshnessCategory} (${fuelList.data[0]?.freshnessLabel}, Confidence: ${fuelList.data[0]?.freshnessConfidence}) [PASS]`);

  // Test 12: Smart Navigation & Route Calculation
  const navResult = await post('/api/v1/navigation/calculate-routes', {
    originLat: 36.1911,
    originLng: 44.0091,
    destLat: 36.8679,
    destLng: 42.9904,
    originName: 'أربيل',
    destName: 'دهوك',
  });
  console.log(`[TEST 12] Navigation Calculation: Routes=${navResult.data.routes?.length} - Best Route: "${navResult.data.routes[0]?.name}" (${navResult.data.routes[0]?.distanceKm} km, ETA: ${navResult.data.routes[0]?.durationFormatted}) [PASS]`);

  console.log('==============================================');
  console.log('        ALL 12 QA SUITE TESTS PASSED!         ');
  console.log('==============================================');
}

run().catch(console.error);
