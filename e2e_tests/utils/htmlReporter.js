const fs = require('fs');
const path = require('path');

/**
 * Generates interactive HTML report from actual test execution results.
 * @param {Object} results
 * @param {string} results.suiteName
 * @param {Array} results.passed
 * @param {Array} results.failed
 * @param {number} results.durationSec
 * @param {string} results.startTime
 * @param {string} results.endTime
 * @param {string} outputPath
 */
function generateHtmlReport(results, outputPath) {
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const allCases = [...results.passed, ...results.failed].sort((a, b) =>
    a.id.localeCompare(b.id, undefined, { numeric: true })
  );

  const total = allCases.length;
  const passed = results.passed.length;
  const failed = results.failed.length;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(1) : 100.0;

  const rows = allCases.map((t, idx) => {
    const isPass = t.status === 'PASS';
    const dur = typeof t.time === 'number' ? t.time.toFixed(3) : t.time;
    return `<tr>
      <td><strong>${t.id}</strong></td>
      <td><span class="category-badge">${t.category}</span></td>
      <td><code>${t.name}</code></td>
      <td>${t.scenario}</td>
      <td>${t.actualResult}</td>
      <td><span class="status-badge ${isPass ? 'pass' : 'fail'}">${t.status}</span></td>
      <td>${dur}s</td>
    </tr>`;
  }).join('\n');

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${results.suiteName || 'HackPilot Web E2E Test Report'}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0b0f19; color: #e2e8f0; margin: 0; padding: 32px; }
    .container { max-width: 1300px; margin: 0 auto; background: #161e2e; border-radius: 12px; padding: 32px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
    h1 { color: #38bdf8; border-bottom: 2px solid #2d3748; padding-bottom: 12px; margin-top: 0; }
    .kpi-row { display: flex; gap: 16px; margin: 24px 0; }
    .kpi-card { flex: 1; background: #1e293b; padding: 20px; border-radius: 8px; border: 1px solid #2d3748; text-align: center; }
    .kpi-val { font-size: 28px; font-weight: bold; color: #38bdf8; margin-top: 8px; }
    .kpi-val.pass { color: #34d399; }
    .kpi-val.fail { color: #f87171; }
    table { width: 100%; border-collapse: collapse; margin-top: 24px; font-size: 13px; }
    th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #2d3748; }
    th { background: #1e293b; color: #94a3b8; text-transform: uppercase; font-size: 11px; }
    .status-badge { display: inline-block; padding: 3px 8px; border-radius: 6px; font-weight: bold; font-size: 11px; }
    .status-badge.pass { background: #065f46; color: #34d399; }
    .status-badge.fail { background: #7f1d1d; color: #f87171; }
    .category-badge { background: #334155; color: #cbd5e1; padding: 2px 6px; border-radius: 4px; font-size: 11px; }
    code { color: #f43f5e; background: #1e293b; padding: 2px 4px; border-radius: 4px; font-size: 11px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🧪 HackPilot Web E2E Test Execution Report</h1>
    <p>Generated at: <code>${new Date().toISOString()}</code> | Duration: <strong>${(results.durationSec || 0).toFixed(2)} seconds</strong></p>

    <div class="kpi-row">
      <div class="kpi-card"><div>Total Tests</div><div class="kpi-val">${total}</div></div>
      <div class="kpi-card"><div>Passed</div><div class="kpi-val pass">${passed}</div></div>
      <div class="kpi-card"><div>Failed</div><div class="kpi-val fail">${failed}</div></div>
      <div class="kpi-card"><div>Pass Rate</div><div class="kpi-val pass">${passRate}%</div></div>
    </div>

    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Category</th>
          <th>Test Name</th>
          <th>Scenario</th>
          <th>Actual Result</th>
          <th>Status</th>
          <th>Duration</th>
        </tr>
      </thead>
      <tbody>
        ${rows}
      </tbody>
    </table>
  </div>
</body>
</html>`;

  fs.writeFileSync(outputPath, html, 'utf8');
  console.log(`[HTML Reporter] Interactive HTML report successfully written to: ${outputPath}`);
}

module.exports = {
  generateHtmlReport
};

