(() => {
  const toggle = document.querySelector('[data-nav-toggle]');
  const navigation = document.querySelector('[data-navigation]');

  if (toggle && navigation) {
    toggle.addEventListener('click', () => {
      const open = toggle.getAttribute('aria-expanded') === 'true';
      toggle.setAttribute('aria-expanded', String(!open));
      toggle.setAttribute('aria-label', open ? 'Open navigation menu' : 'Close navigation menu');
      navigation.classList.toggle('is-open', !open);
      document.body.classList.toggle('nav-open', !open);
    });

    navigation.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => {
        toggle.setAttribute('aria-expanded', 'false');
        toggle.setAttribute('aria-label', 'Open navigation menu');
        navigation.classList.remove('is-open');
        document.body.classList.remove('nav-open');
      });
    });

    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        toggle.setAttribute('aria-expanded', 'false');
        toggle.setAttribute('aria-label', 'Open navigation menu');
        navigation.classList.remove('is-open');
        document.body.classList.remove('nav-open');
        toggle.focus();
      }
    });
  }

  document.querySelectorAll('[data-password-toggle]').forEach((button) => {
    button.addEventListener('click', () => {
      const input = document.getElementById(button.dataset.passwordToggle);
      if (!input) return;
      const revealing = input.type === 'password';
      input.type = revealing ? 'text' : 'password';
      button.textContent = revealing ? 'Hide' : 'Show';
      button.setAttribute('aria-pressed', String(revealing));
    });
  });

  document.querySelectorAll('[data-confirm]').forEach((element) => {
    element.addEventListener('click', (event) => {
      if (!window.confirm(element.dataset.confirm || 'Are you sure?')) {
        event.preventDefault();
      }
    });
  });

  const directory = document.getElementById('registered-users-results');
  if (directory) {
    const status = document.getElementById('user-directory-status');
    const refreshButton = document.getElementById('refresh-user-directory');
    let checking = false;
    let sessionExpired = false;
    const refreshDirectory = async (manual = false) => {
      if (checking || sessionExpired || document.hidden) return;
      // Do not remove keyboard focus or interrupt someone editing their filters.
      if (!manual && (document.activeElement?.matches('input, select, textarea') || directory.contains(document.activeElement))) return;
      checking = true;
      refreshButton.disabled = true;
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 15000);
      try {
        const response = await fetch(window.location.href, {
          credentials: 'same-origin', cache: 'no-store', signal: controller.signal,
          headers: { 'X-BKK-Directory-Poll': manual ? '0' : '1' }
        });
        if (response.redirected || response.status === 401 || response.status === 403) {
          sessionExpired = true;
          status.textContent = 'Your administrator session ended. Sign in again to check registrations.';
          return;
        }
        if (!response.ok) throw new Error('Directory request failed');
        const updated = new DOMParser().parseFromString(await response.text(), 'text/html');
        const results = updated.getElementById('registered-users-results');
        const count = updated.getElementById('registered-users-count');
        if (!results || !count) throw new Error('Directory response was incomplete');
        const changed = directory.innerHTML !== results.innerHTML;
        if (changed) {
          const scrollLeft = directory.querySelector('.table-wrap')?.scrollLeft || 0;
          directory.replaceChildren(...Array.from(results.childNodes, (node) => document.importNode(node, true)));
          const table = directory.querySelector('.table-wrap');
          if (table) table.scrollLeft = scrollLeft;
        }
        document.getElementById('registered-users-count').textContent = count.textContent;
        status.textContent = `${changed ? 'Registration list updated. ' : ''}Last checked ${new Date().toLocaleTimeString()}. Checks every 10 seconds. Search and platform filters still apply.`;
      } catch (error) {
        status.textContent = 'Could not check for new registrations. Showing the saved list. Try Refresh now.';
      } finally {
        clearTimeout(timeout);
        checking = false;
        refreshButton.disabled = sessionExpired;
      }
    };
    refreshButton.addEventListener('click', () => refreshDirectory(true));
    setInterval(() => refreshDirectory(), 10000);
    document.addEventListener('visibilitychange', () => { if (!document.hidden) refreshDirectory(); });
    window.addEventListener('online', () => refreshDirectory());
    // Browsers can restore an older page from their back/forward cache.
    window.addEventListener('pageshow', () => refreshDirectory());
  }

  if ('serviceWorker' in navigator && window.isSecureContext) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/service-worker.js').catch(() => {
        // Installation is optional. The website remains fully usable when the
        // browser blocks service workers or registration fails.
      });
    });
  }
})();
