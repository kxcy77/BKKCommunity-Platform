<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/app/bootstrap.php';
if (!in_array($_SERVER['REQUEST_METHOD'] ?? 'GET', ['GET', 'HEAD'], true)) {
    http_response_code(405);
    header('Allow: GET, HEAD');
    exit('Method not allowed.');
}
$download = require dirname(__DIR__) . '/app/android_download.php';
header('Cache-Control: no-store');
header('Referrer-Policy: no-referrer');
header('Location: ' . $download['url'], true, 302);
exit;
