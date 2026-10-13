const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({
  maxInstances: 10,
  region: "us-central1",
});

exports.sendPushNotification = onCall(async (request) => {
  // لازم المستخدم يكون مسجل دخول
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated.",
    );
  }

  const receiverId = request.data.receiverId;
  const type = request.data.type;
  const referenceId = request.data.referenceId || "";
  const senderId = request.data.senderId || "";

  if (!receiverId || !type) {
    throw new HttpsError(
        "invalid-argument",
        "receiverId and type are required.",
    );
  }
//We support 2 types of notifications which are friend request and practice invitation
  const supportedTypes = [
    "friend_request",
    "practice_invitation",
  ];

  if (!supportedTypes.includes(type)) {
    throw new HttpsError(
      "invalid-argument",
      "Unsupported notification type.",
    );
  }

  try {
const childDoc = await admin
    .firestore()
    .collection("children")
    .doc(receiverId)
    .get();

let childName = "طفلك";

if (childDoc.exists) {
  childName = childDoc.data().name || "طفلك";
}
    const tokenDoc = await admin
        .firestore()
        .collection("child_fcm_tokens")
        .doc(receiverId)
        .get();

    if (!tokenDoc.exists) {
      logger.warn("No FCM token found", {receiverId});

      return {
        success: false,
        reason: "NO_TOKEN",
      };
    }

    const token = tokenDoc.data().token;

    if (!token) {
      return {
        success: false,
        reason: "EMPTY_TOKEN",
      };
    }

    await admin.messaging().send({
      token: token,

      notification: {
  title: type === "practice_invitation"
    ? `دعوة تدريب جديدة لـ ${childName} 🎮`
    : `طلب صداقة جديد لـ ${childName} 💜`,

  body: type === "practice_invitation"
    ? `${childName} لديه دعوة جديدة للتدرّب مع صديق في فصيح`
    : `${childName} لديه طلب صداقة جديد في فصيح`,
},

      data: {
        type: type,
        referenceId: String(referenceId),
        senderId: String(senderId),
        receiverId: String(receiverId),
      },

      android: {
        priority: "high",
      },
    });

    logger.info("Push notification sent", {
      receiverId,
      type,
    });

    return {
      success: true,
    };
  } catch (error) {
    logger.error("Push notification error", error);

    throw new HttpsError(
        "internal",
        "Failed to send push notification.",
    );
  }
});
exports.sendPushNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated.",
    );
  }

  const receiverId = request.data.receiverId;
  const type = request.data.type;
  const referenceId = request.data.referenceId || "";
  const senderId = request.data.senderId || "";

  if (!receiverId || !type) {
    throw new HttpsError(
        "invalid-argument",
        "receiverId and type are required.",
    );
  }

  const supportedTypes = [
    "friend_request",
    "practice_invitation",
  ];

  if (!supportedTypes.includes(type)) {
    throw new HttpsError(
        "invalid-argument",
        "Unsupported notification type.",
    );
  }

  try {
    const db = admin.firestore();

    // 1. Get receiver child information
    const childDoc = await db
        .collection("children")
        .doc(receiverId)
        .get();

    let childName = "طفلك";
    let parentId = null;

    if (childDoc.exists) {
      const childData = childDoc.data();

      childName =
          childData.nickname ||
          childData.firstName ||
          childData.name ||
          "طفلك";

      parentId = childData.parentId || null;
    }

    // 2. Collect all tokens that should receive this notification
    const tokens = new Set();

    // Keep the old child token as a fallback
    const childTokenDoc = await db
        .collection("child_fcm_tokens")
        .doc(receiverId)
        .get();

    if (childTokenDoc.exists) {
      const childToken = childTokenDoc.data().token;

      if (childToken) {
        tokens.add(childToken);
      }
    }

    // Add every device registered for this child's family
    if (parentId) {
      const familyDevices = await db
          .collection("parent_fcm_tokens")
          .doc(parentId)
          .collection("devices")
          .get();

      familyDevices.docs.forEach((doc) => {
        const token = doc.data().token;

        if (token) {
          tokens.add(token);
        }
      });
    }

    if (tokens.size === 0) {
      logger.warn("No FCM tokens found", {
        receiverId,
        parentId,
      });

      return {
        success: false,
        reason: "NO_TOKEN",
      };
    }

    // 3. Build notification
    const title = type === "practice_invitation"
      ? `دعوة تدريب جديدة لـ ${childName} 🎮`
      : `طلب صداقة جديد لـ ${childName} 💜`;

    const body = type === "practice_invitation"
      ? `${childName} لديه دعوة جديدة للتدرّب مع صديق في فصيح`
      : `${childName} لديه طلب صداقة جديد في فصيح`;

    // 4. Send to all unique registered devices
    const response = await admin.messaging().sendEachForMulticast({
      tokens: Array.from(tokens),

      notification: {
        title: title,
        body: body,
      },

      data: {
        type: String(type),
        referenceId: String(referenceId),
        senderId: String(senderId),
        receiverId: String(receiverId),
      },

      android: {
        priority: "high",
      },
    });

    logger.info("Push notifications sent", {
      receiverId,
      parentId,
      totalTokens: tokens.size,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    return {
      success: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    logger.error("Push notification error", error);

    throw new HttpsError(
        "internal",
        "Failed to send push notification.",
    );
  }
});

exports.cleanupOldNotifications = onSchedule(
    {
      schedule: "every day 00:00",
      timeZone: "Asia/Riyadh",
      region: "us-central1",
    },
    async () => {
      const db = admin.firestore();

      const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
      );

      const snapshot = await db
          .collection("notifications")
          .where("isRead", "==", true)
          .where("createdAt", "<=", sevenDaysAgo)
          .get();

      if (snapshot.empty) {
        logger.info("No old notifications to delete.");
        return;
      }

      const batch = db.batch();

      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      logger.info(
          `Deleted ${snapshot.size} old notifications.`,
      );
    },
);