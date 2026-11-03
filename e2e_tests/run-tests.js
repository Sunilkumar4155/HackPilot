const path = require('path');
const fs = require('fs');
const { executeWebTests } = require('./selenium_web/webRunner');
const { generateExcelReport } = require('./utils/excelReporter');
const { generateJUnitXml } = require('./utils/junitReporter');
const { generateHtmlReport } = require('./utils/htmlReporter');

// Report Output Directories
const webReportsDir = path.resolve(__dirname, './reports/web');
const rootReportsDir = path.resolve(__dirname, '../testing/reports');

// Helper to ensure directory exists
function ensureDirectory(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// Parse CLI Arguments
const args = process.argv.slice(2);
const runWeb = args.includes('--web') || args.includes('--all') || args.length === 0;

async function main() {
  const startTime = new Date();
  console.log(`===================================================`);
  console.log(`HackPilot Genuine E2E Test Suite Orchestrator`);
  console.log(`Start Time: ${startTime.toISOString()}`);
  console.log(`===================================================`);

  let hasFailures = false;

  if (runWeb) {
    console.log('\n--- STARTING GENUINE WEB E2E TEST SUITE (300 Real Tests) ---');
    ensureDirectory(webReportsDir);
    ensureDirectory(rootReportsDir);
    ensureDirectory(path.join(rootReportsDir, 'html'));
    ensureDirectory(path.join(rootReportsDir, 'excel'));

    const webStart = Date.now();
    try {
      const targetUrl = process.env.BASE_URL || 'http://localhost:8080';
      const results = await executeWebTests(targetUrl);
      const webEnd = Date.now();

      const totalDiscovered = results.passed.length + results.failed.length;
      const passedCount = results.passed.length;
      const failedCount = results.failed.length;

      console.log(`\n[WEB E2E SUMMARY] Discovered: ${totalDiscovered} | Passed: ${passedCount} | Failed: ${failedCount}`);

      results.durationSec = (webEnd - webStart) / 1000;
      results.startTime = new Date(webStart).toISOString();
      results.endTime = new Date(webEnd).toISOString();

      // 1. Generate Genuine JUnit XML Report
      const junitPath = path.join(webReportsDir, 'junit-results.xml');
      generateJUnitXml(results, junitPath);
      // Also copy to testing/reports for centralized access
      fs.copyFileSync(junitPath, path.join(rootReportsDir, 'junit-web-e2e.xml'));

      // 2. Generate Interactive HTML Report
      const htmlPath = path.join(webReportsDir, 'E2E_Test_Report_Web.html');
      generateHtmlReport(results, htmlPath);
      fs.copyFileSync(htmlPath, path.join(rootReportsDir, 'html', 'HTML_Web_E2E_Report.html'));

      // 3. Generate Dual-Sheet Excel Report
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const reportName = `E2E_Test_Report_Web_${timestamp}.xlsx`;
      const reportPath = path.join(webReportsDir, reportName);
      await generateExcelReport(results, reportPath);
      // Copy to latest excel report path
      fs.copyFileSync(reportPath, path.join(webReportsDir, 'E2E_Test_Report_Web_Latest.xlsx'));
      fs.copyFileSync(reportPath, path.join(rootReportsDir, 'excel', 'HackPilot_E2E_300_Report.xlsx'));

      console.log(`[Success] Genuine JUnit XML: ${junitPath}`);
      console.log(`[Success] Interactive HTML Report: ${htmlPath}`);
      console.log(`[Success] Master Excel Report: ${reportPath}`);

      if (totalDiscovered !== 300 || passedCount !== 300 || failedCount !== 0) {
        console.error(`[E2E ASSERTION ERROR] Web E2E assertion: Expected 300 Passed, 0 Failed. Got: ${passedCount} Passed, ${failedCount} Failed out of ${totalDiscovered}`);
        hasFailures = true;
      }
    } catch (e) {
      console.error('[Error] Genuine Web E2E Run failed:', e);
      hasFailures = true;
    }
  }

  const endTime = new Date();
  console.log(`\n===================================================`);
  console.log(`All operations completed at: ${endTime.toISOString()}`);
  console.log(`Total duration: ${((endTime - startTime) / 1000).toFixed(2)} seconds`);
  console.log(`===================================================`);

  if (hasFailures) {
    process.exit(1);
  }
}

main().catch(err => {
  console.error('[Critical Error] Orchestrator crashed:', err);
  process.exit(1);
});
