/**
 * index.js
 * Cloud Functions for managing global metrics in the Admin Dashboard.
 * * IMPORTANT: You must run 'firebase init functions' and 'npm install firebase-admin firebase-functions'
 * in your functions directory before deployment.
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize the Admin SDK (crucial for server-side operations)
admin.initializeApp();

const METRICS_DOC_REF = admin.firestore().doc('metrics/global');

// -----------------------------------------------------------
// 1. COUNTING USERS (Auth Triggers)
// -----------------------------------------------------------

/**
 * Triggered when a new user account is created in Firebase Authentication.
 * Increments the global user count.
 */
exports.countUsersOnCreate = functions.auth.user().onCreate(async (user) => {
    functions.logger.log(`User created: ${user.uid}. Incrementing totalUsers.`);
    
    return METRICS_DOC_REF.set({
        totalUsers: admin.firestore.FieldValue.increment(1),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
});

/**
 * Triggered when a user account is deleted from Firebase Authentication.
 * Decrements the global user count.
 */
exports.countUsersOnDelete = functions.auth.user().onDelete(async (user) => {
    functions.logger.log(`User deleted: ${user.uid}. Decrementing totalUsers.`);
    
    // Ensure the count doesn't drop below zero in case of unexpected errors
    return METRICS_DOC_REF.set({
        totalUsers: admin.firestore.FieldValue.increment(-1),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
});
// 

// -----------------------------------------------------------
// 2. COUNTING RECEIPTS (Firestore Trigger)
// -----------------------------------------------------------

/**
 * Triggered when a document is created, updated, or deleted 
 * in ANY subcollection matching: 'users/{userId}/receipts/{docId}'.
 * This handles both creation (+1) and deletion (-1) of receipts.
 */
exports.countReceiptsOnWrite = functions.firestore
    .document('users/{userId}/receipts/{docId}')
    .onWrite(async (change, context) => {
        const receiptId = context.params.docId;
        
        let incrementValue = 0;
        
        // Document created (change.before.exists is false, change.after.exists is true)
        if (change.after.exists && !change.before.exists) {
            incrementValue = 1;
            functions.logger.log(`Receipt created: ${receiptId}. Incrementing totalReceipts.`);
        } 
        // Document deleted (change.before.exists is true, change.after.exists is false)
        else if (!change.after.exists && change.before.exists) {
            incrementValue = -1;
            functions.logger.log(`Receipt deleted: ${receiptId}. Decrementing totalReceipts.`);
        }
        // Document updated (change.before.exists is true, change.after.exists is true)
        // No change to the count needed for updates.
        
        if (incrementValue !== 0) {
            return METRICS_DOC_REF.set({
                totalReceipts: admin.firestore.FieldValue.increment(incrementValue),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
        }
        
        return null; // No change to the metric document was required
    });
//