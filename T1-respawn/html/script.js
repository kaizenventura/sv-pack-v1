const app = document.getElementById('app');
const locationsEl = document.getElementById('locations');
const respawnBtn = document.getElementById('respawn');
const minimizeBtn = document.getElementById('minimize');
const stuckBtn = document.getElementById('stuck');
const recapBtn = document.getElementById('recap');
const changeBtn = document.getElementById('change');
const textUI = document.getElementById('death-textui');
const textKey = document.getElementById('text-key');
const textLabel = document.getElementById('text-label');
const textTime = document.getElementById('text-time');

let locations = [];
let selected = 1;
let timer = 30;
let interval = null;
let ready = false;
let timerStarted = false;
let choosingLocation = true;

const post = (name, data = {}) => fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
});

function icon(id, classes = 'w-4 h-4 mr-2 icon-stroke') {
    return `<svg class="${classes}"><use href="#${id}"/></svg>`;
}

function renderLocations() {
    const list = choosingLocation ? locations : locations.filter((_, idx) => idx + 1 === selected);

    locationsEl.classList.toggle('selected-only', !choosingLocation);
    changeBtn.classList.toggle('hidden', choosingLocation);

    locationsEl.innerHTML = list.map((loc) => {
        const index = locations.indexOf(loc) + 1;
        const img = loc.image || 'logo.png';
        const active = selected === index;
        return `
            <button class="loc ${active ? 'loc-active' : ''}" data-index="${index}">
                <div class="loc-row">
                    <img class="loc-img" src="${img}" onerror="this.src='logo.png'">
                    <div class="loc-info">
                        <div class="loc-name">
                            ${icon('i-pin', 'loc-pin icon-stroke')}
                            <span>${loc.label || 'Spawn'}</span>
                        </div>
                        <p class="loc-desc">${loc.description || 'Spawn Location'}</p>
                    </div>
                </div>
            </button>`;
    }).join('');

    document.querySelectorAll('.loc').forEach(el => {
        el.addEventListener('click', () => {
            selected = Number(el.dataset.index);
            choosingLocation = false;
            renderLocations();
            post('selectLocation', { index: selected });
        });
    });
}

function formatTime(seconds) {
    const total = Math.max(0, Number(seconds) || 0);
    const mins = Math.floor(total / 60);
    const secs = total % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function updateTextTimer() {
    if (textTime) textTime.textContent = formatTime(timer);
}

function setRespawnText() {
    if (ready) {
        respawnBtn.classList.add('respawn-ready');
        respawnBtn.classList.remove('disabled');
        respawnBtn.textContent = 'Respawn Now';
        updateTextTimer();
        return;
    }

    respawnBtn.classList.remove('respawn-ready');
    respawnBtn.classList.add('disabled');
    respawnBtn.textContent = `Respawn in ${timer}s`;
    updateTextTimer();
}

function startTimer(seconds, forceReset = false) {
    if (timerStarted && !forceReset) {
        setRespawnText();
        return;
    }

    clearInterval(interval);
    timer = Number(seconds) || 30;
    ready = false;
    timerStarted = true;
    setRespawnText();

    interval = setInterval(() => {
        timer--;
        if (timer <= 0) {
            clearInterval(interval);
            interval = null;
            timer = 0;
            ready = true;
            setRespawnText();
            post('timerDone');
            return;
        }
        setRespawnText();
    }, 1000);
}

function resetAll() {
    clearInterval(interval);
    interval = null;
    ready = false;
    timerStarted = false;
    choosingLocation = true;
    app.classList.add('hidden');
    textUI.classList.add('hidden');
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'setData') {
        locations = data.locations || [];
        selected = data.selected || 1;
        app.classList.toggle('hidden', !data.show);
        textUI.classList.add('hidden');
        renderLocations();
        startTimer(data.timer || 30, data.resetTimer === true);
    }

    if (data.action === 'selected') {
        selected = data.selected || 1;
        choosingLocation = false;
        renderLocations();
    }

    if (data.action === 'hide') {
        app.classList.add('hidden');
        // Timer keeps running while hidden/minimized.
    }

    if (data.action === 'showTextUI') {
        textKey.textContent = data.key || 'G';
        textLabel.textContent = data.text || 'view full death screen';
        updateTextTimer();
        textUI.classList.remove('hidden');
    }

    if (data.action === 'hideTextUI') {
        textUI.classList.add('hidden');
    }

    if (data.action === 'resetAll') {
        resetAll();
    }
});

respawnBtn.addEventListener('click', () => {
    if (!ready) return;
    post('respawn');
});

changeBtn.addEventListener('click', () => {
    choosingLocation = true;
    renderLocations();
});

minimizeBtn.addEventListener('click', () => post('minimize'));
stuckBtn.addEventListener('click', () => post('stuck'));
recapBtn.addEventListener('click', () => post('recap'));

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.key.toLowerCase() === 'g') post('minimize');
});
