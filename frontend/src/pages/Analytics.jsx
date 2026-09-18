import { useEffect, useState } from 'react'
import {
  BarChart, Bar, LineChart, Line, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, ReferenceLine
} from 'recharts'
import { api } from '../api.js'

const MOCK_TRENDS = [
  { month_start:'2025-01-01', total_inflow:98400,  total_outflow:62100, flagged_count:1, transaction_count:210 },
  { month_start:'2025-02-01', total_inflow:112000, total_outflow:74200, flagged_count:2, transaction_count:248 },
  { month_start:'2025-03-01', total_inflow:131000, total_outflow:68400, flagged_count:1, transaction_count:291 },
  { month_start:'2025-04-01', total_inflow:118000, total_outflow:80100, flagged_count:2, transaction_count:267 },
  { month_start:'2025-05-01', total_inflow:143000, total_outflow:71200, flagged_count:0, transaction_count:231 },
]

const BruteTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-[#1a1a1a] border-2 border-[#ff3b00] p-3 shadow-[4px_4px_0_#ff3b00]">
      <p className="text-[10px] font-black uppercase tracking-widest text-[#ff3b00] mb-1">{label}</p>
      {payload.map((p, i) => (
        <p key={i} className="text-xs font-bold text-white">
          {p.name}: {typeof p.value === 'number' && p.value > 100 ? '$' + p.value.toLocaleString() : p.value}
        </p>
      ))}
    </div>
  )
}

export default function Analytics() {
  const [trends, setTrends] = useState(MOCK_TRENDS)

  useEffect(() => {
    api.monthlyTrends().then(d => { if (d?.length) setTrends(d) }).catch(() => {})
  }, [])

  const label = (iso) => new Date(iso).toLocaleString('en-CA', { month: 'short', year: '2-digit' })

  // Net flow = inflow - outflow
  const withNet = trends.map(t => ({
    ...t,
    net_flow: t.total_inflow - t.total_outflow,
    month: label(t.month_start),
  }))

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-4xl font-black tracking-tighter text-[#1a1a1a] uppercase leading-none">
          Analytics.
        </h1>
        <p className="text-sm font-semibold text-[#1a1a1a] opacity-40 mt-2 uppercase tracking-widest">
          Window functions · CTEs · SQL-powered · Jan–May 2025
        </p>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">

        {/* Net cash flow (inflow - outflow) — shows profitability */}
        <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a]">Net Cash Flow</h2>
          <p className="text-xs font-semibold text-[#1a1a1a] opacity-35 uppercase tracking-wide mb-4">Inflow minus Outflow · positive = surplus</p>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={withNet}>
              <CartesianGrid strokeDasharray="4 4" stroke="#e5e5e5" vertical={false} />
              <XAxis dataKey="month" tick={{ fontSize:11, fontWeight:700, fill:'#1a1a1a', opacity:.4 }} />
              <YAxis tickFormatter={(v) => '$'+(v/1000).toFixed(0)+'K'} tick={{ fontSize:11, fontWeight:700, fill:'#1a1a1a', opacity:.4 }} width={55} />
              <Tooltip content={<BruteTooltip />} />
              <ReferenceLine y={0} stroke="#1a1a1a" strokeWidth={2} />
              <Bar dataKey="net_flow" name="Net Flow" radius={[2,2,0,0]}
                fill="#ff3b00"
                label={{ position:'top', fontSize:10, fontWeight:700, fill:'#ff3b00',
                  formatter: (v) => '$'+(v/1000).toFixed(0)+'K' }} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Transaction volume trend with flagged overlay */}
        <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a]">Transaction Volume + Fraud</h2>
          <p className="text-xs font-semibold text-[#1a1a1a] opacity-35 uppercase tracking-wide mb-4">Monthly count · flagged shown separately</p>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={withNet}>
              <CartesianGrid strokeDasharray="4 4" stroke="#e5e5e5" />
              <XAxis dataKey="month" tick={{ fontSize:11, fontWeight:700, fill:'#1a1a1a', opacity:.4 }} />
              <YAxis yAxisId="left"  tick={{ fontSize:11, fontWeight:700, fill:'#1a1a1a', opacity:.4 }} width={40} />
              <YAxis yAxisId="right" orientation="right" tick={{ fontSize:11, fontWeight:700, fill:'#ff3b00', opacity:.6 }} width={30} />
              <Tooltip content={<BruteTooltip />} />
              <Line yAxisId="left"  type="monotone" dataKey="transaction_count" name="Total Txns" stroke="#1a1a1a"  strokeWidth={2.5} dot={{ r:4, fill:'#1a1a1a' }} />
              <Line yAxisId="right" type="monotone" dataKey="flagged_count"     name="Flagged"    stroke="#ff3b00" strokeWidth={2.5} dot={{ r:4, fill:'#ff3b00' }} strokeDasharray="6 3" />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Inflow vs outflow stacked area */}
        <div className="xl:col-span-2 bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a]">Stacked Inflow / Outflow — All Months</h2>
          <p className="text-xs font-semibold text-[#1a1a1a] opacity-35 uppercase tracking-wide mb-4">
            Area chart · powered by vw_MonthlyTransactionSummary + LAG() window function
          </p>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={withNet}>
              <defs>
                <linearGradient id="ag1" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#ff3b00" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#ff3b00" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="ag2" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#1a1a1a" stopOpacity={0.12} />
                  <stop offset="95%" stopColor="#1a1a1a" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="4 4" stroke="#e5e5e5" />
              <XAxis dataKey="month" tick={{ fontSize:11, fontWeight:700, fill:'#1a1a1a', opacity:.4 }} />
              <YAxis tickFormatter={(v) => '$'+(v/1000).toFixed(0)+'K'} tick={{ fontSize:11, fontWeight:700, fill:'#1a1a1a', opacity:.4 }} width={60} />
              <Tooltip content={<BruteTooltip />} />
              <Area type="monotone" dataKey="total_inflow"  name="Inflow"  stroke="#ff3b00" strokeWidth={2.5} fill="url(#ag1)" dot={{ r:4, fill:'#ff3b00', strokeWidth:0 }} />
              <Area type="monotone" dataKey="total_outflow" name="Outflow" stroke="#1a1a1a" strokeWidth={2.5} fill="url(#ag2)" dot={{ r:4, fill:'#1a1a1a', strokeWidth:0 }} strokeOpacity={0.5} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* SQL technique badge strip */}
      <div className="border-2 border-[#1a1a1a] p-5 bg-[#1a1a1a]">
        <p className="text-[10px] font-black uppercase tracking-[0.2em] text-[#ff3b00] mb-3">SQL Techniques Powering This Page</p>
        <div className="flex flex-wrap gap-2">
          {['LAG() Window Function','SUM() OVER PARTITION','NTILE(4) Segmentation','Rolling 3-Month AVG','Z-Score Anomaly Detection','Recursive CTE Amortization','vw_MonthlyTransactionSummary','vw_BranchPerformance'].map(t => (
            <span key={t} className="border border-white border-opacity-20 px-3 py-1 text-[10px] font-black uppercase tracking-widest text-white opacity-60">
              {t}
            </span>
          ))}
        </div>
      </div>
    </div>
  )
}
