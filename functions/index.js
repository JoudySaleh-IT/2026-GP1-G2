const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {
  onDocumentUpdated,
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");

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


const MILESTONE_LEVELS = [
  "beginner",
  "intermediate",
  "advanced",
];

const MILESTONE_LEVEL_NAMES = {
  beginner: "المبتدئ",
  intermediate: "المتوسط",
  advanced: "المتقدم",
};

const MILESTONE_LETTERS = ["ض", "س", "ص", "غ", "خ", "ق"];

function getMilestoneLevel(progress, letter, level) {
  return progress?.[letter]?.[level] || {};
}

function hasPassedListening(progress, letter, level) {
  return getMilestoneLevel(progress, letter, level).listeningPassed === true;
}

function hasCompletedLevel(progress, letter, level) {
  const data = getMilestoneLevel(progress, letter, level);

  return (
    data.listeningPassed === true &&
    data.pronunciationPassed === true
  );
}

function hasCompletedLetter(progress, letter) {
  return MILESTONE_LEVELS.every((level) =>
    hasCompletedLevel(progress, letter, level)
  );
}


async function sendMilestonePush({
  parentId,
  childId,
  mode,
  title,
  message,
  type,
  referenceId,
}) {
  if (!parentId) return;

  const db = admin.firestore();

  const devices = await db
    .collection("parent_fcm_tokens")
    .doc(parentId)
    .collection("devices")
    .get();

  const tokens = new Set();

  devices.docs.forEach((doc) => {
    const device = doc.data();

    const correctMode =
      mode === "parent"
        ? device.activeMode === "parent"
        : device.activeMode === "child" &&
          device.activeChildId === childId;

    if (correctMode && device.token) {
      tokens.add(device.token);
    }
  });


  // Fallback: use the child's directly registered FCM token.
  if (mode === "child" && tokens.size === 0) {
    const childTokenDoc = await db
      .collection("child_fcm_tokens")
      .doc(childId)
      .get();

    if (childTokenDoc.exists) {
      const childToken = childTokenDoc.data()?.token;

      if (typeof childToken === "string" && childToken.length > 0) {
        tokens.add(childToken);
        logger.info("Child fallback FCM token found", {childId});
      }
    }
  }

  if (tokens.size === 0) {
    logger.info("No milestone push tokens", {
      childId,
      mode,
    });
    return;
  }

  const response = await admin.messaging().sendEachForMulticast({
    tokens: Array.from(tokens),
    notification: {
      title,
      body: message,
    },
    data: {
      type: String(type),
      referenceId: String(referenceId),
      childId: String(childId),
      receiverId: String(childId),
    },
    android: {
      priority: "high",
    },
  });

  logger.info("Milestone push result", {
    childId,
    mode,
    successCount: response.successCount,
    failureCount: response.failureCount,
  });
}




exports.notifyFaseehProgress = onCall(
  {region: "us-central1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
          "unauthenticated",
          "Authentication is required.",
      );
    }

    const childId = request.data?.childId;
    const letter = request.data?.letter;
    const level = request.data?.level;

    if (
      typeof childId !== "string" ||
      !childId.trim() ||
      !MILESTONE_LETTERS.includes(letter) ||
      !MILESTONE_LEVELS.includes(level)
    ) {
      throw new HttpsError(
          "invalid-argument",
          "Invalid childId, letter, or level.",
      );
    }

    const db = admin.firestore();
    const childDoc = await db.collection("children").doc(childId).get();

    if (!childDoc.exists) {
      throw new HttpsError("not-found", "Child not found.");
    }

    const child = childDoc.data();
    const parentId = child.parentId;

    if (!parentId || request.auth.uid !== parentId) {
      throw new HttpsError(
          "permission-denied",
          "Not authorized for this child.",
      );
    }

    const newProgress = child.exerciseProgress || {};

    const milestones = [];


    const levelName = MILESTONE_LEVEL_NAMES[level];

    // 1. Listening completed - child only
    if (hasPassedListening(newProgress, letter, level)) {
      milestones.push({
        id: `listening_${letter}_${level}`,
        type: "listening_completed",
        childTitle: "أحسنت! 🎧",
        childMessage:
          `أكملت تمارين الاستماع لحرف ${letter} في المستوى ${levelName}! 🌟`,
      });
    }

    // 2. Level completed - child and parent
    if (hasCompletedLevel(newProgress, letter, level)) {
      milestones.push({
        id: `level_${letter}_${level}`,
        type: "level_completed",
        childTitle: "مبروك! 🎉",
        childMessage:
          `أكملت المستوى ${levelName} لحرف ${letter}!`,
        parentTitle: "إنجاز جديد لطفلك! 🌟",
        parentMessage:
          `أكمل طفلك المستوى ${levelName} لحرف ${letter} في مهارتي الاستماع والنطق!`,
      });
    }

    // 3. Letter completed - child and parent
    if (hasCompletedLetter(newProgress, letter)) {
      milestones.push({
        id: `letter_${letter}`,
        type: "letter_completed",
        childTitle: "إنجاز رائع! 🏆",
        childMessage:
          `أتقنت حرف ${letter} بجميع مستوياته!`,
        parentTitle: "إنجاز جديد لطفلك! 🏆",
        parentMessage:
          `أكمل طفلك جميع مستويات حرف ${letter} بنجاح!`,
      });
    }

  
    if (milestones.length === 0) {
      return {success: true, count: 0};
    }

    for (const milestone of milestones) {

      const achievementRef = db
        .collection("children")
        .doc(childId)
        .collection("milestone_achievements")
        .doc(milestone.id);

      const notificationId =
        `milestone_${childId}_${milestone.id}`;

      const childNotificationRef = db
        .collection("notifications")
        .doc(notificationId);

      const parentNotificationRef = parentId && milestone.parentMessage
        ? db.collection("parent_notifications").doc(notificationId)
        : null;

      const created = await db.runTransaction(async (transaction) => {
        const existingAchievement =
          await transaction.get(achievementRef);

        if (existingAchievement.exists) {
          return false;
        }

        const now = Date.now();

        const childExpiresAt =
          admin.firestore.Timestamp.fromMillis(
            now + 48 * 60 * 60 * 1000
          );

        const parentExpiresAt =
          admin.firestore.Timestamp.fromMillis(
            now + 30 * 24 * 60 * 60 * 1000
          );

        transaction.create(achievementRef, {
          type: milestone.type,
          letter: milestone.id.startsWith("letter_")
            ? milestone.id.substring(7)
            : null,
          achievedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.create(childNotificationRef, {
          receiverId: childId,
          senderId: "system",
          type: milestone.type,
          referenceId: milestone.id,
          title: milestone.childTitle,
          message: milestone.childMessage,
          isRead: false,
          createdAt:
            admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: childExpiresAt,
        });

        if (parentNotificationRef) {
          transaction.create(parentNotificationRef, {
            parentId,
            childId,
            type: milestone.type,
            referenceId: milestone.id,
            title: milestone.parentTitle,
            message: milestone.parentMessage,
            isRead: false,
            createdAt:
              admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: parentExpiresAt,
          });
        }

        return true;
      });

      if (!created) continue;

      try {
        await sendMilestonePush({
          parentId,
          childId,
          mode: "child",
          title: milestone.childTitle,
          message: milestone.childMessage,
          type: milestone.type,
          referenceId: milestone.id,
        });
      } catch (error) {
        logger.error("Child milestone push failed", error);
      }

      if (milestone.parentMessage && parentId) {
        try {
          await sendMilestonePush({
            parentId,
            childId,
            mode: "parent",
            title: milestone.parentTitle,
            message: milestone.parentMessage,
            type: milestone.type,
            referenceId: milestone.id,
          });
        } catch (error) {
          logger.error("Parent milestone push failed", error);
        }
      }
    }

    logger.info("Faseeh milestones processed", {
      childId,
      count: milestones.length,
    });

    return {
      success: true,
      count: milestones.length,
    };

  }
);

// =============================================================
// FASEEH CERTIFICATE ACHIEVEMENT NOTIFICATIONS
// =============================================================


exports.notifyFaseehCertificate = onCall(
  {region: "us-central1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
          "unauthenticated",
          "Authentication is required.",
      );
    }

    const childId = request.data?.childId;

    if (typeof childId !== "string" || !childId.trim()) {
      throw new HttpsError(
          "invalid-argument",
          "A valid childId is required.",
      );
    }

    const db = admin.firestore();
    const childRef = db.collection("children").doc(childId);
    const childDoc = await childRef.get();

    if (!childDoc.exists) {
      throw new HttpsError("not-found", "Child not found.");
    }

    const child = childDoc.data();
    const parentId = child.parentId;

    // IMPORTANT:
    // This assumes parentId equals the Firebase Auth UID.
    if (!parentId || request.auth.uid !== parentId) {
      throw new HttpsError(
          "permission-denied",
          "Not authorized for this child.",
      );
    }

    const letterScores = child.letterScores || {};
    const progress = child.exerciseProgress || {};

    const requiredLetters = Object.entries(letterScores)
        .filter(([, score]) =>
          typeof score === "number" && score < 80)
        .map(([letter]) => letter);

    if (requiredLetters.length === 0) {
      throw new HttpsError(
          "failed-precondition",
          "No required exercises found.",
      );
    }

    for (const letter of requiredLetters) {
      const advanced = progress[letter]?.advanced;

      if (
        advanced?.listeningPassed !== true ||
        advanced?.pronunciationPassed !== true
      ) {
        throw new HttpsError(
            "failed-precondition",
            "Journey is not completed.",
        );
      }
    }

    const certificateRef = childRef
        .collection("certificates")
        .doc("completion");

    const certificateDoc = await certificateRef.get();

    if (!certificateDoc.exists) {
      throw new HttpsError(
          "failed-precondition",
          "Certificate has not been issued.",
      );
    }

    const type = "journey_completed";
    const referenceId = "certificate_completion";
    const notificationId = `milestone_${childId}_${referenceId}`;

    const childTitle = "شهادة فصيح 🎓";
    const childMessage = "🎓 حصلت على شهادة فصيح!";
    const parentTitle = "شهادة فصيح 🎓";
    const parentMessage =
      "🎓 أكمل طفلك رحلة فصيح وحصل على شهادته!";

    const achievementRef = childRef
        .collection("milestone_achievements")
        .doc(referenceId);

    const childNotificationRef = db
        .collection("notifications")
        .doc(notificationId);

    const parentNotificationRef = db
        .collection("parent_notifications")
        .doc(notificationId);

    const created = await db.runTransaction(async (transaction) => {
      const existing = await transaction.get(achievementRef);

      if (existing.exists) return false;

      const now = Date.now();

      transaction.create(achievementRef, {
        type,
        achievedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      transaction.create(childNotificationRef, {
        receiverId: childId,
        senderId: "system",
        type,
        referenceId,
        title: childTitle,
        message: childMessage,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(
            now + 48 * 60 * 60 * 1000),
      });

      transaction.create(parentNotificationRef, {
        parentId,
        childId,
        type,
        referenceId,
        title: parentTitle,
        message: parentMessage,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(
            now + 30 * 24 * 60 * 60 * 1000),
      });

      return true;
    });

    if (!created) {
      return {success: true, alreadyNotified: true};
    }

    try {
      await sendMilestonePush({
        parentId,
        childId,
        mode: "child",
        title: childTitle,
        message: childMessage,
        type,
        referenceId,
      });
    } catch (error) {
      logger.error("Certificate child push failed", error);
    }

    try {
      await sendMilestonePush({
        parentId,
        childId,
        mode: "parent",
        title: parentTitle,
        message: parentMessage,
        type,
        referenceId,
      });
    } catch (error) {
      logger.error("Certificate parent push failed", error);
    }

    return {success: true, alreadyNotified: false};
  },
);

// =============================================================
// FASEEH STREAK ACHIEVEMENT NOTIFICATIONS
// =============================================================


 // =============================================================
 // FASEEH STREAK ACHIEVEMENT NOTIFICATIONS (CALLABLE)
 // =============================================================

exports.notifyFaseehStreak = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const childId = request.data?.childId;

  if (typeof childId !== "string" || !childId.trim()) {
    throw new HttpsError("invalid-argument", "Valid childId is required.");
  }

  const parentId = request.auth.uid;
  const db = admin.firestore();

  const childRef = db.collection("children").doc(childId);
  const childSnapshot = await childRef.get();

  if (!childSnapshot.exists) {
    throw new HttpsError("not-found", "Child not found.");
  }

  const childData = childSnapshot.data();

  if (childData.parentId !== parentId) {
    throw new HttpsError("permission-denied", "Not authorized for this child.");
  }

  const streak = Number(childData.streak || 0);

  if (streak < 3 || streak % 3 !== 0) {
    return {success: true, notified: false, reason: "not_milestone"};
  }

  // Verify that the streak was updated for today's practice.
  const today = new Date(
    Date.now() + 3 * 60 * 60 * 1000
  ).toISOString().slice(0, 10);

  if (childData.lastPracticeDay !== today) {
    return {success: true, notified: false, reason: "not_practiced_today"};
  }

  const referenceId = `streak_${streak}`;
  const notificationId = `milestone_${childId}_${referenceId}`;

  const achievementRef = childRef
    .collection("milestone_achievements")
    .doc(referenceId);

  const childNotificationRef = db
    .collection("notifications")
    .doc(notificationId);

  const parentNotificationRef = db
    .collection("parent_notifications")
    .doc(notificationId);

  const childTitle = "سلسلة إنجازات رائعة! 🔥";
  const childMessage =
    `أحسنت! واصلت التدريب ${streak} أيام متتالية في فصيح! 🌟`;

  const parentTitle = "طفلك يحافظ على تقدمه! 🌟";
  const parentMessage =
    `واصل طفلك التدريب لمدة ${streak} أيام متتالية في فصيح!`;

  const created = await db.runTransaction(async (transaction) => {
    const currentChild = await transaction.get(childRef);
    const existing = await transaction.get(achievementRef);

    if (!currentChild.exists) {
      throw new HttpsError("not-found", "Child not found.");
    }

    const currentData = currentChild.data();

    if (currentData.parentId !== parentId) {
      throw new HttpsError("permission-denied", "Not authorized.");
    }

    const currentStreak = Number(currentData.streak || 0);

    if (
      existing.exists ||
      currentStreak !== streak ||
      currentStreak < 3 ||
      currentStreak % 3 !== 0 ||
      currentData.lastPracticeDay !== today
    ) {
      return false;
    }

    const now = Date.now();

    transaction.create(achievementRef, {
      type: "streak_completed",
      streak,
      achievedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.create(childNotificationRef, {
      receiverId: childId,
      senderId: "system",
      type: "streak_completed",
      referenceId,
      title: childTitle,
      message: childMessage,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(
        now + 48 * 60 * 60 * 1000
      ),
    });

    transaction.create(parentNotificationRef, {
      parentId,
      childId,
      type: "streak_completed",
      referenceId,
      title: parentTitle,
      message: parentMessage,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(
        now + 30 * 24 * 60 * 60 * 1000
      ),
    });

    return true;
  });

  if (!created) {
    return {success: true, notified: false, reason: "already_sent_or_changed"};
  }

  try {
    await sendMilestonePush({
      parentId,
      childId,
      mode: "child",
      title: childTitle,
      message: childMessage,
      type: "streak_completed",
      referenceId,
    });
  } catch (error) {
    logger.error("Streak child push failed", error);
  }

  try {
    await sendMilestonePush({
      parentId,
      childId,
      mode: "parent",
      title: parentTitle,
      message: parentMessage,
      type: "streak_completed",
      referenceId,
    });
  } catch (error) {
    logger.error("Streak parent push failed", error);
  }

  return {success: true, notified: true, streak};
});



 // =============================================================
 // FASEEH DAILY PRACTICE REMINDER
 // Every day at 2:00 AM Saudi Arabia time
 // =============================================================

exports.sendDailyPracticeReminder = onSchedule(
  {
schedule: "0 12 * * *",
    timeZone: "Asia/Riyadh",
    region: "us-central1",
  },
  async () => {
    const db = admin.firestore();

    // Saudi calendar dates (UTC+3).
    const saudiNow = new Date(Date.now() + 3 * 60 * 60 * 1000);
    const today = saudiNow.toISOString().slice(0, 10);

    const yesterdayDate = new Date(
      saudiNow.getTime() - 24 * 60 * 60 * 1000
    );
    const yesterday = yesterdayDate.toISOString().slice(0, 10);

    // Only children who practiced yesterday.
    const childrenSnapshot = await db
      .collection("children")
      .where("lastPracticeDay", "==", yesterday)
      .get();

    if (childrenSnapshot.empty) {
      logger.info("No children eligible for practice reminders.", {
        today,
        yesterday,
      });
      return;
    }

    let remindersCreated = 0;

    for (const childDoc of childrenSnapshot.docs) {
      const childId = childDoc.id;
      const child = childDoc.data();
      const parentId = child.parentId;

      if (!parentId) continue;

      const reminderId = `practice_reminder_${childId}_${today}`;

      const notificationRef = db
        .collection("notifications")
        .doc(reminderId);

      const title = "فصيح ينتظرك! 🌟";
      const message =
        "لا تنسَ تدريبك اليوم! واصل رحلتك في فصيح وحافظ على سلسلة إنجازاتك 🔥";

      try {
        // Transaction prevents duplicate reminders.
        const created = await db.runTransaction(async (transaction) => {
          const latestChild = await transaction.get(childDoc.ref);
          const existing = await transaction.get(notificationRef);

          if (!latestChild.exists || existing.exists) {
            return false;
          }

          // Recheck the child's practice day.
          if (latestChild.data().lastPracticeDay !== yesterday) {
            return false;
          }

          transaction.create(notificationRef, {
            receiverId: childId,
            senderId: "system",
            type: "practice_reminder",
            referenceId: reminderId,
            title,
            message,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromMillis(
              Date.now() + 48 * 60 * 60 * 1000
            ),
          });

          return true;
        });

if (!created) continue;
        remindersCreated++;

        try {
          await sendMilestonePush({
            parentId,
            childId,
            mode: "child",
            title,
            message,
            type: "practice_reminder",
            referenceId: reminderId,
          });
        } catch (error) {
          logger.error("Practice reminder push failed", {
            childId,
            error,
          });
        }
      } catch (error) {
        logger.error("Failed to create practice reminder", {
          childId,
          error,
        });
      }
    }

    logger.info("Daily practice reminders completed", {
      today,
      yesterday,
      remindersCreated,
    });
  }
);


// =============================================================
// FASEEH STREAK REMINDER
// Every day at 7:00 PM Saudi Arabia time
// =============================================================

exports.sendStreakReminder = onSchedule(
  {
    schedule: "0 19 * * *",
    timeZone: "Asia/Riyadh",
    region: "us-central1",
  },
  async () => {
    const db = admin.firestore();

    const saudiNow = new Date(Date.now() + 3 * 60 * 60 * 1000);
    const today = saudiNow.toISOString().slice(0, 10);
    const yesterday = new Date(
      saudiNow.getTime() - 24 * 60 * 60 * 1000
    ).toISOString().slice(0, 10);

    const childrenSnapshot = await db
      .collection("children")
      .where("lastPracticeDay", "==", yesterday)
      .get();

    let remindersCreated = 0;

    for (const childDoc of childrenSnapshot.docs) {
      const childId = childDoc.id;
      const child = childDoc.data();
      const parentId = child.parentId;

      if (!parentId || Number(child.streak || 0) < 2) {
        continue;
      }

      const reminderId = `streak_reminder_${childId}_${today}`;
      const notificationRef = db
        .collection("notifications")
        .doc(reminderId);

      const title = "لا تخسر سلسلتك! 🔥";
      const message =
        `عندك سلسلة تدريب مستمرة لمدة ${child.streak} أيام! ` +
        "تدرب اليوم عشان تحافظ عليها! 🌟";

      try {
        const created = await db.runTransaction(async (transaction) => {
          const latestChild = await transaction.get(childDoc.ref);
          const existing = await transaction.get(notificationRef);

          if (!latestChild.exists || existing.exists) {
            return false;
          }

          const latestData = latestChild.data();

          if (
            latestData.lastPracticeDay !== yesterday ||
            Number(latestData.streak || 0) < 2 ||
            !latestData.parentId
          ) {
            return false;
          }

          transaction.create(notificationRef, {
            receiverId: childId,
            senderId: "system",
            type: "streak_reminder",
            referenceId: reminderId,
            title,
            message,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromMillis(
              Date.now() + 48 * 60 * 60 * 1000
            ),
          });

          return true;
        });

        if (!created) continue;

        remindersCreated++;

        try {
          await sendMilestonePush({
            parentId,
            childId,
            mode: "child",
            title,
            message,
            type: "streak_reminder",
            referenceId: reminderId,
          });
        } catch (error) {
          logger.error("Streak reminder push failed", {
            childId,
            error,
          });
        }
      } catch (error) {
        logger.error("Failed to create streak reminder", {
          childId,
          error,
        });
      }
    }

    logger.info("Streak reminders completed", {
      today,
      yesterday,
      remindersCreated,
    });
  }
);