import { useEffect, useState } from 'react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { api } from '../api.js'

const MOCK = [
  { branch_name:'Downtown Toronto Main', city:'Toronto',     total_accounts:18, total_customers:12, total_deposits_on_hand:820000, total_transactions:89, active_loans:4, total_loan_balance:2442000, open_fraud_alerts:2 },
  { branch_name:'Mississauga City Centre',city:'Mississauga',total_accounts:12, total_customers:8,  total_deposits_on_hand:510000, total_transactions:61, active_loans:3, total_loan_balance:480000,  open_fraud_alerts:1 },
  { branch_name:'North York Yonge',      city:'North York', total_accounts:9,  total_customers:6,  total_deposits_on_hand:450000, total_transactions:52, active_loans:1, total_loan_balance:22875,   open_fraud_alerts:0 },
  { branch_name:'Scarborough East',      city:'Scarborough',total_accounts:8,  total_customers:5,  total_deposits_on_hand:340000, total_transactions:38, active_loans:1, total_loan_balance:21400,   open_fraud_alerts:1 },
  { branch_name:'Brampton Bramalea',     city:'Brampton',   total_accounts:7,  total_customers:5,  total_deposits_on_hand:290000, total_transactions:32, active_loans:1, total_loan_balance:4675,    open_fraud_alerts:0 },
]

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

export default function Branches() {
  const [branches, setBranches] = useState(MOCK)

  useEffect(() => {
    api.branches().then(d => { if (d?.length) setBranches(d) }).catch(() => {})
  }, [])

  const chartData = branches.map(b => ({
    name: b.city,
    deposits: b.total_deposits_on_hand,
    loans: b.total_loan_balance,
  }))

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-4xl font-black tracking-tighter text-[#1a1a1a] uppercase leading-none">
          Branch<br />Performance.
        </h1>
        <p className="text-sm font-semibold text-[#1a1a1a] opacity-40 mt-2 uppercase tracking-widest">
          {branches.length} GTA branches · powered by vw_BranchPerformance
        </p>
      </div>

      {/* Branch deposit comparison chart */}
      <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
        <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a] mb-4">Deposits vs. Loan Book by Branch</h2>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={chartData} margin={{ top:4, right:4, left:0, bottom:0 }}>
            <CartesianGrid strokeDasharray="4 4" stroke="#e5e5e5" vertical={false} />
            <XAxis dataKey="name" tick={{ fontSize:11, fontWeight:700, fill:'#1a1a1a', opacity:.5 }} />
            <YAxis tickFormatter={(v) => '$'+(v/1000).toFixed(0)+'K'} tick={{ fontSize:11, fontWeight:700, fill:'#1a1a1a', opacity:.4 }} width={60} />
            <Tooltip content={<BruteTooltip />} />
            <Bar dataKey="deposits" name="Deposits"  fill="#ff3b00" radius={[2,2,0,0]} />
            <Bar dataKey="loans"    name="Loan Book" fill="#1a1a1a" radius={[2,2,0,0]} opacity={0.4} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Branch cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {branches.map((b, i) => (
          <div key={i} className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
            <div className="flex items-start justify-between mb-3">
              <div>
                <p className="text-[9px] font-black uppercase tracking-[0.15em] text-[#1a1a1a] opacity-30">{b.city}</p>
                <h3 className="text-sm font-black uppercase tracking-tight text-[#1a1a1a] leading-tight mt-0.5">
                  {b.branch_name.replace(b.city, '').trim() || b.branch_name}
                </h3>
              </div>
              {b.open_fraud_alerts > 0 && (
                <span className="border-2 border-[#ff3b00] text-[#ff3b00] text-[9px] font-black uppercase tracking-wider px-2 py-0.5">
                  {b.open_fraud_alerts} Alert{b.open_fraud_alerts > 1 ? 's' : ''}
                </span>
              )}
            </div>
            <div className="grid grid-cols-2 gap-3 mt-3 pt-3 border-t-2 border-[#1a1a1a] border-opacity-10">
              {[
                { l:'Deposits',    v:'$'+Number(b.total_deposits_on_hand).toLocaleString() },
                { l:'Customers',   v:b.total_customers },
                { l:'Accounts',    v:b.total_accounts },
                { l:'Transactions',v:b.total_transactions },
              ].map(({ l, v }) => (
                <div key={l}>
                  <p className="text-[9px] font-black uppercase tracking-[0.15em] text-[#1a1a1a] opacity-30">{l}</p>
                  <p className="text-lg font-black text-[#1a1a1a] mt-0.5">{v}</p>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
