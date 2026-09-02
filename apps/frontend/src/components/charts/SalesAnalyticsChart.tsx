import React, { useState, useMemo } from 'react';
import { ArrowUpRight, BarChart2, TrendingUp, Calendar, Zap, DollarSign, Award } from 'lucide-react';
import './SalesAnalyticsChart.css';

export interface ChartDataPoint {
  label: string;
  fullDate?: string;
  income: number;
  expense: number;
  ordersCount?: number;
}

interface SalesAnalyticsChartProps {
  title?: string;
  subtitle?: string;
  growthPercentage?: string;
}

const DATA_7_DAYS: ChartDataPoint[] = [
  { label: 'Sen', fullDate: 'Senin, 24 Agt', income: 950000, expense: 320000, ordersCount: 28 },
  { label: 'Sel', fullDate: 'Selasa, 25 Agt', income: 1100000, expense: 180000, ordersCount: 34 },
  { label: 'Rab', fullDate: 'Rabu, 26 Agt', income: 850000, expense: 400000, ordersCount: 22 },
  { label: 'Kam', fullDate: 'Kamis, 27 Agt', income: 1250000, expense: 420000, ordersCount: 38 },
  { label: 'Jum', fullDate: 'Jumat, 28 Agt', income: 1400000, expense: 250000, ordersCount: 42 },
  { label: 'Sab', fullDate: 'Sabtu, 29 Agt', income: 1850000, expense: 600000, ordersCount: 56 },
  { label: 'Min', fullDate: 'Minggu, 30 Agt', income: 2100000, expense: 450000, ordersCount: 64 },
];

const DATA_30_DAYS: ChartDataPoint[] = [
  { label: 'Mgg 1', fullDate: '1 - 7 Agt', income: 7200000, expense: 2100000, ordersCount: 210 },
  { label: 'Mgg 2', fullDate: '8 - 14 Agt', income: 8400000, expense: 2400000, ordersCount: 245 },
  { label: 'Mgg 3', fullDate: '15 - 21 Agt', income: 9100000, expense: 2800000, ordersCount: 270 },
  { label: 'Mgg 4', fullDate: '22 - 28 Agt', income: 9500000, expense: 2620000, ordersCount: 284 },
];

export const SalesAnalyticsChart: React.FC<SalesAnalyticsChartProps> = ({
  title = 'Grafik Penjualan & Arus Kas',
  subtitle = 'Analisis tren omzet harian vs pengeluaran kulakan',
}) => {
  const [period, setPeriod] = useState<'7d' | '30d'>('7d');
  const [chartMode, setChartMode] = useState<'line' | 'bar'>('line');
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const activeData = period === '7d' ? DATA_7_DAYS : DATA_30_DAYS;

  // Selected or default active point
  const selectedIndex = hoveredIndex !== null ? hoveredIndex : activeData.length - 1;
  const activePoint = activeData[selectedIndex] || activeData[0];

  // Calculations
  const totalIncome = useMemo(() => activeData.reduce((acc, d) => acc + d.income, 0), [activeData]);
  const totalExpense = useMemo(() => activeData.reduce((acc, d) => acc + d.expense, 0), [activeData]);
  const netProfit = totalIncome - totalExpense;
  const profitMargin = totalIncome > 0 ? ((netProfit / totalIncome) * 100).toFixed(1) : '0';

  const peakPoint = useMemo(() => {
    return activeData.reduce((max, d) => (d.income > max.income ? d : max), activeData[0]);
  }, [activeData]);

  const maxVal = Math.max(...activeData.map((d) => Math.max(d.income, d.expense)), 1000000);
  const safeMax = maxVal * 1.15;

  // SVG dimensions for Line Chart
  const svgWidth = 640;
  const svgHeight = 180;
  const paddingLeft = 58;
  const paddingRight = 24;
  const paddingBottom = 28;
  const paddingTop = 20;
  const plotWidth = svgWidth - paddingLeft - paddingRight;
  const plotHeight = svgHeight - paddingBottom - paddingTop;

  const points = activeData.map((d, i) => {
    const x = paddingLeft + (i / (activeData.length - 1)) * plotWidth;
    const yIncome = paddingTop + plotHeight - (d.income / safeMax) * plotHeight;
    const yExpense = paddingTop + plotHeight - (d.expense / safeMax) * plotHeight;
    return { x, yIncome, yExpense, ...d };
  });

  // Smooth SVG bezier
  const generateCurvedPath = (pts: { x: number; y: number }[]) => {
    if (pts.length === 0) return '';
    let d = `M ${pts[0].x} ${pts[0].y}`;
    for (let i = 0; i < pts.length - 1; i++) {
      const current = pts[i];
      const next = pts[i + 1];
      const controlX = (current.x + next.x) / 2;
      d += ` C ${controlX} ${current.y}, ${controlX} ${next.y}, ${next.x} ${next.y}`;
    }
    return d;
  };

  const incomeLinePath = generateCurvedPath(points.map((p) => ({ x: p.x, y: p.yIncome })));
  const expenseLinePath = generateCurvedPath(points.map((p) => ({ x: p.x, y: p.yExpense })));

  const incomeAreaPath = points.length > 0
    ? `${incomeLinePath} L ${points[points.length - 1].x} ${svgHeight - paddingBottom} L ${points[0].x} ${svgHeight - paddingBottom} Z`
    : '';

  // Y-axis formatting helper
  const formatYAxis = (val: number) => {
    if (val >= 1000000) return `${(val / 1000000).toFixed(1)}Jt`;
    if (val >= 1000) return `${(val / 1000).toFixed(0)}Rb`;
    return '0';
  };

  const yTicks = [0, 0.33, 0.66, 1].map((ratio) => {
    const value = safeMax * ratio;
    const yPos = paddingTop + plotHeight - ratio * plotHeight;
    return { value, yPos };
  });

  return (
    <div className="card-base modern-chart-container">
      {/* ── Top Header Toolbar ── */}
      <div className="modern-chart-header">
        <div className="chart-heading-group">
          <div className="chart-icon-badge">
            <TrendingUp size={18} />
          </div>
          <div>
            <h3 className="chart-title-text">{title}</h3>
            <p className="chart-sub-text">{subtitle}</p>
          </div>
        </div>

        <div className="chart-header-actions">
          {/* Period Pills */}
          <div className="chart-pill-selector">
            <button
              type="button"
              onClick={() => { setPeriod('7d'); setHoveredIndex(null); }}
              className={`pill-btn ${period === '7d' ? 'active' : ''}`}
            >
              7 Hari
            </button>
            <button
              type="button"
              onClick={() => { setPeriod('30d'); setHoveredIndex(null); }}
              className={`pill-btn ${period === '30d' ? 'active' : ''}`}
            >
              30 Hari
            </button>
          </div>

          {/* Mode Switcher */}
          <div className="chart-view-toggle">
            <button
              type="button"
              onClick={() => setChartMode('line')}
              className={`view-btn ${chartMode === 'line' ? 'active' : ''}`}
              title="Grafik Garis Area"
            >
              <TrendingUp size={14} />
            </button>
            <button
              type="button"
              onClick={() => setChartMode('bar')}
              className={`view-btn ${chartMode === 'bar' ? 'active' : ''}`}
              title="Grafik Batang Komparasi"
            >
              <BarChart2 size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* ── KPI Micro Scoreboard ── */}
      <div className="chart-kpi-scoreboard">
        <div className="kpi-mini-card">
          <span className="kpi-mini-label">Total Omzet</span>
          <span className="kpi-mini-val text-teal">Rp {totalIncome.toLocaleString('id-ID')}</span>
        </div>
        <div className="kpi-mini-divider"></div>
        <div className="kpi-mini-card">
          <span className="kpi-mini-label">Pengeluaran</span>
          <span className="kpi-mini-val text-red">Rp {totalExpense.toLocaleString('id-ID')}</span>
        </div>
        <div className="kpi-mini-divider"></div>
        <div className="kpi-mini-card">
          <span className="kpi-mini-label">Laba Bersih ({profitMargin}%)</span>
          <span className="kpi-mini-val text-dark">Rp {netProfit.toLocaleString('id-ID')}</span>
        </div>
        <div className="kpi-mini-divider"></div>
        <div className="kpi-mini-card">
          <span className="kpi-mini-label">Puncak Omzet</span>
          <span className="kpi-mini-val text-gold">{peakPoint.label} (Rp {peakPoint.income.toLocaleString('id-ID')})</span>
        </div>
      </div>

      {/* ── Interactive Active Point Banner ── */}
      <div className="chart-interactive-banner">
        <div className="banner-date">
          <Calendar size={13} />
          <span>{activePoint.fullDate || activePoint.label}</span>
          {activePoint.ordersCount && (
            <span className="banner-orders-chip">{activePoint.ordersCount} Transaksi</span>
          )}
        </div>

        <div className="banner-stats-row">
          <div className="stat-pill income">
            <span className="stat-dot teal"></span>
            <span>Omzet: <strong>Rp {activePoint.income.toLocaleString('id-ID')}</strong></span>
          </div>
          <div className="stat-pill expense">
            <span className="stat-dot red"></span>
            <span>Biaya: <strong>Rp {activePoint.expense.toLocaleString('id-ID')}</strong></span>
          </div>
          <div className="stat-pill profit">
            <span className="stat-dot green"></span>
            <span>Laba: <strong>Rp {(activePoint.income - activePoint.expense).toLocaleString('id-ID')}</strong></span>
          </div>
        </div>
      </div>

      {/* ── Chart Visual Area ── */}
      <div className="chart-render-stage">
        {chartMode === 'line' ? (
          <svg
            viewBox={`0 0 ${svgWidth} ${svgHeight}`}
            className="chart-svg-root"
            preserveAspectRatio="none"
          >
            <defs>
              <linearGradient id="modernTealGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#0D9488" stopOpacity="0.32" />
                <stop offset="85%" stopColor="#0D9488" stopOpacity="0.02" />
                <stop offset="100%" stopColor="#0D9488" stopOpacity="0.0" />
              </linearGradient>
              <filter id="glowEffect" x="-20%" y="-20%" width="140%" height="140%">
                <feDropShadow dx="0" dy="2" stdDeviation="3" floodColor="#0D9488" floodOpacity="0.3" />
              </filter>
            </defs>

            {/* Y-Axis Grid Lines & Reference Labels */}
            {yTicks.map((tick, idx) => (
              <g key={idx}>
                <line
                  x1={paddingLeft}
                  y1={tick.yPos}
                  x2={svgWidth - paddingRight}
                  y2={tick.yPos}
                  stroke="#E2E8F0"
                  strokeDasharray={idx === 0 ? '0' : '3 3'}
                  strokeWidth="1"
                />
                <text
                  x={paddingLeft - 8}
                  y={tick.yPos + 4}
                  textAnchor="end"
                  className="axis-y-label"
                >
                  {formatYAxis(tick.value)}
                </text>
              </g>
            ))}

            {/* Area Fill */}
            <path d={incomeAreaPath} fill="url(#modernTealGrad)" />

            {/* Expense Subtle Path */}
            <path
              d={expenseLinePath}
              fill="none"
              stroke="#F87171"
              strokeWidth="2"
              strokeDasharray="4 4"
              strokeLinecap="round"
              opacity="0.85"
            />

            {/* Income Main Curved Line */}
            <path
              d={incomeLinePath}
              fill="none"
              stroke="#0D9488"
              strokeWidth="3.5"
              strokeLinecap="round"
              strokeLinejoin="round"
              filter="url(#glowEffect)"
            />

            {/* Scrubber Laser Guideline on Hover */}
            {points[selectedIndex] && (
              <line
                x1={points[selectedIndex].x}
                y1={paddingTop}
                x2={points[selectedIndex].x}
                y2={svgHeight - paddingBottom}
                stroke="#0D9488"
                strokeWidth="1.5"
                strokeDasharray="3 3"
                opacity="0.6"
              />
            )}

            {/* Interactive Data Nodes */}
            {points.map((p, idx) => {
              const isSelected = selectedIndex === idx;
              return (
                <g
                  key={idx}
                  className="interactive-node"
                  onMouseEnter={() => setHoveredIndex(idx)}
                  onClick={() => setHoveredIndex(idx)}
                  style={{ cursor: 'pointer' }}
                >
                  {/* Broad transparent touch target */}
                  <rect
                    x={p.x - plotWidth / (points.length * 2)}
                    y={0}
                    width={plotWidth / points.length}
                    height={svgHeight}
                    fill="transparent"
                  />

                  {/* Expense Dot */}
                  <circle
                    cx={p.x}
                    cy={p.yExpense}
                    r={isSelected ? 4 : 2.5}
                    fill="#EF4444"
                  />

                  {/* Income Outer Glow Ring */}
                  {isSelected && (
                    <circle
                      cx={p.x}
                      cy={p.yIncome}
                      r="9"
                      fill="#0D9488"
                      opacity="0.2"
                    />
                  )}

                  {/* Income Dot */}
                  <circle
                    cx={p.x}
                    cy={p.yIncome}
                    r={isSelected ? 6 : 4}
                    fill={isSelected ? '#0F766E' : '#FFFFFF'}
                    stroke="#0D9488"
                    strokeWidth={isSelected ? 3 : 2}
                  />

                  {/* X-Axis Date Label */}
                  <text
                    x={p.x}
                    y={svgHeight - 8}
                    textAnchor="middle"
                    className={`axis-x-label ${isSelected ? 'active' : ''}`}
                  >
                    {p.label}
                  </text>
                </g>
              );
            })}
          </svg>
        ) : (
          /* ── Bar Comparison Mode ── */
          <div className="modern-bars-wrapper" style={{ paddingLeft: `${paddingLeft}px` }}>
            <div className="bars-y-ticks">
              {yTicks.map((tick, idx) => (
                <span
                  key={idx}
                  className="bar-y-label"
                  style={{ bottom: `${((tick.value / safeMax) * 100) * 0.75 + 18}%` }}
                >
                  {formatYAxis(tick.value)}
                </span>
              ))}
            </div>

            <div className="bars-columns-flex">
              {activeData.map((item, idx) => {
                const isSelected = selectedIndex === idx;
                const incomePct = (item.income / safeMax) * 100;
                const expensePct = (item.expense / safeMax) * 100;

                return (
                  <div
                    key={idx}
                    className={`bar-day-group ${isSelected ? 'active' : ''}`}
                    onMouseEnter={() => setHoveredIndex(idx)}
                    onClick={() => setHoveredIndex(idx)}
                  >
                    <div className="bar-pillars-row">
                      {/* Income Bar */}
                      <div
                        className="bar-column income-col"
                        style={{ height: `${Math.max(incomePct, 8)}%` }}
                        title={`Omzet: Rp ${item.income.toLocaleString('id-ID')}`}
                      >
                        {isSelected && <span className="bar-tag income">Rp {(item.income / 1000).toFixed(0)}k</span>}
                      </div>

                      {/* Expense Bar */}
                      <div
                        className="bar-column expense-col"
                        style={{ height: `${Math.max(expensePct, 4)}%` }}
                        title={`Biaya: Rp ${item.expense.toLocaleString('id-ID')}`}
                      >
                        {isSelected && <span className="bar-tag expense">Rp {(item.expense / 1000).toFixed(0)}k</span>}
                      </div>
                    </div>

                    <span className={`bar-day-label ${isSelected ? 'active' : ''}`}>{item.label}</span>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* ── Chart Legend & Insights Footer ── */}
      <div className="modern-chart-footer">
        <div className="legend-pills-row">
          <div className="legend-indicator">
            <span className="legend-bullet teal-solid"></span>
            <span className="legend-name">Omzet Pemasukan</span>
          </div>
          <div className="legend-indicator">
            <span className="legend-bullet red-dashed"></span>
            <span className="legend-name">Pengeluaran Bahan Baku</span>
          </div>
        </div>

        <div className="footer-quick-tip">
          <Zap size={13} className="text-amber" />
          <span>Arahkan kursor atau klik pada grafik untuk melihat rincian laba per hari.</span>
        </div>
      </div>
    </div>
  );
};

export default SalesAnalyticsChart;
