const $ = id => document.getElementById(id);
let currentIP = '';
let toastTimer;
async function refresh() {
  $('refresh').disabled = true;
  $('connection-status').textContent = 'Checking connection';
  try {
    const response = await fetch('/api/connection', { cache: 'no-store' });
    if (!response.ok) throw new Error('Connection unavailable');
    const data = await response.json();
    currentIP = data.ip;
    $('ip').textContent = data.ip;
    $('protocol').textContent = data.version;
    $('scope').textContent = data.local ? 'Local network' : 'Remote connection';
    $('connection-status').textContent = 'Connected';
    $('address-note').textContent = data.local ? 'Local address · Public IP may differ' : 'Server-observed address · Public IP may differ';
    $('copy').disabled = false;
  } catch {
    currentIP = '';
    $('ip').textContent = 'Unavailable';
    $('protocol').textContent = '—';
    $('scope').textContent = 'Unavailable';
    $('connection-status').textContent = 'Connection interrupted';
    $('address-note').textContent = 'Please try refreshing your connection.';
    $('copy').disabled = true;
  } finally { $('refresh').disabled = false; }
}
$('refresh').addEventListener('click', refresh);
$('copy').addEventListener('click', async () => {
  try {
    await navigator.clipboard.writeText(currentIP);
    $('toast').textContent = 'IP address copied';
  } catch { $('toast').textContent = 'Copy unavailable. Select the address to copy it.'; }
  $('toast').classList.add('visible');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => $('toast').classList.remove('visible'), 2600);
});
refresh();
