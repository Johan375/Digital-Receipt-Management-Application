// set-admin.js
const admin = require('firebase-admin');

// 1. Point to your downloaded Service Account key
const serviceAccount = require('./service-account.json'); 

// 2. IMPORTANT: Replace this with the User ID you want to make admin
const TARGET_UID = '2LaqtCPX31PueTSKPxjUl6UMXvH2'; 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function setAdminClaim() {
    try {
        console.log(`Setting 'admin: true' claim for user: ${TARGET_UID}`);
        
        // This is the core Admin SDK command that sets the claim
        await admin.auth().setCustomUserClaims(TARGET_UID, { admin: true });
        
        // Verification step (optional but helpful)
        const user = await admin.auth().getUser(TARGET_UID);
        console.log('Verification: Custom claims now:', user.customClaims);
        
        console.log('\n✅ SUCCESS: The admin role has been set.');
    } catch (error) {
        console.error('❌ ERROR setting admin claim:', error);
    } finally {
        // Exit the script gracefully
        process.exit();
    }
}

setAdminClaim();