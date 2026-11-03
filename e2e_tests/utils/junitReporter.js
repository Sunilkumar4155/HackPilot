const fs = require('fs');
const path = require('path');

/**
 * Escapes characters for XML attributes and text nodes.
 * @param {string} str
 * @returns {string}
 */
function escapeXml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

/**
 * Generates standard JUnit XML file from execution results.
 * @param {Object} results
 * @param {string} results.suiteName
 * @param {Array} results.passed
 * @param {Array} results.failed
 * @param {number} results.durationSec
 * @param {string} outputPath
 */
function generateJUnitXml(results, outputPath) {
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const allCases = [...results.passed, ...results.failed];
  const totalTests = allCases.length;
  const failureCount = results.failed.length;
  const totalDuration = results.durationSec || 0;

  // Group by category
  const categoriesMap = {};
  allCases.forEach(tc => {
    const cat = tc.category || 'General';
    if (!categoriesMap[cat]) categoriesMap[cat] = [];
    categoriesMap[cat].push(tc);
  });

  let xml = `<?xml version="1.0" encoding="UTF-8"?>\n`;
  const safeSuiteName = (results.suiteName || 'HackPilot Web E2E Suite').replace(/[^\x00-\x7F]/g, '-');
  xml += `<testsuites name="${escapeXml(safeSuiteName)}" tests="${totalTests}" failures="${failureCount}" errors="0" skipped="0" time="${totalDuration.toFixed(3)}">\n`;

  for (const [catName, tests] of Object.entries(categoriesMap)) {
    const catFailures = tests.filter(t => t.status === 'FAIL').length;
    const catTime = tests.reduce((acc, t) => acc + (typeof t.time === 'number' ? t.time : 0), 0);

    xml += `  <testsuite name="${escapeXml(catName)}" tests="${tests.length}" failures="${catFailures}" errors="0" skipped="0" time="${catTime.toFixed(3)}">\n`;

    tests.forEach(t => {
      const duration = typeof t.time === 'number' ? t.time.toFixed(3) : '0.010';
      xml += `    <testcase classname="HackPilot.WebE2E.${escapeXml(t.category.replace(/[^a-zA-Z0-9]/g, ''))}" name="${escapeXml(t.id + ': ' + t.name)}" time="${duration}">\n`;
      if (t.status === 'FAIL') {
        xml += `      <failure message="${escapeXml(t.error || 'Test failed')}">${escapeXml(t.actualResult || t.error || '')}</failure>\n`;
      }
      xml += `    </testcase>\n`;
    });

    xml += `  </testsuite>\n`;
  }

  xml += `</testsuites>\n`;

  fs.writeFileSync(outputPath, xml, 'utf8');
  console.log(`[JUnit Reporter] Genuine JUnit XML successfully written to: ${outputPath}`);
}

module.exports = {
  generateJUnitXml
};
