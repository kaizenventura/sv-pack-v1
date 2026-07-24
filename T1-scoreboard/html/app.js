const app = document.getElementById('app');
const pages = document.querySelectorAll('.page');
const navButtons = document.querySelectorAll('.nav-btn');
let currentData = {};

function switchPage(page) {
    navButtons.forEach(btn => {
        const active = btn.dataset.page === page;
        btn.classList.toggle('active', active);
        if (active) {
            document.getElementById('pageTitle').textContent = btn.dataset.title || btn.querySelector('strong')?.textContent || '';
            document.getElementById('pageDesc').textContent = btn.dataset.desc || btn.querySelector('small')?.textContent || '';
        }
    });
    pages.forEach(p => p.classList.toggle('active', p.id === `page-${page}`));
}

navButtons.forEach(btn => btn.addEventListener('click', () => switchPage(btn.dataset.page)));

const exclusiveItems = [
    { name: 'Edit Deathcam', icon: 'camera', command: 'exclucam' },
    { name: 'Edit Welcomer', icon: 'users', command: 'excluwc' },
    { name: 'Manage EUP', icon: 'shirt', command: 'myexclu' }
];

document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape') closeNui();
});

function closeNui() {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: '{}' });
}

function setText(id, text) {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
}

function icon(name) {
    return `<svg class="line-icon"><use href="#icon-${name}"></use></svg>`;
}

function formatNumber(num) {
    return Number(num || 0).toLocaleString('en-US');
}

function renderPlayers(players = []) {
    const el = document.getElementById('playersList');
    if (!players.length) return el.innerHTML = '<div class="empty">No players online.</div>';
    el.innerHTML = players.map(p => `
        <div class="player-row">
            <div class="avatar">${String(p.id).padStart(2, '0')}</div>
            <div>
                <h4>${escapeHtml(p.name)}</h4>
                <p>${escapeHtml(p.job || 'Unemployed')}</p>
            </div>
            <span class="ping">${escapeHtml(p.ping || 0)}ms</span>
        </div>
    `).join('');
}

function renderJobs(jobs = []) {
    const el = document.getElementById('jobsList');
    document.getElementById('jobsBadge').textContent = jobs.length;
    if (!jobs.length) return el.innerHTML = '<div class="empty">No jobs online.</div>';
    el.innerHTML = jobs.map(j => `
        <div class="info-card">
            <span class="job-count">${escapeHtml(j.count)}</span>
            <h4>${escapeHtml(j.label)}</h4>
            <p>${escapeHtml(j.name)}</p>
        </div>
    `).join('');
}

function renderCommands(commands = []) {
    const el = document.getElementById('commandsList');
    if (!commands.length) return el.innerHTML = '<div class="empty">No handbook commands yet.</div>';
    el.innerHTML = commands.map(c => `
        <div class="info-card">
            <code>${escapeHtml(c.command)}</code>
            <h4>${escapeHtml(c.title)}</h4>
            <p>${escapeHtml(c.desc)}</p>
        </div>
    `).join('');
}

function renderRules(rules = []) {
    const el = document.getElementById('rulesList');
    if (!rules.length) return el.innerHTML = '<div class="empty">No rules listed yet.</div>';
    el.innerHTML = rules.map((r, i) => `
        <div class="info-card">
            <code>Rule ${i + 1}</code>
            <h4>${escapeHtml(r.title)}</h4>
            <p>${escapeHtml(r.desc)}</p>
        </div>
    `).join('');
}

function runCommand(command) {
    app.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/runCommand`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ command })
    });
}

function renderExclusive() {
    const el = document.getElementById('exclusiveList');
    if (!el) return;
    el.innerHTML = exclusiveItems.map(item => `
        <button class="exclusive-card" onclick="runCommand('${escapeAttr(item.command)}')">
            ${icon(item.icon)}
            <span>${escapeHtml(item.name)}</span>
        </button>
    `).join('');
}

function renderAnnouncements(announcements = []) {
    const el = document.getElementById('announcementsList');
    if (!announcements.length) return el.innerHTML = '<div class="empty">No announcements yet.</div>';
    el.innerHTML = announcements.map(a => `
        <article class="announcement-card">
            <h4>${icon('bullhorn')} ${escapeHtml(a.title)}</h4>
            <p>${escapeHtml(a.message)}</p>
            ${a.image ? `<img class="announcement-image" src="${escapeAttr(a.image)}" onerror="this.remove()" />` : ''}
        </article>
    `).join('');
}

function render(data) {
    currentData = data || {};
    document.getElementById('logo').src = data.logo || '';
    setText('playerOnline', `${data.playerCount || 0}/${data.maxPlayers || 128}`);
    setText('playerId', data.playerId || 0);
    renderPlayers(data.players);
    renderJobs(data.jobs);
    renderCommands(data.commands);
    renderRules(data.rules);
    renderAnnouncements(data.announcements);
    renderExclusive();
}

function escapeHtml(str) {
    return String(str ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#039;','"':'&quot;'}[c]));
}

function escapeAttr(str) {
    return escapeHtml(str).replace(/`/g, '&#096;');
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') {
        app.classList.remove('hidden');
        switchPage('announcements');
        render(msg.data || {});
    }
    if (msg.action === 'close') app.classList.add('hidden');
    if (msg.action === 'announcements') {
        currentData.announcements = msg.announcements || [];
        renderAnnouncements(currentData.announcements);
    }
});
