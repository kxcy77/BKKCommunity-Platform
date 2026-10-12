<?php

declare(strict_types=1);

require dirname(__DIR__) . '/app/bootstrap.php';

$pageTitle = 'Senior discounts';
$activeNav = 'discounts';
$allDiscounts = all_discounts();
$categories = array_values(array_unique(array_column($allDiscounts, 'category')));
sort($categories);
$selectedCategory = trim((string) ($_GET['category'] ?? 'All'));
$discounts = $selectedCategory === 'All'
    ? $allDiscounts
    : array_values(array_filter($allDiscounts, fn (array $discount): bool => $discount['category'] === $selectedCategory));

require __DIR__ . '/partials/header.php';
?>
<section class="page-hero">
    <div class="shell">
        <p class="eyebrow eyebrow-light">Spend wisely</p>
        <h1>Senior discounts and savings</h1>
        <p>Compare offers by category, check eligibility and read the claim instructions before visiting a provider.</p>
    </div>
</section>
<section class="section section-gold">
    <div class="shell">
        <?php if (array_filter($discounts, static fn (array $discount): bool => !empty($discount['is_demo']))): ?>
            <div class="flash flash-info discount-warning" role="note">
                <?= icon_svg('info') ?>
                <span><strong>Demonstration entries are not real offers.</strong> Do not try to claim them or travel to a provider based on these examples. BKK-approved offers will be shown separately when available.</span>
            </div>
        <?php endif; ?>
        <nav class="filter-bar" aria-label="Filter discounts by category">
            <a class="filter-pill" href="<?= h(app_url('discounts.php')) ?>" <?= $selectedCategory === 'All' ? 'aria-current="true"' : '' ?>>All</a>
            <?php foreach ($categories as $category): ?>
                <a class="filter-pill" href="<?= h(app_url('discounts.php?category=' . rawurlencode($category))) ?>" <?= $selectedCategory === $category ? 'aria-current="true"' : '' ?>><?= h($category) ?></a>
            <?php endforeach; ?>
        </nav>
        <?php if (!$discounts): ?>
            <div class="empty-state"><h2>No discounts found</h2><p>Choose another category or view all discounts.</p></div>
        <?php else: ?>
            <div class="card-grid">
                <?php foreach ($discounts as $discount): ?>
                    <article class="content-card tone-<?= h($discount['tone']) ?>">
                        <header class="content-card-header">
                            <h2><?= h($discount['store_name']) ?></h2>
                            <span class="category-badge"><?= h($discount['category']) ?></span>
                        </header>
                        <div class="content-card-body">
                            <?php if (!empty($discount['is_demo'])): ?><p><strong>Demonstration only — not a valid offer.</strong></p><?php endif; ?>
                            <p class="deal"><?= h($discount['deal']) ?></p>
                            <dl class="detail-list">
                                <div><dt>Who qualifies</dt><dd><?= h($discount['eligibility']) ?></dd></div>
                                <?php if (empty($discount['is_demo'])): ?><div><dt>How to claim</dt><dd><?= h($discount['claim_instructions']) ?></dd></div><?php endif; ?>
                            </dl>
                            <?php if (empty($discount['is_demo'])): ?><a class="button button-outline" href="<?= h(app_url('contact.php?subject=' . rawurlencode('Discount enquiry: ' . $discount['store_name']))) ?>">Ask for help</a><?php endif; ?>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</section>
<?php require __DIR__ . '/partials/footer.php'; ?>

