const TMDB_IMG = 'https://image.tmdb.org/t/p/w500';

document.getElementById('searchBtn').addEventListener('click', doSearch);
document.getElementById('searchInput').addEventListener('keydown', function (e) {
  if (e.key === 'Enter') doSearch();
});

async function doSearch() {
  const query = document.getElementById('searchInput').value.trim();
  const type = document.getElementById('typeFilter').value;
  if (!query) return;

  const resultsDiv = document.getElementById('results');
  resultsDiv.innerHTML = '<p class="loading">Searching...</p>';
  document.getElementById('movieDetail').innerHTML = '';
  document.getElementById('similarResults').innerHTML = '';

  if (type === 'movie') await searchMovies(query);
  else await searchSongs(query);
}

function esc(str) {
  return String(str == null ? '' : str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* ---------------- MOVIES ---------------- */
async function searchMovies(query) {
  const resultsDiv = document.getElementById('results');
  try {
    const r = await fetch('/api/search-movies?q=' + encodeURIComponent(query));
    const data = await r.json();
    if (!data.results.length) {
      resultsDiv.innerHTML = '<p class="no-results">No movies found.</p>';
      return;
    }
    let html = '<div class="movie-grid">';
    data.results.forEach(function (m) {
      const poster = m.poster_path
        ? '<img src="' + TMDB_IMG + m.poster_path + '" class="poster">'
        : '<div class="poster placeholder">No Poster</div>';
      const yt = 'https://www.youtube.com/results?search_query=' + encodeURIComponent(m.title + ' official trailer');
      const imdb = 'https://www.imdb.com/find/?q=' + encodeURIComponent(m.title);
      html += '<div class="movie-card" onclick="showMovieDetail(' + m.id + ')">'
        + poster
        + '<h3>' + esc(m.title) + '</h3>'
        + '<p class="meta">' + (m.release_date ? m.release_date.substring(0, 4) : 'Unknown')
        + ' | ' + (m.vote_average ? m.vote_average.toFixed(1) : 'N/A') + '</p>'
        + '<div class="btn-group">'
        + '<a href="' + yt + '" target="_blank" class="btn btn-yt">Trailer</a>'
        + '<a href="' + imdb + '" target="_blank" class="btn btn-imdb">IMDb</a>'
        + '</div></div>';
    });
    html += '</div>';
    resultsDiv.innerHTML = html;
  } catch (err) {
    resultsDiv.innerHTML = '<p class="error">Error: ' + err.message + '</p>';
  }
}

async function showMovieDetail(id) {
  const detailDiv = document.getElementById('movieDetail');
  detailDiv.innerHTML = '<p class="loading">Loading details...</p>';
  document.getElementById('similarResults').innerHTML = '';
  try {
    const r = await fetch('/api/movie/' + id);
    const movie = await r.json();
    if (!movie.title) { detailDiv.innerHTML = '<p class="error">Could not load details.</p>'; return; }

    const crew = (movie.credits && movie.credits.crew) || [];
    const director = crew.find(function (c) { return c.job === 'Director'; });
    const cast = ((movie.credits && movie.credits.cast) || []).slice(0, 5);
    const genres = (movie.genres || []).map(function (g) { return g.name; }).join(', ') || 'N/A';
    const yt = 'https://www.youtube.com/results?search_query=' + encodeURIComponent(movie.title + ' official trailer');
    const imdb = 'https://www.imdb.com/find/?q=' + encodeURIComponent(movie.title);

    detailDiv.innerHTML = '<div class="detail-card">'
      + '<div class="detail-header"><h2>' + esc(movie.title) + '</h2><span class="badge">' + esc(movie.tagline || '') + '</span></div>'
      + '<div class="detail-grid">'
      + '<div><strong>Release:</strong> ' + (movie.release_date || 'N/A') + '</div>'
      + '<div><strong>Rating:</strong> ' + (movie.vote_average ? movie.vote_average.toFixed(1) : 'N/A') + ' / 10</div>'
      + '<div><strong>Runtime:</strong> ' + (movie.runtime ? movie.runtime + ' min' : 'N/A') + '</div>'
      + '<div><strong>Genres:</strong> ' + genres + '</div>'
      + '<div><strong>Director:</strong> ' + (director ? esc(director.name) : 'N/A') + '</div>'
      + '<div><strong>Cast:</strong> ' + cast.map(function (c) { return esc(c.name); }).join(', ') + '</div>'
      + '</div>'
      + '<p class="overview">' + esc(movie.overview || 'No description available.') + '</p>'
      + '<div class="detail-actions">'
      + '<a href="' + yt + '" target="_blank" class="btn btn-yt">Watch Trailer</a>'
      + '<a href="' + imdb + '" target="_blank" class="btn btn-imdb">IMDb Page</a>'
      + '<button onclick="showSimilarMovies(' + id + ')" class="btn btn-similar">Similar Movies</button>'
      + '</div></div>';
    detailDiv.scrollIntoView({ behavior: 'smooth' });
  } catch (err) {
    detailDiv.innerHTML = '<p class="error">Error: ' + err.message + '</p>';
  }
}

async function showSimilarMovies(id) {
  const div = document.getElementById('similarResults');
  div.innerHTML = '<p class="loading">Finding similar movies...</p>';
  try {
    const r = await fetch('/api/movie/' + id + '/similar');
    const data = await r.json();
    if (!data.results.length) { div.innerHTML = '<p class="no-results">None found.</p>'; return; }
    let html = '<h3 class="section-title">Similar Movies</h3><div class="movie-grid">';
    data.results.forEach(function (m) {
      const poster = m.poster_path
        ? '<img src="' + TMDB_IMG + m.poster_path + '" class="poster">'
        : '<div class="poster placeholder">No Poster</div>';
      html += '<div class="movie-card" onclick="showMovieDetail(' + m.id + ')">'
        + poster + '<h3>' + esc(m.title) + '</h3>'
        + '<p class="meta">' + (m.release_date ? m.release_date.substring(0, 4) : 'Unknown') + '</p></div>';
    });
    html += '</div>';
    div.innerHTML = html;
    div.scrollIntoView({ behavior: 'smooth' });
  } catch (err) {
    div.innerHTML = '<p class="error">Error: ' + err.message + '</p>';
  }
}

/* ---------------- SONGS ---------------- */
async function searchSongs(query) {
  const resultsDiv = document.getElementById('results');
  try {
    const r = await fetch('/api/search-songs?q=' + encodeURIComponent(query));
    const data = await r.json();
    if (!data.results.length) {
      resultsDiv.innerHTML = '<p class="no-results">No songs found.</p>';
      return;
    }

    const top = data.results[0];
    const art = top.artworkUrl100 ? top.artworkUrl100.replace('100x100', '300x300') : '';
    const ytTop = 'https://www.youtube.com/results?search_query='
      + encodeURIComponent(top.trackName + ' ' + top.artistName + ' song');

    let html = '<div class="song-hero">'
      + (art ? '<img src="' + art + '" class="hero-art">' : '<div class="hero-art placeholder">&#9834;</div>')
      + '<div class="hero-info">'
      + '<h2>' + esc(top.trackName) + '</h2>'
      + '<p class="hero-artist">' + esc(top.artistName) + '</p>'
      + '<p class="meta">' + esc(top.collectionName || 'Single') + ' &middot; '
      + esc(top.primaryGenreName || '') + ' &middot; '
      + (top.releaseDate ? top.releaseDate.substring(0, 4) : '') + '</p>'
      + '<a href="' + ytTop + '" target="_blank" class="btn btn-yt big-btn">Listen on YouTube</a>'
      + '</div></div>';

    if (top.similar && top.similar.length) {
      html += '<h3 class="section-title">More Like "' + esc(top.trackName) + '"</h3><div class="song-list">';
      top.similar.forEach(function (t) {
        const ylink = 'https://www.youtube.com/results?search_query=' + encodeURIComponent(t.name + ' ' + t.artist);
        html += '<div class="song-row"><div><strong>' + esc(t.name) + '</strong> &mdash; ' + esc(t.artist) + '</div>'
          + '<a href="' + ylink + '" target="_blank" class="btn btn-yt small-btn">Play</a></div>';
      });
      html += '</div>';
    }

    if (data.results.length > 1) {
      html += '<h3 class="section-title">Other Results</h3><div class="song-grid">';
      data.results.slice(1).forEach(function (s) {
        const a = s.artworkUrl100 ? s.artworkUrl100.replace('100x100', '300x300') : '';
        const yq = 'https://www.youtube.com/results?search_query=' + encodeURIComponent(s.trackName + ' ' + s.artistName + ' song');
        html += '<div class="song-card">'
          + (a ? '<img src="' + a + '" class="song-art">' : '<div class="song-art placeholder">&#9834;</div>')
          + '<h3>' + esc(s.trackName) + '</h3>'
          + '<p class="meta">' + esc(s.artistName) + '</p>'
          + '<div class="btn-group">'
          + '<a href="' + yq + '" target="_blank" class="btn btn-yt">Listen</a>'
          + '</div></div>';
      });
      html += '</div>';
    }

    resultsDiv.innerHTML = html;
  } catch (err) {
    resultsDiv.innerHTML = '<p class="error">Error: ' + err.message + '</p>';
  }
}