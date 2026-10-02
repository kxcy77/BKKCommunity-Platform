# Bootstrap 5.3.8 distribution

These unmodified browser assets are intentionally tracked in Git. They are not the generated Composer `services/web/vendor` directory, which remains ignored.

Source: https://github.com/twbs/bootstrap/tree/v5.3.8
Pinned upstream commit: `25aa8cc0b32f0d1a54be575347e6d84b70b1acd7`.
The CSS, JavaScript bundle, source maps and MIT licence were downloaded from that commit. The bundle includes Popper; no runtime CDN dependency is introduced.

`php services/web/tests/static-assets.php` checks the packaged public shell and pinned CSS/JS hashes. Append a deployment base URL to compare actual HTTP responses, MIME types and content against this checkout. The smoke suite and production verification workflow run this check.

For an intentional Bootstrap upgrade, obtain the official distribution and licence, review upstream changes, update the pinned hashes and this source record, increment the service-worker cache name, and verify locally and in production.
