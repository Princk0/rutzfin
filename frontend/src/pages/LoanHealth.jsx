import { useEffect, useState } from 'react'
import { RadarChart, Radar, PolarGrid, PolarAngleAxis, ResponsiveContainer, Tooltip } from 'recharts'
import { api } from '../api.js'

const MOCK = [
  { loan_id:1,  loan_type:'Personal',  customer_name:'Amara Okonkwo',    principal_amount:15000,    outstanding_balance:5748,    interest_rate_pct:6.99, monthly_payment:463.18, months_remaining:12, pct_paid_off:61.7, late_payments:0, max_days_late:0,  risk_rating:'Low' },
  { loan_id:2,  loan_type:'Mortgage',  customer_name:'James MacPherson',  principal_amount:750000,   outstanding_balance:692000,  interest_rate_pct:5.49, monthly_payment:4847.18,months_remaining:234,pct_paid_off:7.7,  late_payments:0, max_days_late:0,  risk_rating:'Low' },
  { loan_id:3,  loan_type:'Auto',      customer_name:'David Nguyen',      principal_amount:32000,    outstanding_balance:21400,   interest_rate_pct:5.99, monthly_payment:618.17, months_remaining:33, pct_paid_off:33.1, late_payments:2, max_days_late:7,  risk_rating:'Medium' },
  { loan_id:4,  loan_type:'Mortgage',  customer_name:'Michael Chen',      principal_amount:1200000,  outstanding_balance:1050000, interest_rate_pct:4.79, monthly_payment:6914.63,months_remaining:215,pct_paid_off:12.5, late_payments:0, max_days_late:0,  risk_rating:'Low' },
  { loan_id:5,  loan_type:'Personal',  customer_name:'Raj Patel',         principal_amount:20000,    outstanding_balance:15725,   interest_rate_pct:7.49, monthly_payment:484.39, months_remaining:32, pct_paid_off:21.4, late_payments:0, max_days_late:0,  risk_rating:'Low' },
  { loan_id:6,  loan_type:'Mortgage',  customer_name:'Tyler Brooks',      principal_amount:680000,   outstanding_balance:618000,  interest_rate_pct:5.29, monthly_payment:4328.72,months_remaining:209,pct_paid_off:9.1,  late_payments:0, max_days_late:0,  risk_rating:'Low' },
  { loan_id:7,  loan_type:'Auto',      customer_name:'Omar Diallo',       principal_amount:28000,    outstanding_balance:20800,   interest_rate_pct:6.19, monthly_payment:541.22, months_remaining:38, pct_paid_off:25.7, late_payments:0, max_days_late:0,  risk_rating:'Low' },
  { loan_id:8,  loan_type:'Mortgage',  customer_name:'Andre Beaumont',    principal_amount:900000,   outstanding_balance:780000,  interest_rate_pct:4.59, monthly_payment:5008.81,months_remaining:195,pct_paid_off:13.3, late_payments:0, max_days_late:0,  risk_rating:'Low' },
  { loan_id:9,  loan_type:'Student',   customer_name:'Nathan Griffiths',  principal_amount:25000,    outstanding_balance:22875,   interest_rate_pct:4.99, monthly_payment:264.72, months_remaining:89, pct_paid_off:8.5,  late_payments:1, max_days_late:14, risk_rating:'Medium' },
  { loan_id:10, loan_type:'Personal',  customer_name:'Sofia Petrov',      principal_amount:8000,     outstanding_balance:4675,    interest_rate_pct:8.49, monthly_payment:364.55, months_remaining:9,  pct_paid_off:41.6, late_payments:2, max_days_late:27, risk_rating:'High' },
]

const RISK = {
  Low:      'border-green-600 text-green-600',
  Medium:   'border-orange-500 text-orange-500',
  High:     'border-red-600 text-red-600',
  Critical: 'border-red-800 text-red-800',
}

export default function LoanHealth() {
  const [loans, setLoans] = useState(MOCK)

  useEffect(() => {
    api.loanHealth().then(d => { if (d?.length) setLoans(d) }).catch(() => {})
  }, [])

  const radarData = [
    { metric: 'On-Time',  value: Math.round(100 * loans.filter(l => l.late_payments === 0).length / loans.length) },
    { metric: 'Low Risk', value: Math.round(100 * loans.filter(l => l.risk_rating === 'Low').length / loans.length) },
    { metric: 'Paid >20%',value: Math.round(100 * loans.filter(l => l.pct_paid_off > 20).length / loans.length) },
    { metric: 'Active',   value: Math.round(100 * loans.filter(l => l.months_remaining > 6).length / loans.length) },
    { metric: '<7% Rate', value: Math.round(100 * loans.filter(l => l.interest_rate_pct < 7).length / loans.length) },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-4xl font-black tracking-tighter text-[#1a1a1a] uppercase leading-none">
          Loan<br />Health.
        </h1>
        <p className="text-sm font-semibold text-[#1a1a1a] opacity-40 mt-2 uppercase tracking-widest">
          {loans.length} active loans · book value ${(loans.reduce((a,l)=>a+l.outstanding_balance,0)/1000000).toFixed(2)}M
        </p>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        {/* Portfolio health radar */}
        <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a] mb-4">Portfolio Health</h2>
          <ResponsiveContainer width="100%" height={200}>
            <RadarChart data={radarData}>
              <PolarGrid stroke="#e5e5e5" />
              <PolarAngleAxis dataKey="metric" tick={{ fontSize: 10, fontWeight: 700, fill: '#1a1a1a' }} />
              <Radar dataKey="value" stroke="#ff3b00" fill="#ff3b00" fillOpacity={0.15} strokeWidth={2} />
              <Tooltip formatter={(v) => v + '%'} />
            </RadarChart>
          </ResponsiveContainer>
        </div>

        {/* Risk breakdown */}
        <div className="xl:col-span-2 bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a] mb-4">Loan Risk Breakdown</h2>
          <div className="grid grid-cols-3 gap-3">
            {['Low','Medium','High'].map(risk => {
              const count = loans.filter(l => l.risk_rating === risk).length
              return (
                <div key={risk} className={`border-2 p-4 ${RISK[risk]}`}>
                  <p className="text-[9px] font-black uppercase tracking-[0.15em]">{risk} Risk</p>
                  <p className="text-3xl font-black mt-1">{count}</p>
                  <p className="text-xs font-bold opacity-60">{Math.round(100*count/loans.length)}% of portfolio</p>
                </div>
              )
            })}
          </div>
        </div>
      </div>

      {/* Loan table */}
      <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] overflow-hidden">
        <div className="px-5 py-4 border-b-2 border-[#1a1a1a]">
          <h2 className="text-sm font-black uppercase tracking-widest text-[#1a1a1a]">All Loans</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b-2 border-[#1a1a1a]">
                {['Risk','Type','Customer','Principal','Outstanding','Rate','% Paid','Late Pmts','Months Left'].map(h => (
                  <th key={h} className="text-left px-4 py-3 text-[10px] font-black uppercase tracking-widest text-[#1a1a1a] opacity-40 whitespace-nowrap">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loans.map((l, i) => (
                <tr key={l.loan_id} className={`border-b border-[#1a1a1a] border-opacity-10 hover:bg-[#f5f0e8] transition-colors ${i % 2 === 0 ? '' : 'bg-[#fafaf8]'}`}>
                  <td className="px-4 py-3">
                    <span className={`inline-flex items-center px-2 py-0.5 text-[10px] font-black uppercase tracking-wide border-2 ${RISK[l.risk_rating]}`}>
                      {l.risk_rating}
                    </span>
                  </td>
                  <td className="px-4 py-3 font-bold text-[#1a1a1a]">{l.loan_type}</td>
                  <td className="px-4 py-3 font-semibold text-[#1a1a1a]">{l.customer_name}</td>
                  <td className="px-4 py-3 font-bold">${Number(l.principal_amount).toLocaleString()}</td>
                  <td className="px-4 py-3 font-bold text-[#ff3b00]">${Number(l.outstanding_balance).toLocaleString()}</td>
                  <td className="px-4 py-3 font-bold">{l.interest_rate_pct}%</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <div className="w-16 h-1.5 bg-gray-200 border border-[#1a1a1a]">
                        <div className="h-full bg-[#ff3b00]" style={{ width: `${Math.min(l.pct_paid_off, 100)}%` }} />
                      </div>
                      <span className="font-black text-xs text-[#1a1a1a]">{l.pct_paid_off}%</span>
                    </div>
                  </td>
                  <td className={`px-4 py-3 font-black ${l.late_payments > 0 ? 'text-red-600' : 'text-green-600'}`}>
                    {l.late_payments}
                  </td>
                  <td className="px-4 py-3 font-bold text-[#1a1a1a]">{l.months_remaining}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
