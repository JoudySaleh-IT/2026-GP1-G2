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
    

    // Add every device registered for this child's family
    if (parentId) {
      const familyDevices = await db
          .collection("parent_fcm_tokens")
          .doc(parentId)
          .collection("devices")
          .get();

     familyDevices.docs.forEach((doc) => {
  const deviceData = doc.data();

  if (
    deviceData.activeMode === "child" &&
    deviceData.activeChildId === receiverId &&
    deviceData.token
  ) {
    tokens.add(deviceData.token);
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

exports.sendParentPushNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated.",
    );
  }

  const parentId = request.data.parentId;
  const childId = request.data.childId;
  const type = request.data.type;

  if (!parentId || !childId || !type) {
    throw new HttpsError(
        "invalid-argument",
        "parentId, childId and type are required.",
    );
  }

  if (type !== "new_friend") {
    throw new HttpsError(
        "invalid-argument",
        "Unsupported parent notification type.",
    );
  }

  try {
    const db = admin.firestore();

    // 1. Verify that this child really belongs to this parent.
    const childDoc = await db
        .collection("children")
        .doc(childId)
        .get();

    if (!childDoc.exists) {
      throw new HttpsError(
          "not-found",
          "Child not found.",
      );
    }

    const childData = childDoc.data();

    if (childData.parentId !== parentId) {
      throw new HttpsError(
          "permission-denied",
          "Child does not belong to this parent.",
      );
    }

    const childName =
        childData.nickname ||
        childData.firstName ||
        childData.name ||
        "طفلك";

    const gender =
        String(childData.gender || "").toLowerCase();

    // 2. Get all devices registered for this parent.
    const devicesSnapshot = await db
        .collection("parent_fcm_tokens")
        .doc(parentId)
        .collection("devices")
        .get();

    const tokens = new Set();

    // IMPORTANT:
    // Parent notifications are sent ONLY to devices
    // explicitly marked as being in parent mode.
    devicesSnapshot.docs.forEach((doc) => {
      const deviceData = doc.data();

      if (
        deviceData.activeMode === "parent" &&
        deviceData.token
      ) {
        tokens.add(deviceData.token);
      }
    });

    if (tokens.size === 0) {
      logger.info("No parent-mode devices available", {
        parentId,
        childId,
      });

      return {
        success: false,
        reason: "NO_PARENT_MODE_DEVICE",
      };
    }

    // 3. Build parent notification.
    const action =
        gender === "girl" ? "أضافت" : "أضاف";

    const title = "صديق جديد في فصيح 🌟";
    const body = `${childName} ${action} صديقًا جديدًا`;

    // 4. Send ONLY to parent-mode devices.
    const response = await admin.messaging().sendEachForMulticast({
      tokens: Array.from(tokens),

      notification: {
        title: title,
        body: body,
      },

      data: {
        type: "parent_new_friend",
        parentId: String(parentId),
        childId: String(childId),
      },

      android: {
        priority: "high",
      },
    });

    logger.info("Parent push notification sent", {
      parentId,
      childId,
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
    logger.error("Parent push notification error", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
        "internal",
        "Failed to send parent push notification.",
    );
  }
});

exports.syncFriendshipSiblingStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated.",
    );
  }

  const pairId = String(request.data.pairId || "").trim();

  if (!pairId) {
    throw new HttpsError(
        "invalid-argument",
        "pairId is required.",
    );
  }

  const db = admin.firestore();

  const friendshipRef = db
      .collection("friendships")
      .doc(pairId);

  const friendshipSnapshot =
      await friendshipRef.get();

  if (!friendshipSnapshot.exists) {
    throw new HttpsError(
        "not-found",
        "Friendship not found.",
    );
  }

  const friendshipData =
      friendshipSnapshot.data();

  const childA = friendshipData.childA;
  const childB = friendshipData.childB;

  if (!childA || !childB) {
    throw new HttpsError(
        "failed-precondition",
        "Invalid friendship.",
    );
  }

  const uid = request.auth.uid;

  const [childASnapshot, childBSnapshot, deviceLinkSnapshot] =
      await Promise.all([
        db.collection("children").doc(childA).get(),
        db.collection("children").doc(childB).get(),
        db.collection("child_device_links").doc(uid).get(),
      ]);

  if (!childASnapshot.exists || !childBSnapshot.exists) {
    throw new HttpsError(
        "not-found",
        "One or both children do not exist.",
    );
  }

  const childAData = childASnapshot.data();
  const childBData = childBSnapshot.data();

  const parentOwnsA =
      childAData.parentId === uid;

  const parentOwnsB =
      childBData.parentId === uid;

  const deviceChildId =
      deviceLinkSnapshot.exists
          ? deviceLinkSnapshot.data().childId
          : null;

  const deviceActsAsA =
      deviceChildId === childA;

  const deviceActsAsB =
      deviceChildId === childB;

  const canAccessFriendship =
      parentOwnsA ||
      parentOwnsB ||
      deviceActsAsA ||
      deviceActsAsB;

  if (!canAccessFriendship) {
    throw new HttpsError(
        "permission-denied",
        "User is not a participant in this friendship.",
    );
  }

  const parentA = childAData.parentId;
  const parentB = childBData.parentId;

  const isSibling =
      typeof parentA === "string" &&
      parentA.length > 0 &&
      parentA === parentB;

  await friendshipRef.update({
    isSibling: isSibling,
  });

  logger.info("Sibling status synchronized", {
    pairId,
    isSibling,
  });

  return {
    success: true,
    isSibling: isSibling,
  };
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