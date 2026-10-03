const express = require('express');
const path = require('path');
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const app = express();
const PORT = 3000;
const BASE = 'https://api.themoviedb.org/3';

// Module-level variables — assigned after secrets load
let API_KEY = '';
let LASTFM_KEY = '';

async function loadSecrets() {
    const client = new SecretsManagerClient({ region: "ap-south-1" });
    try {
        const data = await client.send(new GetSecretValueCommand({ SecretId: "cinesangeet/app-config-v2" }));
        const secrets = JSON.parse(data.SecretString);
        API_KEY = secrets.TMDB_API_KEY;
        LASTFM_KEY = secrets.LASTFM_KEY || '';
        console.log('Secrets loaded successfully from AWS Secrets Manager');
    } catch (err) {
        console.error('Failed to load secrets:', err.message);
        process.exit(1);
    }
}

app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString(), secretsLoaded: !!API_KEY });
});

/* ---------------- MOVIES ---------------- */
app.get('/api/search-movies', async (req, res) => {
    const query = req.query.q;
    if (!query) return res.json({ results: [] });
    try {
        const url = BASE + '/search/movie?api_key=' + API_KEY + '&query=' + encodeURIComponent(query);
        const r = await fetch(url);
        const data = await r.json();
        res.json({ results: data.results || [] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/movie/:id', async (req, res) => {
    try {
        const [m, c] = await Promise.all([
            fetch(BASE + '/movie/' + req.params.id + '?api_key=' + API_KEY),
            fetch(BASE + '/movie/' + req.params.id + '/credits?api_key=' + API_KEY)
        ]);
        const movie = await m.json();
        movie.credits = await c.json();
        res.json(movie);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/movie/:id/similar', async (req, res) => {
    try {
        const r = await fetch(BASE + '/movie/' + req.params.id + '/similar?api_key=' + API_KEY);
        const data = await r.json();
        res.json({ results: data.results || [] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/* ---------------- MUSIC ---------------- */
function genreToCountry(genre) {
    if (!genre) return null;
    const g = genre.toLowerCase();
    if (/kannada/.test(g)) return 'IN';
    if (/tamil/.test(g)) return 'IN';
    if (/telugu/.test(g)) return 'IN';
    if (/malayalam/.test(g)) return 'IN';
    if (/bollywood|hind|punjab/.test(g)) return 'IN';
    if (/bengali/.test(g)) return 'IN';
    return null;
}

function detectLang(s) {
    const c = (s.collectionName || '').toLowerCase();
    const genre = (s.primaryGenreName || '').toLowerCase();
    const text = (s.trackName || '').toLowerCase();

    if (/kannada/.test(genre)) return 'Kannada';
    if (/tamil/.test(genre)) return 'Tamil';
    if (/telugu/.test(genre)) return 'Telugu';
    if (/malayalam/.test(genre)) return 'Malayalam';
    if (/bengali/.test(genre)) return 'Bengali';
    if (/punjabi/.test(genre)) return 'Punjabi';

    const scripts = {
        Kannada: /[\u0C80-\u0CFF]/,
        Tamil: /[\u0B80-\u0BFF]/,
        Telugu: /[\u0C00-\u0C7F]/,
        Malayalam: /[\u0D00-\u0D7F]/,
        Bengali: /[\u0980-\u09FF]/,
        Hindi: /[\u0900-\u097F]/
    };

    const fullText = text + ' ' + c;
    for (const [lang, re] of Object.entries(scripts)) {
        if (re.test(fullText)) return lang;
    }

    for (const lang of ['Kannada', 'Tamil', 'Telugu', 'Malayalam', 'Bengali', 'Punjabi']) {
        if (c.includes(lang.toLowerCase())) return lang;
    }

    return null;
}

function langToTag(lang) {
    const map = {
        Kannada: 'kannada',
        Tamil: 'tamil',
        Telugu: 'telugu',
        Malayalam: 'malayalam',
        Bengali: 'bengali',
        Punjabi: 'punjabi',
        Hindi: 'bollywood'
    };
    return map[lang] || 'bollywood';
}

async function getSimilarSongs(trackName, artistName, targetLang) {
    const results = [];
    const seen = new Set();
    const tag = langToTag(targetLang);

    if (LASTFM_KEY) {
        try {
            const su = 'http://ws.audioscrobbler.com/2.0/?method=track.getsimilar&artist='
                + encodeURIComponent(artistName) + '&track=' + encodeURIComponent(trackName)
                + '&api_key=' + LASTFM_KEY + '&format=json&limit=15&autocorrect=1';
            const sr = await fetch(su);
            const sd = await sr.json();
            const arr = (sd.similartracks && sd.similartracks.track) ? sd.similartracks.track : [];
            for (const t of arr) {
                const k = t.name.toLowerCase();
                if (seen.has(k) || !k) continue;
                seen.add(k);
                results.push({ name: t.name, artist: t.artist ? t.artist.name : 'Unknown', source: 'lastfm' });
            }
        } catch (e) { /* ignore */ }
    }

    if (LASTFM_KEY && !results.length) {
        try {
            const gu = 'http://ws.audioscrobbler.com/2.0/?method=geo.gettoptracks&country=IN&api_key='
                + LASTFM_KEY + '&format=json&limit=30';
            const gr = await fetch(gu);
            const gd = await gr.json();
            const tracks = (gd.toptracks && gd.toptracks.track) ? gd.toptracks.track : [];
            for (const t of tracks) {
                const k = t.name.toLowerCase();
                if (seen.has(k) || !k) continue;
                seen.add(k);
                results.push({ name: t.name, artist: t.artist ? t.artist.name : 'Unknown', source: 'geo' });
            }
        } catch (e) { /* ignore */ }
    }

    if (results.length < 8) {
        try {
            const genreSearch = tag || 'bollywood';
            const fr = await fetch('https://itunes.apple.com/search?term=' + genreSearch + '&media=music&entity=song&limit=40');
            const fd = await fr.json();
            for (const s of (fd.results || [])) {
                const k = (s.trackName + '|' + s.artistName).toLowerCase();
                if (seen.has(k)) continue;
                const lang = detectLang(s);
                if (lang !== targetLang && targetLang !== 'Hindi') continue;
                seen.add(k);
                results.push({ name: s.trackName, artist: s.artistName, source: 'itunes' });
                if (results.length >= 12) break;
            }
        } catch (e) { /* ignore */ }
    }

    if (!results.length) {
        try {
            const fr = await fetch('https://itunes.apple.com/search?term=' + encodeURIComponent(artistName) + '&media=music&entity=song&limit=60');
            const fd = await fr.json();
            const trackKey = (trackName || '').toLowerCase();
            for (const s of (fd.results || [])) {
                const k = s.trackName.toLowerCase();
                if (k === trackKey || seen.has(k)) continue;
                seen.add(k);
                results.push({ name: s.trackName, artist: s.artistName, source: 'same-artist' });
                if (results.length >= 10) break;
            }
        } catch (e) { /* ignore */ }
    }

    return results.slice(0, 12);
}

app.get('/api/search-songs', async (req, res) => {
    const query = req.query.q;
    if (!query) return res.json({ results: [] });

    try {
        const r = await fetch('https://itunes.apple.com/search?term=' + encodeURIComponent(query) + '&media=music&entity=song&limit=50');
        const data = await r.json();
        const all = data.results || [];

        const seen = new Set();
        const unique = [];
        for (const s of all) {
            const k = (s.trackName || '').toLowerCase().trim();
            if (!k || seen.has(k)) continue;
            if (/\(remix|reprise|instrumental|acoustic|slowed|sped up|cover|karaoke|8d|lofi/i.test(s.trackName)) continue;
            seen.add(k);
            unique.push(s);
        }

        const top = unique[0];
        if (top) {
            const lang = detectLang(top) || top.primaryGenreName || 'Hindi';
            top.similar = await getSimilarSongs(top.trackName, top.artistName, lang);
        }

        res.json({ results: unique.slice(0, 10) });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Start server ONLY after secrets are loaded
(async () => {
    await loadSecrets();
    app.listen(PORT, () => {
        console.log('CineSangeet running at http://localhost:' + PORT);
    });
})();