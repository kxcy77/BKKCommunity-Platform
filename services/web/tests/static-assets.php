<?php
declare(strict_types=1);

// Also accepts a public deployment URL: compare served files with this checkout.
// No login or database writes are performed.
$publicRoot = dirname(__DIR__) . '/public';
$worker = file_get_contents($publicRoot . '/service-worker.js');
if ($worker === false || !preg_match('/const STATIC_ASSETS = \[(.*?)\];/s', $worker, $list)) {
    fwrite(STDERR, "FAIL public asset manifest missing\n");
    exit(1);
}
preg_match_all("/'([^']+)'/", $list[1], $paths);
if (count($paths[1]) < 9) {
    fwrite(STDERR, "FAIL public asset manifest unexpectedly incomplete\n");
    exit(1);
}
$pinned = [
    '/assets/vendor/bootstrap/bootstrap.min.css' => 'd85327d99c7a3ee1f9b5d0500d1370acea3ad2db39c163c2f51f232baedbdede',
    '/assets/vendor/bootstrap/bootstrap.bundle.min.js' => 'e4fd49181388c48ec5040bd3fe66f57c29c8e67fcd8502b3354b96ec7ab47cc7',
];
if (array_diff(array_keys($pinned), $paths[1])) {
    fwrite(STDERR, "FAIL Bootstrap assets missing from public shell manifest\n");
    exit(1);
}
$base = isset($argv[1]) ? rtrim($argv[1], '/') : null;
if ($base !== null && !preg_match('~^https?://[^/]+(?:/[^?#]*)?$~', $base)) {
    fwrite(STDERR, "FAIL provide an HTTP(S) deployment base URL\n");
    exit(1);
}
$context = stream_context_create(['http' => [
    'timeout' => 15, 'follow_location' => 0, 'ignore_errors' => true,
    'header' => "User-Agent: BKK-Static-Asset-Verification/1.0\r\n",
]]);
foreach ($paths[1] as $path) {
    $file = $publicRoot . $path;
    if (str_contains($path, '..') || !is_file($file) || filesize($file) === 0) {
        fwrite(STDERR, "FAIL missing or empty static asset: {$path}\n");
        exit(1);
    }
    $expected = hash_file('sha256', $file);
    if (isset($pinned[$path]) && $expected !== $pinned[$path]) {
        fwrite(STDERR, "FAIL Bootstrap 5.3.8 integrity: {$path}\n");
        exit(1);
    }
    if ($base !== null) {
        $http_response_header = [];
        $body = @file_get_contents($base . $path, false, $context);
        $headers = implode("\n", $http_response_header);
        if ($body === false || !preg_match('#^HTTP/\S+ 200\b#', $headers)
            || hash('sha256', $body) !== $expected) {
            fwrite(STDERR, "FAIL served static asset status/content: {$path}\n");
            exit(1);
        }
        if (str_ends_with($path, '.css') && !preg_match('/content-type:\s*text\/css\b/i', $headers)) {
            fwrite(STDERR, "FAIL stylesheet MIME type: {$path}\n");
            exit(1);
        }
        if (str_ends_with($path, '.js') && !preg_match('/content-type:\s*(?:application|text)\/javascript\b/i', $headers)) {
            fwrite(STDERR, "FAIL script MIME type: {$path}\n");
            exit(1);
        }
    }
    echo 'PASS ' . ($base !== null ? 'served ' : 'packaged ') . $path . "\n";
}
foreach (['LICENSE', 'bootstrap.min.css.map', 'bootstrap.bundle.min.js.map'] as $name) {
    if (!is_file($publicRoot . '/assets/vendor/bootstrap/' . $name)) {
        fwrite(STDERR, "FAIL missing Bootstrap distribution file: {$name}\n");
        exit(1);
    }
}
echo "PASS pinned Bootstrap integrity, licence and source maps\n";
