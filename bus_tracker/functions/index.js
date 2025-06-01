/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

admin.initializeApp();
sgMail.setApiKey('YOUR_SENDGRID_API_KEY'); // Replace with your SendGrid API key

exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;

  // Generate a 4-digit OTP
  const otp = Math.floor(1000 + Math.random() * 9000);

  // Save the OTP to Firestore with a timestamp
  await admin.firestore().collection('otps').doc(email).set({
    otp: otp,
    timestamp: new Date().toISOString(),
  });

  // Send the OTP via email
  const msg = {
    to: email,
    from: 'your-email@example.com', // Replace with your verified sender email
    subject: 'Your OTP for Bus Tracking App',
    text: `Your OTP is: ${otp}`,
  };

  try {
    await sgMail.send(msg);
    return { success: true, message: 'OTP sent successfully' };
  } catch (error) {
    console.error('Error sending OTP email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send OTP email');
  }
});
