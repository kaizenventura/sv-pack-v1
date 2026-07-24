let hideTimer = null;

window.addEventListener('message', function (event) {
    if (event.data.type !== 'show') return;

    const box = document.getElementById('welcomeBox');
    const name = document.getElementById('welcomeName');
    const badge = document.getElementById('badgeName');
    const audio = document.getElementById('welcomeAudio');
    const duration = event.data.duration || 13000;

    clearTimeout(hideTimer);

    name.innerText = event.data.name || 'WELCOME';
    badge.innerText = event.data.badge || '';

    if (event.data.image && event.data.image.length > 0) {
        box.style.backgroundImage = `linear-gradient(rgba(0,0,0,.15), rgba(0,0,0,.25)), url('${event.data.image}')`;
    } else {
        box.style.backgroundImage = 'linear-gradient(135deg, rgba(12,12,12,.95), rgba(45,45,45,.92))';
    }

    box.style.display = 'flex';

    audio.pause();
    audio.currentTime = 0;
    audio.removeAttribute('src');

    if (event.data.sound && event.data.sound.length > 0) {
        audio.src = event.data.sound;
        audio.play().catch(() => {});
    }

    hideTimer = setTimeout(() => {
        box.style.display = 'none';
        audio.pause();
        audio.currentTime = 0;
    }, duration);
});
