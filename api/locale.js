// Vercel supplies a coarse country code. No IP, precise location or analytics is read or stored.
module.exports = function handler(req, res) {
  const raw = req.headers['x-vercel-ip-country'];
  const country = typeof raw === 'string' && /^[A-Z]{2}$/.test(raw) ? raw : null;
  res.setHeader('Cache-Control', 'private, no-store');
  res.status(200).json({ country });
};
