</main>
<footer class="site-footer">
    <div class="shell footer-grid">
        <section>
            <a class="brand brand-footer" href="<?= h(app_url('index.php')) ?>">
                <span class="brand-mark">BKK</span>
                <span class="brand-copy"><strong>Community</strong><small>Group</small></span>
            </a>
            <p>A clear, welcoming place for older community members to stay connected, active and informed.</p>
        </section>
        <section>
            <h2>Explore</h2>
            <ul class="footer-links">
                <li><a href="<?= h(app_url('about.php')) ?>">About BKK Community Group</a></li>
                <li><a href="<?= h(app_url('events.php')) ?>">Upcoming events</a></li>
                <li><a href="<?= h(app_url('discounts.php')) ?>">Senior discounts</a></li>
                <li><a href="<?= h(app_url('info.php')) ?>">Local information</a></li>
                <li><a href="<?= h(app_url('contact.php')) ?>">Contact the group</a></li>
                <li><a href="<?= h(app_url('download.php')) ?>">Download Android app</a></li>
            </ul>
        </section>
        <section>
            <h2>Get in touch</h2>
            <ul class="contact-list">
                <li><?= icon_svg('mail') ?><a href="<?= h(app_url('contact.php')) ?>">Send a message to BKK</a></li>
                <li><?= icon_svg('info') ?><span>Direct contact details will appear after BKK verifies them.</span></li>
            </ul>
        </section>
    </div>
    <div class="shell footer-bottom">
        <span>&copy; <span data-current-year><?= date('Y') ?></span> BKK Community Group</span>
        <span>Designed for clarity, dignity and accessibility.</span>
    </div>
</footer>
<script src="<?= h(app_url('assets/vendor/bootstrap/bootstrap.bundle.min.js')) ?>" defer></script>
<script src="<?= h(app_url('assets/js/app.js')) ?>" defer></script>
</body>
</html>

