const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

/**
 * Generates the E2E Test Report Excel file based on execution outcomes.
 * @param {Object} results
 * @param {string} results.suiteName
 * @param {Array} results.passed
 * @param {Array} results.failed
 * @param {Array} [results.logs]
 * @param {number} results.durationSec
 * @param {string} results.startTime
 * @param {string} results.endTime
 * @param {string} outputPath
 */
async function generateExcelReport(results, outputPath) {
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'HackPilot E2E Test Runner';
  workbook.lastModifiedBy = 'HackPilot E2E Test Runner';
  workbook.created = new Date();
  workbook.modified = new Date();

  const totalTests = results.passed.length + results.failed.length;
  const passedCount = results.passed.length;
  const failedCount = results.failed.length;
  const skippedCount = 0;
  const passRate = totalTests > 0 ? parseFloat(((passedCount / totalTests) * 100).toFixed(2)) : 100.00;

  // 1. Summary Sheet
  const summarySheet = workbook.addWorksheet('Summary');
  summarySheet.columns = [
    { header: 'Test Suite', key: 'suite', width: 45 },
    { header: 'Total Tests', key: 'total', width: 15 },
    { header: 'Passed', key: 'passed', width: 12 },
    { header: 'Failed', key: 'failed', width: 12 },
    { header: 'Skipped', key: 'skipped', width: 12 },
    { header: 'Pass Rate', key: 'rate', width: 15 },
    { header: 'Duration (sec)', key: 'duration', width: 18 },
    { header: 'Start Time', key: 'start', width: 25 },
    { header: 'End Time', key: 'end', width: 25 }
  ];

  summarySheet.addRow({
    suite: results.suiteName || 'HackPilot Web App – Automated E2E Test Suite',
    total: totalTests,
    passed: passedCount,
    failed: failedCount,
    skipped: skippedCount,
    rate: `${passRate}%`,
    duration: parseFloat((results.durationSec || 0).toFixed(2)),
    start: results.startTime || new Date().toISOString(),
    end: results.endTime || new Date().toISOString()
  });

  // Style Summary Header
  summarySheet.getRow(1).font = { name: 'Segoe UI', size: 11, bold: true, color: { argb: 'FFFFFF' } };
  summarySheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '1E293B' } }; // Dark slate
  summarySheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

  // Style Summary Data Row
  const summaryDataRow = summarySheet.getRow(2);
  summaryDataRow.font = { name: 'Segoe UI', size: 10, bold: true };
  summaryDataRow.alignment = { vertical: 'middle', horizontal: 'center' };
  summaryDataRow.getCell('rate').font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: passRate >= 80 ? '059669' : 'DC2626' } };

  ['A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1', 'I1', 'A2', 'B2', 'C2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2'].forEach(cellRef => {
    summarySheet.getCell(cellRef).border = {
      top: { style: 'thin', color: { argb: 'D1D5DB' } },
      left: { style: 'thin', color: { argb: 'D1D5DB' } },
      bottom: { style: 'thin', color: { argb: 'D1D5DB' } },
      right: { style: 'thin', color: { argb: 'D1D5DB' } }
    };
  });

  // 2. Test Cases Sheet
  const casesSheet = workbook.addWorksheet('Test Cases');
  casesSheet.columns = [
    { header: 'Test ID', key: 'id', width: 16 },
    { header: 'Category', key: 'category', width: 24 },
    { header: 'Test Name', key: 'name', width: 45 },
    { header: 'Scenario', key: 'scenario', width: 45 },
    { header: 'Preconditions', key: 'preconditions', width: 35 },
    { header: 'Execution Steps', key: 'steps', width: 45 },
    { header: 'Expected Result', key: 'expected', width: 45 },
    { header: 'Actual Result', key: 'actualResult', width: 45 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Duration (s)', key: 'time', width: 14 },
    { header: 'Timestamp', key: 'timestamp', width: 25 }
  ];

  // Style Test Cases Header
  casesSheet.getRow(1).font = { name: 'Segoe UI', size: 11, bold: true, color: { argb: 'FFFFFF' } };
  casesSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '0F172A' } };
  casesSheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

  const allCases = [...results.passed, ...results.failed].sort((a, b) => a.id.localeCompare(b.id, undefined, { numeric: true }));

  allCases.forEach((t, idx) => {
    const rowNum = idx + 2;
    const isPassed = t.status === 'PASS';
    const row = casesSheet.addRow({
      id: t.id,
      category: t.category,
      name: t.name,
      scenario: t.scenario,
      preconditions: t.preconditions || 'N/A',
      steps: t.steps || 'N/A',
      expected: t.expected || 'N/A',
      actualResult: t.actualResult || (isPassed ? 'Verified successfully' : t.error || 'Execution failed'),
      status: t.status,
      time: typeof t.time === 'number' ? parseFloat(t.time.toFixed(3)) : t.time,
      timestamp: t.timestamp || new Date().toISOString()
    });

    row.font = { name: 'Segoe UI', size: 9 };
    row.alignment = { vertical: 'middle', horizontal: 'left', wrapText: true };
    
    // Status cell styling
    const statusCell = row.getCell('status');
    statusCell.alignment = { vertical: 'middle', horizontal: 'center' };
    statusCell.font = { name: 'Segoe UI', size: 9, bold: true, color: { argb: isPassed ? '047857' : 'B91C1C' } };
    statusCell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: isPassed ? 'D1FAE5' : 'FEE2E2' }
    };

    // Alternating row background
    if (idx % 2 === 1) {
      ['id', 'category', 'name', 'scenario', 'preconditions', 'steps', 'expected', 'actualResult', 'time', 'timestamp'].forEach(key => {
        row.getCell(key).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'F8FAFC' } };
      });
    }

    ['id', 'category', 'name', 'scenario', 'preconditions', 'steps', 'expected', 'actualResult', 'status', 'time', 'timestamp'].forEach(key => {
      row.getCell(key).border = {
        top: { style: 'thin', color: { argb: 'E2E8F0' } },
        left: { style: 'thin', color: { argb: 'E2E8F0' } },
        bottom: { style: 'thin', color: { argb: 'E2E8F0' } },
        right: { style: 'thin', color: { argb: 'E2E8F0' } }
      };
    });
  });

  await workbook.xlsx.writeFile(outputPath);
  console.log(`[Excel Reporter] Successfully saved report to: ${outputPath}`);
}

module.exports = {
  generateExcelReport
};

