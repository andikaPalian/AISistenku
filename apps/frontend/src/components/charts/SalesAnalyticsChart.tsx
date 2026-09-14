import React, { useState, useMemo } from 'react';
import {
  TrendingUp,
  BarChart2,
  Zap,
  ArrowUpRight,
  ArrowDownRight,
  Calendar,
  ShoppingBag,
  Activity,
  Layers,
} from 'lucide-react';
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
  data7d?: ChartDataPoint[];
  data30d?: ChartDataPoint[];
}

const DEFAULT_7_DAYS: ChartDataPoint[] = [
  { label: 'Sen', fullDate: 'Senin, 07 Sep', income: 980000, expense: 220000, ordersCount: 26 },
  { label: 'Sel', fullDate: 'Selasa, 08 Sep', income: 1120000, expense: 180000, ordersCount: 29 },
  { label: 'Rab', fullDate: 'Rabu, 09 Sep', income: 1050000, expense: 350000, ordersCount: 28 },
  { label: 'Kam', fullDate: 'Kamis, 10 Sep', income: 1280000, expense: 160000, ordersCount: 34 },
  { label: 'Jum', fullDate: 'Jumat, 11 Sep', income: 1450000, expense: 420000, ordersCount: 38 },
  { label: 'Sab', fullDate: 'Sabtu, 12 Sep', income: 1850000, expense: 310000, ordersCount: 48 },
  { label: 'Min', fullDate: 'Minggu, 13 Sep (Hari Ini)', income: 1250000, expense: 180000, ordersCount: 32 },
];

const DEFAULT_30_DAYS: ChartDataPoint[] = [
  { label: 'Mgg 1', fullDate: 'Minggu Ke-1 (01 - 07 Sep)', income: 6800000, expense: 1950000, ordersCount: 184 },
  { label: 'Mgg 2', fullDate: 'Minggu Ke-2 (08 - 14 Sep)', income: 7400000, expense: 2100000, ordersCount: 198 },
  { label: 'Mgg 3', fullDate: 'Minggu Ke-3 (15 - 21 Sep)', income: 8100000, expense: 2350000, ordersCount: 215 },
  { label: 'Mgg 4', fullDate: 'Minggu Ke-4 (22 - 28 Sep)', income: 8980000, expense: 2420000, ordersCount: 236 },
];

export const SalesAnalyticsChart: React.FC<SalesAnalyticsChartProps> = ({
  title = 'Grafik Penjualan & Arus Kas',
  subtitle = 'Analisis perbandingan omzet penjualan vs pengeluaran operasional toko',
  data7d = DEFAULT_7_DAYS,
  data30d = DEFAULT_30_DAYS,
}) => {
  const [period, setPeriod] = useState<'7d' | '30d'>('7d');
  const [chartMode, setChartMode] = useState<'line' | 'bar'>('line');
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const activeData = period === '7d' ? data7d : data30d;

  // Selected or hovered point
  const isHovering = hoveredIndex !== null;
  const activeIndex = isHovering ? hoveredIndex : activeData.length - 1;
  const activePoint = activeData[activeIndex] || activeData[0];

  // Financial aggregates
  const totalIncome = useMemo(() => activeData.reduce((acc, d) => acc + d.income, 0), [activeData]);
  const totalExpense = useMemo(() => activeData.reduce((acc, d) => acc + d.expense, 0), [activeData]);
  const netProfit = totalIncome - totalExpense;
  const profitMargin = totalIncome > 0 ? ((netProfit / totalIncome) * 100).toFixed(1) : '0';
  const totalOrders = useMemo(() => activeData.reduce((acc, d) => acc + (d.ordersCount || 0), 0), [activeData]);

  const peakPoint = useMemo(() => {
    return activeData.reduce((max, d) => (d.income > max.income ? d : max), activeData[0]);
  }, [activeData]);

  // Clean rounded Y-Axis scaling calculation (eliminates strange fractions like 720rb or 2.2Jt)
  const calculateCleanMax = (val: number) => {
    if (val <= 1000000) return 1000000;
    if (val <= 1500000) return 1500000;
    if (val <= 2000000) return 2000000;
    if (val <= 3000000) return 3000000;
    if (val <= 5000000) return 5000000;
    if (val <= 10000000) return 10000000;
    const mag = Math.pow(10, Math.floor(Math.log10(val)));
    return Math.ceil((val * 1.05) / mag) * mag;
  };

  const maxRaw = Math.max(...activeData.map((d) => Math.max(d.income, d.expense)), 1000000);
  const cleanMax = calculateCleanMax(maxRaw);

  // SVG dimensions for high-precision plotting
  const svgWidth = 720;
  const svgHeight = 220;
  const paddingLeft = 60;
  const paddingRight = 24;
  const paddingBottom = 32;
  const paddingTop = 22;
  const plotWidth = svgWidth - paddingLeft - paddingRight;
  const plotHeight = svgHeight - paddingBottom - paddingTop;

  // Normalized data coordinates
  const points = activeData.map((d, i) => {
    const x = paddingLeft + (i / (activeData.length - 1)) * plotWidth;
    const yIncome = paddingTop + plotHeight - (d.income / cleanMax) * plotHeight;
    const yExpense = paddingTop + plotHeight - (d.expense / cleanMax) * plotHeight;
    return { x, yIncome, yExpense, ...d };
  });

  // Smooth bezier curve generator
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

  const expenseAreaPath =
    points.length > 0
      ? `${expenseLinePath} L ${points[points.length - 1].x} ${svgHeight - paddingBottom} L ${points[0].x} ${
          svgHeight - paddingBottom
        } Z`
      : '';

  // Clean Y-axis ticks formatting
  const formatYAxis = (val: number) => {
    if (val >= 1000000) {
      const millions = val / 1000000;
      return `${Number.isInteger(millions) ? millions : millions.toFixed(1)} Jt`;
    }
    if (val >= 1000) return `${Math.round(val / 1000)} rb`;
    return '0';
  };

  const yTicks = [0, 0.25, 0.5, 0.75, 1].map((ratio) => {
    const value = cleanMax * ratio;
    const yPos = paddingTop + plotHeight - ratio * plotHeight;
    return { value, yPos };
  });

  const activeNode = points[activeIndex];
  const tooltipXPercent = activeNode ? (activeNode.x / svgWidth) * 100 : 50;
  const tooltipYPos = activeNode ? Math.max(16, Math.min(activeNode.yIncome, activeNode.yExpense) - 12) : 20;

  return (
    <div className="card-base modern-sales-chart-card">
      {/* ── 1. Header: Title, Live Status & Segmented Controls ── */}
      <div className="chart-card-top-bar">
        <div className="chart-title-block">
          <div className="chart-icon-box">
            <Activity size={18} />
          </div>
          <div>
            <h3 className="chart-heading">{title}</h3>
            <p className="chart-subheading">{subtitle}</p>
          </div>
        </div>

        <div className="chart-controls-cluster">
          {/* Period Selector (7 Hari / 30 Hari) */}
          <div className="chart-segmented-control">
            <button
              type="button"
              onClick={() => {
                setPeriod('7d');
                setHoveredIndex(null);
              }}
              className={`segmented-chip ${period === '7d' ? 'active' : ''}`}
            >
              7 Hari
            </button>
            <button
              type="button"
              onClick={() => {
                setPeriod('30d');
                setHoveredIndex(null);
              }}
              className={`segmented-chip ${period === '30d' ? 'active' : ''}`}
            >
              30 Hari
            </button>
          </div>

          {/* View Toggle (Line Area vs Dual Bar) */}
          <div className="chart-segmented-control view-mode">
            <button
              type="button"
              onClick={() => setChartMode('line')}
              className={`segmented-chip icon-only ${chartMode === 'line' ? 'active' : ''}`}
              title="Tampilan Grafik Garis & Area"
            >
              <TrendingUp size={14} />
            </button>
            <button
              type="button"
              onClick={() => setChartMode('bar')}
              className={`segmented-chip icon-only ${chartMode === 'bar' ? 'active' : ''}`}
              title="Tampilan Grafik Batang Perbandingan"
            >
              <BarChart2 size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* ── 2. Executive Stat Strip: Key Numbers & Legend ── */}
      <div className="chart-stat-strip">
        <div className="chart-legend-row">
          <div className="legend-badge income">
            <span className="legend-indicator-dot green"></span>
            <span className="legend-title">Omzet Kasir</span>
          </div>
          <div className="legend-badge expense">
            <span className="legend-indicator-dot red"></span>
            <span className="legend-title">Beban Kulakan</span>
          </div>
        </div>

        <div className="chart-quick-metrics-row">
          <div className="quick-metric-tile">
            <span className="metric-tag">Total Omzet:</span>
            <span className="metric-figure text-emerald">Rp {totalIncome.toLocaleString('id-ID')}</span>
          </div>
          <span className="quick-metric-dot">•</span>
          <div className="quick-metric-tile">
            <span className="metric-tag">Total Beban:</span>
            <span className="metric-figure text-coral">Rp {totalExpense.toLocaleString('id-ID')}</span>
          </div>
          <span className="quick-metric-dot">•</span>
          <div className="quick-metric-tile">
            <span className="metric-tag">Laba Bersih:</span>
            <span className="metric-figure text-dark">Rp {netProfit.toLocaleString('id-ID')}</span>
            <span className="margin-chip-pill">({profitMargin}% Margin)</span>
          </div>
        </div>
      </div>

      {/* ── 3. High-Craft SVG Canvas & Floating Card Tooltip ── */}
      <div
        className="chart-canvas-container"
        onMouseLeave={() => setHoveredIndex(null)}
      >
        {/* Modern Floating Hover Tooltip */}
        {isHovering && activeNode && (
          <div
            className="chart-floating-popover"
            style={{
              left: `${tooltipXPercent}%`,
              top: `${tooltipYPos}px`,
            }}
          >
            <div className="popover-header">
              <div className="popover-date-wrap">
                <Calendar size={12} className="text-muted" />
                <span className="popover-date-text">{activePoint.fullDate || activePoint.label}</span>
              </div>
              {activePoint.ordersCount && (
                <span className="popover-badge-orders">{activePoint.ordersCount} Pesanan</span>
              )}
            </div>

            <div className="popover-body">
              <div className="popover-data-row">
                <div className="popover-label-group">
                  <span className="data-dot green"></span>
                  <span>Omzet:</span>
                </div>
                <strong className="data-val text-emerald">
                  Rp {activePoint.income.toLocaleString('id-ID')}
                </strong>
              </div>

              <div className="popover-data-row">
                <div className="popover-label-group">
                  <span className="data-dot red"></span>
                  <span>Beban Kulakan:</span>
                </div>
                <strong className="data-val text-coral">
                  Rp {activePoint.expense.toLocaleString('id-ID')}
                </strong>
              </div>

              <div className="popover-divider"></div>

              <div className="popover-data-row highlight">
                <div className="popover-label-group">
                  <span className="data-dot obsidian"></span>
                  <span>Laba Bersih:</span>
                </div>
                <strong className="data-val text-dark">
                  Rp {(activePoint.income - activePoint.expense).toLocaleString('id-ID')}
                </strong>
              </div>
            </div>
            <div className="popover-arrow"></div>
          </div>
        )}

        {chartMode === 'line' ? (
          <svg
            viewBox={`0 0 ${svgWidth} ${svgHeight}`}
            className="chart-svg-element"
            preserveAspectRatio="none"
          >
            <defs>
              {/* Luxury Emerald Gradient */}
              <linearGradient id="modernEmeraldGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#10b981" stopOpacity="0.25" />
                <stop offset="60%" stopColor="#10b981" stopOpacity="0.05" />
                <stop offset="100%" stopColor="#ffffff" stopOpacity="0.0" />
              </linearGradient>

              {/* Subtle Rose Gradient */}
              <linearGradient id="modernRoseGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#f43f5e" stopOpacity="0.08" />
                <stop offset="100%" stopColor="#ffffff" stopOpacity="0.0" />
              </linearGradient>
            </defs>

            {/* Horizontal Precision Gridlines & Y-Axis Numbers */}
            {yTicks.map((tick, idx) => (
              <g key={idx}>
                <line
                  x1={paddingLeft}
                  y1={tick.yPos}
                  x2={svgWidth - paddingRight}
                  y2={tick.yPos}
                  stroke="#f1f5f9"
                  strokeWidth={idx === 0 ? '1.5' : '1'}
                />
                <text
                  x={paddingLeft - 10}
                  y={tick.yPos + 4}
                  textAnchor="end"
                  className="chart-y-axis-text"
                >
                  {formatYAxis(tick.value)}
                </text>
              </g>
            ))}

            {/* Expense Subtle Area Underlay */}
            <path d={expenseAreaPath} fill="url(#modernRoseGradient)" />

            {/* Income Rich Emerald Gradient Area */}
            <path d={incomeAreaPath} fill="url(#modernEmeraldGradient)" />

            {/* Expense Smooth Solid Curve (No ugly caterpillar dashes!) */}
            <path
              d={expenseLinePath}
              fill="none"
              stroke="#f43f5e"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              opacity="0.85"
            />

            {/* Income Primary Vibrant Stroke */}
            <path
              d={incomeLinePath}
              fill="none"
              stroke="#10b981"
              strokeWidth="3"
              strokeLinecap="round"
              strokeLinejoin="round"
            />

            {/* Vertical Hairline Scanner on Hover */}
            {isHovering && activeNode && (
              <line
                x1={activeNode.x}
                y1={paddingTop}
                x2={activeNode.x}
                y2={svgHeight - paddingBottom}
                stroke="#cbd5e1"
                strokeWidth="1.2"
                strokeDasharray="3 3"
              />
            )}

            {/* Interactive Data Nodes */}
            {points.map((p, idx) => {
              const isSelected = activeIndex === idx && isHovering;

              return (
                <g
                  key={idx}
                  className="chart-interactive-node"
                  onMouseEnter={() => setHoveredIndex(idx)}
                  onClick={() => setHoveredIndex(idx)}
                  style={{ cursor: 'pointer' }}
                >
                  {/* Broad transparent touch hit target */}
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
                    fill="#f43f5e"
                    stroke="#ffffff"
                    strokeWidth="1.5"
                  />

                  {/* Income Outer Halo on Select */}
                  {isSelected && (
                    <circle
                      cx={p.x}
                      cy={p.yIncome}
                      r="10"
                      fill="#10b981"
                      opacity="0.22"
                    />
                  )}

                  {/* Income Main Point */}
                  <circle
                    cx={p.x}
                    cy={p.yIncome}
                    r={isSelected ? 5.5 : 3.5}
                    fill={isSelected ? '#059669' : '#ffffff'}
                    stroke="#10b981"
                    strokeWidth={isSelected ? 2.5 : 2}
                  />

                  {/* X-Axis Day Text */}
                  <text
                    x={p.x}
                    y={svgHeight - 10}
                    textAnchor="middle"
                    className={`chart-x-axis-text ${isSelected ? 'active' : ''}`}
                  >
                    {p.label}
                  </text>
                </g>
              );
            })}
          </svg>
        ) : (
          /* ── Modern Dual-Pillar Comparison Bar Mode ── */
          <div className="chart-bars-layout" style={{ paddingLeft: `${paddingLeft}px` }}>
            <div className="bars-y-ticks-scale">
              {yTicks.map((tick, idx) => (
                <span
                  key={idx}
                  className="bar-y-label-item"
                  style={{ bottom: `${(tick.value / cleanMax) * 100 * 0.72 + 22}%` }}
                >
                  {formatYAxis(tick.value)}
                </span>
              ))}
            </div>

            <div className="bars-columns-track">
              {activeData.map((item, idx) => {
                const isSelected = activeIndex === idx && isHovering;
                const incomePct = (item.income / cleanMax) * 100;
                const expensePct = (item.expense / cleanMax) * 100;

                return (
                  <div
                    key={idx}
                    className={`bar-group-slot ${isSelected ? 'active' : ''}`}
                    onMouseEnter={() => setHoveredIndex(idx)}
                    onClick={() => setHoveredIndex(idx)}
                  >
                    <div className="bar-pillars-wrap">
                      {/* Income Bar */}
                      <div
                        className="bar-pillar income-pillar"
                        style={{ height: `${Math.max(incomePct, 8)}%` }}
                        title={`Omzet: Rp ${item.income.toLocaleString('id-ID')}`}
                      ></div>

                      {/* Expense Bar */}
                      <div
                        className="bar-pillar expense-pillar"
                        style={{ height: `${Math.max(expensePct, 5)}%` }}
                        title={`Beban: Rp ${item.expense.toLocaleString('id-ID')}`}
                      ></div>
                    </div>

                    <span className={`bar-slot-label ${isSelected ? 'active' : ''}`}>
                      {item.label}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* ── 4. Intelligent Footer: Peak Day Insight & Daily Average ── */}
      <div className="chart-footer-insight-bar">
        <div className="footer-insight-left">
          <Zap size={14} className="insight-zap-icon" />
          <span>
            Puncak Omzet:{' '}
            <strong>
              {peakPoint.fullDate || peakPoint.label} (Rp {peakPoint.income.toLocaleString('id-ID')})
            </strong>{' '}
            • Tercatat {peakPoint.ordersCount || 0} pesanan kasir
          </span>
        </div>

        <div className="footer-insight-right">
          <span>
            Rata-rata Harian: <strong>Rp {Math.round(totalIncome / activeData.length).toLocaleString('id-ID')}</strong>
          </span>
        </div>
      </div>
    </div>
  );
};

export default SalesAnalyticsChart;
