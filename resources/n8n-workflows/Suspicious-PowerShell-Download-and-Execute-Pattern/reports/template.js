// PDF-friendly HTML generator for security alerts
// Use with data from previous node (e.g., Merge node)

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// Process all items from the Merge node
return $items().map(item => {
  const alertData = item.json;
  
  const alert = alertData.kibana?.alert || {};
  const user = alertData.user || {};
  const host = alertData.host || {};
  const event = alertData.event || {};
  const file = alertData.file || {};
  const processes = alertData.process || [];
  const filenames = alertData.filenames || [];

  // Build image index from CUCKOO-GET-IMAGES node
  const imageItems = $items('CUCKOO-GET-IMAGES');
  const imageMap = new Map();
  
  imageItems.forEach(imgItem => {
    const name = imgItem.json?.name;
    const binary = imgItem.binary?.data;
    if (name && binary) {
      const mimeType = binary.mimeType || 'image/jpeg';
      const base64Data = binary.data;
      imageMap.set(name, { mimeType, base64Data });
    }
  });

  // Generate process list HTML (dynamic)
  const processListHTML = processes.length > 0 
    ? processes.map(proc => {
        const cmd = proc.commandline || '';
        return `        <div class="process-item">${escapeHtml(cmd)}</div>`;
      }).join('\n')
    : '        <div class="process-item muted">No process information available</div>';

  // Generate screenshots HTML (dynamic with actual images)
  const screenshotsHTML = filenames.length > 0
    ? filenames.map(filename => {
        const imageData = imageMap.get(filename);
        if (imageData && imageData.base64Data) {
          const src = `data:${imageData.mimeType};base64,${imageData.base64Data}`;
          return `<figure class="shot">
  <img src="${src}" alt="${escapeHtml(filename)}" />
  <figcaption>${escapeHtml(filename)}</figcaption>
</figure>`;
        } else {
          return `<div class="warn">Image not found: ${escapeHtml(filename)}</div>`;
        }
      }).join('\n')
    : '<div class="mono">No screenshots available</div>';

  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Security Alert Report</title>
<style>
  /* ---------- Page & typography ---------- */
  @page { size: A4; margin: 12mm 12mm 14mm 12mm; }
  html, body {
    background: #fff; color: #111;
    font-family: "Inter", "Segoe UI", Roboto, Arial, sans-serif;
    font-size: 12pt; line-height: 1.35;
    margin: 0;
    padding: 0;
  }
  * {
    box-sizing: border-box;
  }
  h1,h2 { margin: 0 0 6pt; line-height: 1.2; }
  h1 { font-size: 16pt; font-weight: 600; }
  h2 { font-size: 12.5pt; color: #0f172a; font-weight: 600; }
  small, .muted { color: #566; font-size: 10pt; }
  .k { font-family: ui-monospace,SFMono-Regular,Menlo,Consolas,monospace; }

  /* ---------- Layout ---------- */
  .wrap { max-width: 180mm; margin: 0 auto; }
  .header, .footer { position: fixed; left: 0; right: 0; color: #566; }
  .header { top: 0; padding: 6mm 12mm 0 12mm; border-bottom: 1px solid #e4eaf2; background: #fff; }
  .footer { bottom: 0; padding: 0 12mm 6mm 12mm; border-top: 1px solid #e4eaf2; text-align: center; background: #fff; }
  .spacer-header { height: 14mm; }
  .spacer-footer { height: 14mm; }

  .card { 
    border: 2px solid #dc2626; 
    border-radius: 8px; 
    padding: 12pt; 
    margin-bottom: 12pt; 
    background: #fef2f2;
  }
  .section { 
    background: #f7f9fc; 
    border: 1px solid #e4eaf2; 
    border-radius: 6px; 
    padding: 10pt; 
    margin: 0 0 10pt 0; 
    break-inside: avoid; 
  }
  
  table.meta { width: 100%; border-collapse: collapse; }
  table.meta td { padding: 4pt 0; vertical-align: top; }
  table.meta td:first-child { width: 38mm; color: #475569; font-weight: 500; }

  .mono {
    background: #fff; 
    border: 1px solid #e4eaf2; 
    border-radius: 4px;
    padding: 8pt; 
    overflow-wrap: anywhere; 
    white-space: pre-wrap;
    font-family: ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
    font-size: 9.5pt; 
    line-height: 1.4;
    margin: 4pt 0;
  }

  /* ---------- Screenshots ---------- */
  .shot { 
    width: 100%; 
    max-width: 100%;
    max-height: 110mm;
    border: 1px solid #e6ecf2; 
    border-radius: 6px; 
    padding: 6pt; 
    break-inside: avoid; 
    background: #fff;
    margin-bottom: 10pt;
    page-break-inside: avoid;
    page-break-after: auto;
    box-sizing: border-box;
  }
  .shot img { 
    display: block; 
    width: 100%; 
    max-height: 95mm;
    object-fit: contain;
    height: auto; 
    border-radius: 4px; 
    border: 1px solid #e4eaf2;
  }
  .shot figcaption { 
    text-align: center; 
    font-size: 9pt; 
    color: #475569; 
    margin-top: 4pt; 
    word-break: break-all; 
  }

  .warn {
    color: #b91c1c;
    background: #fef2f2;
    padding: 6pt 8pt;
    border: 1px solid #fca5a5;
    border-radius: 4px;
    font-size: 9.5pt;
  }

  .badge { 
    display: inline-block; 
    padding: 3pt 8pt; 
    border: 1px solid #dc2626; 
    border-radius: 4px; 
    font-size: 10pt; 
    color: #dc2626; 
    background: #fff;
    font-weight: 500;
  }

  .process-list {
    background: #fff;
    border: 1px solid #e4eaf2;
    border-radius: 4px;
    padding: 0;
    margin: 4pt 0;
    max-height: 400pt;
    overflow: visible;
  }

  .process-item {
    padding: 6pt 8pt;
    border-bottom: 1px solid #f1f5f9;
    font-family: ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
    font-size: 9.5pt;
    line-height: 1.4;
    overflow-wrap: anywhere;
  }

  .process-item:last-child {
    border-bottom: none;
  }

  /* ---------- Page breaks ---------- */
  .section, .shot, table, pre { page-break-inside: avoid; }
  
  .process-list { page-break-inside: auto; }
</style>
</head>
<body>
  <div class="header"><div class="wrap">
    <span class="muted">Security Alert Report • Generated: ${escapeHtml(new Date().toISOString())}</span>
  </div></div>
  
  <div class="footer"><div class="wrap">
    <span class="muted">Alert UUID: ${escapeHtml(alert.uuid || 'N/A')}</span>
  </div></div>

  <div class="spacer-header"></div>
  <main class="wrap">
    <!-- Alert Header -->
    <div class="card">
      <h1>Security Alert Detection</h1>
      <div class="badge">${escapeHtml(alert.rule?.name || 'Unknown Rule')}</div>
      <div style="margin-top: 8pt;">
        <small class="muted">Original Time: ${escapeHtml(alert.original_time || 'N/A')}</small>
      </div>
    </div>

    <!-- Alert Details -->
    <section class="section">
      <h2>Alert Information</h2>
      <table class="meta">
        <tr><td>Alert UUID</td><td><span class="k">${escapeHtml(alert.uuid || 'N/A')}</span></td></tr>
        <tr><td>Rule Name</td><td>${escapeHtml(alert.rule?.name || 'N/A')}</td></tr>
        <tr><td>Original Time</td><td>${escapeHtml(alert.original_time || 'N/A')}</td></tr>
        <tr><td>Event Action</td><td>${escapeHtml(event.action || 'N/A')}</td></tr>
      </table>
    </section>

    <!-- Host Information -->
    <section class="section">
      <h2>Host Information</h2>
      <table class="meta">
        <tr><td>Host Name</td><td><span class="k">${escapeHtml(host.name || 'N/A')}</span></td></tr>
        <tr><td>User Name</td><td>${escapeHtml(user.name || 'N/A')}</td></tr>
      </table>
    </section>

    <!-- File Information -->
    <section class="section">
      <h2>File Information</h2>
      <table class="meta">
        <tr><td>File Path</td><td><span class="k">${escapeHtml(file.path || 'N/A')}</span></td></tr>
        <tr><td>File Name</td><td><span class="k">${escapeHtml(file.name || 'N/A')}</span></td></tr>
      </table>
    </section>

    <!-- Process Chain (Dynamic) -->
    <section class="section">
      <h2>Process Chain (${processes.length} processes)</h2>
      <div class="process-list">
${processListHTML}
      </div>
    </section>

    <!-- Screenshots (Dynamic) -->
    <section class="section">
      <h2>Evidence Screenshots (${filenames.length} files)</h2>
    </section>
${screenshotsHTML}
  </main>
  <div class="spacer-footer"></div>
</body>
</html>`;

  return { json: { ...alertData, html } };
});