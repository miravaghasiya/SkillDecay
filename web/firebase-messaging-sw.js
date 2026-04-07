importScripts(
  "https://www.gstatic.com/firebasejs/10.9.0/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.9.0/firebase-messaging-compat.js",
);

const firebaseConfig = {
  apiKey: "AIzaSyB92mPF6k9yP1m0FtR6gai1bJSFV7psB2c",
  authDomain: "micro-skill-decay-detector.firebaseapp.com",
  projectId: "micro-skill-decay-detector",
  storageBucket: "micro-skill-decay-detector.firebasestorage.app",
  messagingSenderId: "483787424425",
  appId: "1:483787424425:web:fbea8882e7473a73c09fb8",
  measurementId: "G-C4YXYFBG6K",
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message ",
    payload,
  );

  const notificationTitle = payload.notification
    ? payload.notification.title
    : "SkillDecay Alert";
  const notificationOptions = {
    body: payload.notification
      ? payload.notification.body
      : "You have a new message",
    icon: "icons/Icon-192.png",
    data: payload.data,
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions,
  );
});
