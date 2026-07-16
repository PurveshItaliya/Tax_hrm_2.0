const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const schedule = require('node-schedule');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

let isMockMode = false;
const serviceAccountPath = path.join(__dirname, 'service-account.json');

// 1. Initialize Firebase Admin SDK
if (fs.existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('[FCM Backend] Firebase Admin SDK initialized using service-account.json');
  } catch (error) {
    console.error('[FCM Backend] Error reading service-account.json:', error);
    isMockMode = true;
  }
} else {
  console.warn('[FCM Backend] service-account.json not found at ' + serviceAccountPath);
  console.warn('[FCM Backend] Attempting default credentials initialization...');
  try {
    admin.initializeApp();
    console.log('[FCM Backend] Firebase Admin SDK initialized using Application Default Credentials');
  } catch (error) {
    console.error('[FCM Backend] Failed to initialize default Firebase credentials.');
    console.warn('[FCM Backend] WARNING: RUNNING IN MOCK MODE. Notifications will be logged to console but not sent.');
    isMockMode = true;
  }
}

// Helper to chunk topics list into arrays of maximum size 5 (FCM limits conditions to 5 topics)
function chunkTopics(topics, size = 5) {
  const chunks = [];
  for (let i = 0; i < topics.length; i += size) {
    chunks.push(topics.slice(i, i + size));
  }
  return chunks;
}

// Function to construct condition query for FCM
// e.g. "'all' in topics || 'all_admin' in topics"
function buildCondition(topicsChunk) {
  return topicsChunk.map(t => `'${t}' in topics`).join(' || ');
}

// Core FCM dispatch function
async function dispatchNotification({ title, message, imageUrl, screen, topics }) {
  if (isMockMode) {
    console.log('\n--- SIMULATED PUSH NOTIFICATION DISPATCH ---');
    console.log(`Title: ${title}`);
    console.log(`Message: ${message}`);
    console.log(`Image: ${imageUrl || 'None'}`);
    console.log(`Screen/Deep-link: ${screen || 'None'}`);
    console.log(`Target Topics: ${topics.join(', ')}`);
    console.log('--------------------------------------------\n');
    return { success: true, simulated: true };
  }

  // FCM supports direct 'topic' target if there is only 1 topic
  if (topics.length === 1) {
    const payload = {
      notification: {
        title: title,
        body: message,
        ...(imageUrl ? { imageUrl: imageUrl } : {})
      },
      data: {
        title: title,
        body: message,
        ...(imageUrl ? { image: imageUrl } : {}),
        ...(screen ? { screen: screen } : {})
      },
      android: {
        notification: {
          channelId: 'high_importance_channel',
          sound: 'soft_notify_sound',
          ...(imageUrl ? { imageUrl: imageUrl } : {})
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'soft_notify_sound.mp3',
            badge: 1
          }
        },
        fcmOptions: {
          ...(imageUrl ? { imageUrl: imageUrl } : {})
        }
      },
      topic: topics[0]
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log(`[FCM Backend] Successfully sent notification to topic: ${topics[0]}. Response:`, response);
      return { success: true, responses: [response] };
    } catch (err) {
      console.error(`[FCM Backend] Error sending to topic ${topics[0]}:`, err);
      throw err;
    }
  }

  // For multiple topics, chunk them into groups of up to 5 and send via condition
  const chunks = chunkTopics(topics, 5);
  const sendPromises = chunks.map(async (chunk) => {
    const condition = buildCondition(chunk);
    const payload = {
      notification: {
        title: title,
        body: message,
        ...(imageUrl ? { imageUrl: imageUrl } : {})
      },
      data: {
        title: title,
        body: message,
        ...(imageUrl ? { image: imageUrl } : {}),
        ...(screen ? { screen: screen } : {})
      },
      android: {
        notification: {
          channelId: 'high_importance_channel',
          sound: 'soft_notify_sound',
          ...(imageUrl ? { imageUrl: imageUrl } : {})
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'soft_notify_sound.mp3',
            badge: 1
          }
        },
        fcmOptions: {
          ...(imageUrl ? { imageUrl: imageUrl } : {})
        }
      },
      condition: condition
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log(`[FCM Backend] Successfully sent notification chunk condition: "${condition}". Response:`, response);
      return response;
    } catch (err) {
      console.error(`[FCM Backend] Error sending to condition "${condition}":`, err);
      throw err;
    }
  });

  const responses = await Promise.all(sendPromises);
  return { success: true, responses };
}

// API Routes
app.post('/api/send-notification', async (req, res) => {
  const { title, message, imageUrl, screen, scheduleTime, topics } = req.body;

  if (!title || !message || !topics || !Array.isArray(topics) || topics.length === 0) {
    return res.status(400).json({ error: 'Title, message, and topics (array) are required.' });
  }

  // 1. If scheduling is requested
  if (scheduleTime) {
    const targetDate = new Date(scheduleTime);
    if (isNaN(targetDate.getTime())) {
      return res.status(400).json({ error: 'Invalid scheduleTime format.' });
    }

    if (targetDate > new Date()) {
      console.log(`[FCM Backend] Scheduling notification for ${targetDate.toString()}`);
      
      schedule.scheduleJob(targetDate, async () => {
        try {
          console.log(`[FCM Backend] Executing scheduled notification: "${title}"`);
          await dispatchNotification({ title, message, imageUrl, screen, topics });
        } catch (err) {
          console.error('[FCM Backend] Error executing scheduled notification:', err);
        }
      });

      return res.status(200).json({
        success: true,
        message: `Notification scheduled successfully for ${targetDate.toString()}`
      });
    } else {
      console.log('[FCM Backend] Scheduled time is in the past. Sending immediately.');
    }
  }

  // 2. Dispatch immediately
  try {
    const result = await dispatchNotification({ title, message, imageUrl, screen, topics });
    return res.status(200).json(result);
  } catch (error) {
    return res.status(500).json({ error: 'Failed to send notification via Firebase', details: error.message });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    firebaseInitialized: !isMockMode,
    mode: isMockMode ? 'MOCK_MODE (No service-account.json found)' : 'LIVE_MODE'
  });
});

app.listen(PORT, () => {
  console.log(`[FCM Backend] Server running on http://localhost:${PORT}`);
});
