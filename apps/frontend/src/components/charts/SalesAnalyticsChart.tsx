import React, { useState, useMemo } from 'react';
import { BarChart2, TrendingUp, Zap } from 'lucide-react';
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
  { label: 'Sen', fullDate: 'Senin, 07 Sep', income: 980000, expense: 220000, ordersCount: 26 },
  { label: 'Sel', fullDate: 'Selasa, 08 Sep', income: 1120000, expense: 180000, ordersCount: 29 },
  { label: 'Rab', fullDate: 'Rabu, 09 Sep', income: 1050000, expense: 350000, ordersCount: 28 },
  { label: 'Kam', fullDate: 'Kamis, 10 Sep', income: 1280000, expense: 160000, ordersCount: 34 },
  { label: 'Jum', fullDate: 'Jumat, 11 Sep', income: 1450000, expense: 420000, ordersCount: 38 },
  { label: 'Sab', fullDate: 'Sabtu, 12 Sep', income: 1850000, expense: 310000, ordersCount: 48 },
  { label: 'Min', fullDate: 'Minggu, 13 Sep (Hari Ini)', income: 1250000, expense: 180000, ordersCount: 32 },
];

const DATA_30_DAYS: ChartDataPoint[] = [
  { label: 'Mgg 1', fullDate: 'Minggu Ke-1 (1-7 Sep)', income: 6800000, expense: 1950000, ordersCount: 184 },
  { label: 'Mgg 2', fullDate: 'Minggu Ke-2 (8-14 Sep)', income: 7400000, expense: 2100000, ordersCount: 198 },
  { label: 'Mgg 3', fullDate: 'Minggu Ke-3 (15-21 Sep)', income: 8100000, expense: 2350000, ordersCount: 215 },
  { label: 'Mgg 4', fullDate: 'Minggu Ke-4 (22-28 Sep)', income: 8980000, expense: 2420000, ordersCount: 236 },
];

export const SalesAnalyticsChart: React.FC<SalesAnalyticsChartProps> = ({
  title = 'Tren Penjualan & Arus Kas',
  subtitle = 'Omzet harian vs pengeluaran kulakan real-time',
}) => {
  const [period, setPeriod] = useState<'7d' | '30d'>('7d');
  const [chartMode, setChartMode] = useState<'line' | 'bar'>('line');
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const activeData = period === '7d' ? DATA_7_DAYS : DATA_30_DAYS;

  // Selected or hovered point
  const isHovering = hoveredIndex !== null;
  const activeIndex = isHovering ? hoveredIndex : activeData.length - 1;
  const activePoint = activeData[activeIndex] || activeData[0];

  // Calculations
  const totalIncome = useMemo(() => activeData.reduce((acc, d) => acc + d.income, 0), [activeData]);
  const totalExpense = useMemo(() => activeData.reduce((acc, d) => acc + d.expense, 0), [activeData]);
  const netProfit = totalIncome - totalExpense;
  const profitMargin = totalIncome > 0 ? ((netProfit / totalIncome) * 100).toFixed(1) : '0';

  const peakPoint = useMemo(() => {
    return activeData.reduce((max, d) => (d.income > max.income ? d : max), activeData[0]);
  }, [activeData]);

  const maxVal = Math.max(...activeData.map((d) => Math.max(d.income, d.expense)), 1000000);
  const safeMax = maxVal * 1.18;

  // SVG dimensions for Line Chart (Responsive & Tidy)
  const svgWidth = 660;
  const svgHeight = 200;
  const paddingLeft = 58;
  const paddingRight = 20;
  const paddingBottom = 28;
  const paddingTop = 22;
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

  const incomeAreaPath =
    points.length > 0
      ? `${incomeLinePath} L ${points[points.length - 1].x} ${svgHeight - paddingBottom} L ${points[0].x} ${
          svgHeight - paddingBottom
        } Z`
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

  const activeNode = points[activeIndex];
  const tooltipXPercent = activeNode ? (activeNode.x / svgWidth) * 100 : 50;
  const tooltipYPos = activeNode ? Math.max(12, Math.min(activeNode.yIncome, activeNode.yExpense) - 10) : 16;

  return (
    <div className="card-base web-chart-container">
      {/* ── 1. Clean Header Row: Title & Action Controls ── */}
      <div className="web-chart-header">
        <div className="web-chart-title-wrap">
          <div className="web-chart-icon-box">
            <TrendingUp size={16} />
          </div>
          <div>
            <h3 className="web-chart-title">{title}</h3>
            <p className="web-chart-subtitle">{subtitle}</p>
          </div>
        </div>

        <div className="web-chart-header-actions">
          {/* Period Selector */}
          <div className="web-chart-period-selector">
            <button
              type="button"
              onClick={() => {
                setPeriod('7d');
                setHoveredIndex(null);
              }}
              className={`period-pill-btn ${period === '7d' ? 'active' : ''}`}
            >
              7 Hari
            </button>
            <button
              type="button"
              onClick={() => {
                setPeriod('30d');
                setHoveredIndex(null);
              }}
              className={`period-pill-btn ${period === '30d' ? 'active' : ''}`}
            >
              30 Hari
            </button>
          </div>

          {/* Chart View Toggle */}
          <div className="web-chart-view-toggle">
            <button
              type="button"
              onClick={() => setChartMode('line')}
              className={`chart-view-btn ${chartMode === 'line' ? 'active' : ''}`}
              title="Grafik Garis"
            >
              <TrendingUp size={13} />
            </button>
            <button
              type="button"
              onClick={() => setChartMode('bar')}
              className={`chart-view-btn ${chartMode === 'bar' ? 'active' : ''}`}
              title="Grafik Batang"
            >
              <BarChart2 size={13} />
            </button>
          </div>
        </div>
      </div>

      {/* ── 2. Integrated Sub-Bar: Legend & Quick Summary ── */}
      <div className="web-chart-subbar">
        <div className="web-chart-legend">
          <div className="legend-item">
            <span className="legend-dot income"></span>
            <span className="legend-label">Omzet Penjualan</span>
          </div>
          <div className="legend-item">
            <span className="legend-dot expense"></span>
            <span className="legend-label">Beban Kulakan</span>
          </div>
        </div>

        <div className="web-chart-quick-metrics">
          <span className="quick-metric-item">
            Total: <strong className="text-emerald">Rp {totalIncome.toLocaleString('id-ID')}</strong>
          </span>
          <span className="quick-metric-divider">•</span>
          <span className="quick-metric-item">
            Laba: <strong className="text-slate">Rp {netProfit.toLocaleString('id-ID')}</strong>
            <span className="margin-tag">({profitMargin}%)</span>
          </span>
        </div>
      </div>

      {/* ── 3. Chart SVG Canvas & Web Floating Tooltip ── */}
      <div
        className="web-chart-canvas-wrapper"
        onMouseLeave={() => setHoveredIndex(null)}
      >
        {/* Floating Web Hover Tooltip */}
        {isHovering && activeNode && (
          <div
            className="web-chart-floating-tooltip"
            style={{
              left: `${tooltipXPercent}%`,
              top: `${tooltipYPos}px`,
            }}
          >
            <div className="tooltip-header-row">
              <span className="tooltip-date">{activePoint.fullDate || activePoint.label}</span>
              {activePoint.ordersCount && (
                <span className="tooltip-orders-badge">{activePoint.ordersCount} Pesanan</span>
              )}
            </div>
            <div className="tooltip-body">
              <div className="tooltip-row">
                <span className="tooltip-dot income"></span>
                <span className="tooltip-label">Omzet:</span>
                <strong className="tooltip-val text-emerald">
                  Rp {activePoint.income.toLocaleString('id-ID')}
                </strong>
              </div>
              <div className="tooltip-row">
                <span className="tooltip-dot expense"></span>
                <span className="tooltip-label">Beban:</span>
                <strong className="tooltip-val text-rose">
                  Rp {activePoint.expense.toLocaleString('id-ID')}
                </strong>
              </div>
              <div className="tooltip-row profit-row">
                <span className="tooltip-dot profit"></span>
                <span className="tooltip-label">Laba Bersih:</span>
                <strong className="tooltip-val text-slate">
                  Rp {(activePoint.income - activePoint.expense).toLocaleString('id-ID')}
                </strong>
              </div>
            </div>
            <div className="tooltip-caret"></div>
          </div>
        )}

        {chartMode === 'line' ? (
          <svg
            viewBox={`0 0 ${svgWidth} ${svgHeight}`}
            className="web-chart-svg"
            preserveAspectRatio="none"
          >
            <defs>
              <linearGradient id="emeraldWebGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#10b981" stopOpacity="0.2" />
                <stop offset="90%" stopColor="#059669" stopOpacity="0.02" />
                <stop offset="100%" stopColor="#059669" stopOpacity="0.0" />
              </linearGradient>
            </defs>

            {/* Horizontal Gridlines & Y-Axis Labels */}
            {yTicks.map((tick, idx) => (
              <g key={idx}>
                <line
                  x1={paddingLeft}
                  y1={tick.yPos}
                  x2={svgWidth - paddingRight}
                  y2={tick.yPos}
                  stroke="#e2e8f0"
                  strokeDasharray={idx === 0 ? '0' : '4 4'}
                  strokeWidth="1"
                />
                <text
                  x={paddingLeft - 8}
                  y={tick.yPos + 4}
                  textAnchor="end"
                  className="web-axis-y-label"
                >
                  {formatYAxis(tick.value)}
                </text>
              </g>
            ))}

            {/* Income Area Fill */}
            <path d={incomeAreaPath} fill="url(#emeraldWebGradient)" />

            {/* Expense Subtle Dashed Path */}
            <path
              d={expenseLinePath}
              fill="none"
              stroke="#f43f5e"
              strokeWidth="1.8"
              strokeDasharray="4 4"
              strokeLinecap="round"
              opacity="0.85"
            />

            {/* Income Main Curved Line */}
            <path
              d={incomeLinePath}
              fill="none"
              stroke="#059669"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />

            {/* Vertical Guideline on Hover */}
            {isHovering && activeNode && (
              <line
                x1={activeNode.x}
                y1={paddingTop}
                x2={activeNode.x}
                y2={svgHeight - paddingBottom}
                stroke="#94a3b8"
                strokeWidth="1"
                strokeDasharray="3 3"
                opacity="0.8"
              />
            )}

            {/* Interactive Data Points */}
            {points.map((p, idx) => {
              const isSelected = activeIndex === idx && isHovering;
              return (
                <g
                  key={idx}
                  className="web-chart-node"
                  onMouseEnter={() => setHoveredIndex(idx)}
                  onClick={() => setHoveredIndex(idx)}
                  style={{ cursor: 'pointer' }}
                >
                  {/* Broad touch/hover target */}
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
                    r={isSelected ? 3.5 : 2}
                    fill="#f43f5e"
                  />

                  {/* Income Outer Ring on Hover */}
                  {isSelected && (
                    <circle
                      cx={p.x}
                      cy={p.yIncome}
                      r="9"
                      fill="#10b981"
                      opacity="0.25"
                    />
                  )}

                  {/* Income Main Dot */}
                  <circle
                    cx={p.x}
                    cy={p.yIncome}
                    r={isSelected ? 5.5 : 3.5}
                    fill={isSelected ? '#059669' : '#ffffff'}
                    stroke="#059669"
                    strokeWidth={isSelected ? 2.5 : 2}
                  />

                  {/* X-Axis Date Label */}
                  <text
                    x={p.x}
                    y={svgHeight - 8}
                    textAnchor="middle"
                    className={`web-axis-x-label ${isSelected ? 'active' : ''}`}
                  >
                    {p.label}
                  </text>
                </g>
              );
            })}
          </svg>
        ) : (
          /* ── Modern Bar Comparison Mode ── */
          <div className="web-bars-container" style={{ paddingLeft: `${paddingLeft}px` }}>
            <div className="web-bars-y-ticks">
              {yTicks.map((tick, idx) => (
                <span
                  key={idx}
                  className="web-bar-y-label"
                  style={{ bottom: `${(tick.value / safeMax) * 100 * 0.72 + 20}%` }}
                >
                  {formatYAxis(tick.value)}
                </span>
              ))}
            </div>

            <div className="web-bars-columns-row">
              {activeData.map((item, idx) => {
                const isSelected = activeIndex === idx && isHovering;
                const incomePct = (item.income / safeMax) * 100;
                const expensePct = (item.expense / safeMax) * 100;

                return (
                  <div
                    key={idx}
                    className={`web-bar-column-group ${isSelected ? 'active' : ''}`}
                    onMouseEnter={() => setHoveredIndex(idx)}
                    onClick={() => setHoveredIndex(idx)}
                  >
                    <div className="web-bar-pillars">
                      {/* Income Bar */}
                      <div
                        className="web-bar-pillar income-bar"
                        style={{ height: `${Math.max(incomePct, 6)}%` }}
                        title={`Omzet: Rp ${item.income.toLocaleString('id-ID')}`}
                      ></div>

                      {/* Expense Bar */}
                      <div
                        className="web-bar-pillar expense-bar"
                        style={{ height: `${Math.max(expensePct, 4)}%` }}
                        title={`Beban: Rp ${item.expense.toLocaleString('id-ID')}`}
                      ></div>
                    </div>

                    <span className={`web-bar-label ${isSelected ? 'active' : ''}`}>
                      {item.label}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* ── 4. Compact Web Chart Footer ── */}
      <div className="web-chart-footer">
        <div className="chart-footer-hint">
          <Zap size={12} className="hint-icon" />
          <span>Arahkan kursor ke titik grafik untuk detail harian</span>
        </div>
        <div className="chart-footer-peak">
          Puncak: <strong>{peakPoint.label} (Rp {(peakPoint.income / 1000000).toFixed(2)} Jt)</strong>
        </div>
      </div>
    </div>
  );
};

export default SalesAnalyticsChart;
