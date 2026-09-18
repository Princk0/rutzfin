import { useEffect, useState } from 'react'
import {
  BarChart, Bar, LineChart, Line, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer, PieChart, Pie, Cell
} from 'recharts'
import KPICard   from '../components/KPICard.jsx'
import ThreeScene from '../components/ThreeScene.jsx'
import { api }   from '../api.js'

const fmt  = (n) => n == null ? '—' : Number(n).toLocaleString('en-CA', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
const fmtM = (n) => n == null ? '—' : '$' + (Number(n) / 1000000).toFixed(2) + 'M'

// Fallback data for when API isn't connected yet
const MOCK_KPI = {
  total_customers: 30, total_accounts: 45,
  total_deposits: 2410000, transactions_30d: 1247,
  open_fraud_alerts: 4, active_loans: 10, total_loan_book: 3280000,
}
const MOCK_TRENDS = [
  { month_start: '2025-01-01', total_inflow: 98400, total_outflow: 62100, transaction_count: 210 },
  { month_start: '2025-02-01', total_inflow: 112000, total_outflow: 74200, transaction_count: 248 },
  { month_start: '2025-03-01', total_inflow: 131000, total_outflow: 68400, transaction_count: 291 },
  { month_start: '2025-04-01', total_inflow: 118000, total_outflow: 80100, transaction_count: 267 },
  { month_start: '2025-05-01', total_inflow: 143000, total_outflow: 71200, transaction_count: 231 },
]
const MOCK_SEGMENTS = [
  { segment: 'Platinum', customer_count: 7,  segment_total_balance: 1100000 },
  { segment: 'Gold',     customer_count: 8,  segment_total_balance: 680000 },
  { segment: 'Silver',   customer_count: 8,  segment_total_balance: 420000 },
  { segment: 'Standard', customer_count: 7,  segment_total_balance: 210000 },
]
const SEG_COLORS = ['#ff3b00', '#1a1a1a', '#888', '#bbb']

// Custom tooltip
const BruteTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-[#1a1a1a] border-2 border-[#ff3b00] p-3 shadow-[4px_4px_0_#ff3b00]">
      <p className="text-[10px] font-black uppercase tracking-widest text-[#ff3b00] mb-1">{label}</p>
      {payload.map((p, i) => (
        <p key={i} className="text-xs font-bold text-white">
          {p.name}: ${Number(p.value).toLocaleString()}
        </p>
      ))}
    </div>
  )
}

export default function Overview() {
  const [kpi,      setKpi]      = useState(MOCK_KPI)
  const [trends,   setTrends]   = useState(MOCK_TRENDS)
  const [segments, setSegments] = useState(MOCK_SEGMENTS)
  const [loading,  setLoading]  = useState(true)

  useEffect(() => {
    Promise.allSettled([
      api.dashboard(),
      api.monthlyTrends(),
      api.customerSegments(),
    ]).then(([kpiRes, trendsRes, segRes]) => {
      if (kpiRes.status      === 'fulfilled') setKpi(kpiRes.value)
      if (trendsRes.status   === 'fulfilled') setTrends(trendsRes.value)
      if (segRes.status      === 'fulfilled') setSegments(segRes.value)
    }).finally(() => setLoading(false))
  }, [])

  const monthLabel = (iso) =>
    new Date(iso).toLocaleString('en-CA', { month: 'short', year: '2-digit' })

  return (
    <div className="space-y-6">
      {/* ── Page title ── */}
      <div>
        <h1 className="text-4xl font-black tracking-tighter text-[#1a1a1a] uppercase leading-none">
          Banking<br />Intelligence.
        </h1>
        <p className="text-sm font-semibold text-[#1a1a1a] opacity-40 mt-2 uppercase tracking-widest">
          5 branches · {fmt(kpi.total_customers)} customers · Live data
        </p>
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
        <KPICard label="Total Deposits"     value={fmtM(kpi.total_deposits)}     trend="↑ +3.2% MOM"        color="#ff3b00" />
        <KPICard label="Transactions (30d)" value={fmt(kpi.transactions_30d)}    trend="↑ +8.1% vs prior"   color="#1a1a1a" />
        <KPICard label="Active Loans"       value={fmt(kpi.active_loans)}        sub={fmtM(kpi.total_loan_book) + ' book'} color="#888" />
        <KPICard label="Open Fraud Alerts"  value={fmt(kpi.open_fraud_alerts)}   trend={kpi.open_fraud_alerts > 0 ? '!! Needs review' : '✓ Clear'} color="#ff3b00" />
      </div>

      {/* ── Charts row ── */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">

        {/* Monthly inflow vs outflow — spans 2 cols */}
        <div className="xl:col-span-2 bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
          <div className="flex items-baseline justify-between mb-4">
            <div>
              <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a]">
                Monthly Transaction Volume
              </h2>
              <p className="text-xs font-semibold text-[#1a1a1a] opacity-35 uppercase tracking-wide mt-0.5">
                Inflow vs. Outflow · Jan – May 2025
              </p>
            </div>
            <span className="text-[10px] font-black uppercase tracking-widest border-2 border-[#1a1a1a] px-2 py-0.5 text-[#1a1a1a] opacity-40">
              All Accounts
            </span>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={trends} margin={{ top: 4, right: 4, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="inflowGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#ff3b00" stopOpacity={0.25} />
                  <stop offset="95%" stopColor="#ff3b00" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="outflowGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#1a1a1a" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#1a1a1a" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="4 4" stroke="#e5e5e5" />
              <XAxis
                dataKey="month_start"
                tickFormatter={monthLabel}
                tick={{ fontSize: 11, fontWeight: 700, fill: '#1a1a1a', opacity: 0.4 }}
              />
              <YAxis
                tickFormatter={(v) => '$' + (v/1000).toFixed(0) + 'K'}
                tick={{ fontSize: 11, fontWeight: 700, fill: '#1a1a1a', opacity: 0.4 }}
                width={60}
              />
              <Tooltip content={<BruteTooltip />} />
              <Legend wrapperStyle={{ fontSize: 11, fontWeight: 700 }} />
              <Area type="monotone" dataKey="total_inflow"  name="Inflow"  stroke="#ff3b00" strokeWidth={2.5} fill="url(#inflowGrad)"  dot={{ fill: '#ff3b00', r: 4, strokeWidth: 0 }} />
              <Area type="monotone" dataKey="total_outflow" name="Outflow" stroke="#1a1a1a" strokeWidth={2.5} fill="url(#outflowGrad)" dot={{ fill: '#1a1a1a', r: 4, strokeWidth: 0 }} strokeOpacity={0.5} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Customer Segments donut */}
        <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a] mb-1">
            Customer Segments
          </h2>
          <p className="text-xs font-semibold text-[#1a1a1a] opacity-35 uppercase tracking-wide mb-4">
            By total deposits
          </p>
          <ResponsiveContainer width="100%" height={140}>
            <PieChart>
              <Pie
                data={segments}
                dataKey="segment_total_balance"
                nameKey="segment"
                cx="50%" cy="50%"
                outerRadius={60} innerRadius={30}
                strokeWidth={2} stroke="#f5f0e8"
              >
                {segments.map((_, i) => (
                  <Cell key={i} fill={SEG_COLORS[i % SEG_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip formatter={(v) => '$' + Number(v).toLocaleString()} />
            </PieChart>
          </ResponsiveContainer>
          {/* Legend */}
          <div className="space-y-1 mt-2">
            {segments.map((s, i) => (
              <div key={s.segment} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 border border-[#1a1a1a]" style={{ background: SEG_COLORS[i] }} />
                  <span className="font-black uppercase tracking-wide text-[#1a1a1a] opacity-60">{s.segment}</span>
                </div>
                <span className="font-black text-[#1a1a1a]">{s.customer_count} customers</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── 3D Branch Visualization ── */}
      <div className="bg-[#1a1a1a] border-2 border-[#1a1a1a] shadow-[4px_4px_0_#ff3b00] overflow-hidden">
        <div className="flex items-center justify-between px-5 py-3 border-b border-[#ff3b00] border-opacity-30">
          <div>
            <h2 className="text-sm font-black uppercase tracking-widest text-white">
              Branch Deposit Overview
            </h2>
            <p className="text-xs font-semibold text-white opacity-30 uppercase tracking-wide mt-0.5">
              3D visualization · 5 GTA branches · Deposits on hand
            </p>
          </div>
          <span className="text-[10px] font-black uppercase tracking-widest border border-[#ff3b00] border-opacity-50 px-2 py-0.5 text-[#ff3b00]">
            Three.js
          </span>
        </div>
        <div style={{ height: 300 }}>
          <ThreeScene />
        </div>
      </div>

      {/* ── Monthly bar chart (transaction count) ── */}
      <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
        <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a] mb-4">
          Transaction Count by Month
        </h2>
        <ResponsiveContainer width="100%" height={160}>
          <BarChart data={trends} margin={{ top: 4, right: 4, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="4 4" stroke="#e5e5e5" vertical={false} />
            <XAxis
              dataKey="month_start"
              tickFormatter={monthLabel}
              tick={{ fontSize: 11, fontWeight: 700, fill: '#1a1a1a', opacity: 0.4 }}
            />
            <YAxis
              tick={{ fontSize: 11, fontWeight: 700, fill: '#1a1a1a', opacity: 0.4 }}
              width={40}
            />
            <Tooltip content={<BruteTooltip />} />
            <Bar dataKey="transaction_count" name="Transactions" fill="#ff3b00" radius={[2, 2, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
