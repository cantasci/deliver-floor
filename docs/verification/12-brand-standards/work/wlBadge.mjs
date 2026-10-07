// Watchlist level badge: returns the HTML string for levels 1 to 4.
// Pure: no I/O, no state. Styling lives in wlBadge.css.

function describe(value) {
  try {
    return String(value);
  } catch {
    return typeof value;
  }
}

export function wlBadgeHtml(level) {
  if (level === 1 || level === 2 || level === 3 || level === 4) {
    return '<span class="wl-badge wl-badge--' + level + '">WL ' + level + '</span>';
  }
  throw new RangeError('wlBadgeHtml: level must be 1, 2, 3 or 4, got ' + describe(level));
}
