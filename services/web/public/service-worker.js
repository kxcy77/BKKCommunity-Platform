const CACHE_NAME = 'bkk-public-shell-v2';
const STATIC_ASSETS = [
  '/offline.html',
  '/manifest.webmanifest',
  '/assets/css/app.css',
  '/assets/js/app.js',
  '/assets/vendor/bootstrap/bootstrap.min.css',
  '/assets/vendor/bootstrap/bootstrap.bundle.min.js',
  '/assets/icons/bkk-180.png',
  '/assets/icons/bkk-192.png',
  '/assets/icons/bkk-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

const isPrivatePath = (pathname) => {
  if (pathname.startsWith('/api/') || pathname.startsWith('/admin/')) return true;

  return [
    '/actions.php',
    '/login.php',
    '/register.php',
    '/reset-password.php',
    '/new-password.php',
    '/profile.php'
  ].includes(pathname);
};

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin || isPrivatePath(url.pathname)) return;

  if (request.mode === 'navigate') {
    event.respondWith(fetch(request).catch(() => caches.match('/offline.html')));
    return;
  }

  if (STATIC_ASSETS.includes(url.pathname)) {
    event.respondWith(caches.match(request).then((cached) => cached || fetch(request)));
  }
});
