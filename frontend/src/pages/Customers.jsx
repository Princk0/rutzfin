import { useEffect, useState } from 'react'
import { api } from '../api.js'

const MOCK = [
  { customer_id:18, customer_name:'Andre Beaumont',   email:'andre.beaumont@email.com',   credit_score:870, account_count:2, total_balance:107000, join_date:'2014-10-01' },
  { customer_id:30, customer_name:'Marcus Osei',      email:'marcus.osei@email.com',      credit_score:860, account_count:2, total_balance:111500, join_date:'2014-12-11' },
  { customer_id:24, customer_name:'Patrick Fitzgerald',email:'patrick.fitzgerald@email.com',credit_score:845,account_count:3,total_balance:225900, join_date:'2013-08-20' },
  { customer_id:6,  customer_name:'Michael Chen',     email:'michael.chen@email.com',     credit_score:855, account_count:3, total_balance:178280, join_date:'2015-11-05' },
  { customer_id:2,  customer_name:'James MacPherson', email:'james.macpherson@email.com', credit_score:820, account_count:2, total_balance:51340,  join_date:'2017-03-10' },
  { customer_id:14, customer_name:'Tyler Brooks',     email:'tyler.brooks@email.com',     credit_score:830, account_count:2, total_balance:58450,  join_date:'2015-04-15' },
  { customer_id:21, customer_name:'Isabel Santos',    email:'isabel.santos@email.com',    credit_score:815, account_count:1, total_balance:24600,  join_date:'2016-07-14' },
  { customer_id:1,  customer_name:'Amara Okonkwo',    email:'amara.okonkwo@email.com',    credit_score:780, account_count:2, total_balance:23320,  join_date:'2018-01-15' },
  { customer_id:10, customer_name:'Raj Patel',        email:'raj.patel@email.com',        credit_score:810, account_count:2, total_balance:46700,  join_date:'2016-05-18' },
  { customer_id:27, customer_name:'Claire Dubois',    email:'claire.dubois@email.com',    credit_score:785, account_count:2, total_balance:32440,  join_date:'2019-01-22' },
]

const SEGMENT = (score) => {
  if (score >= 800) return { label: 'Platinum', cls: 'border-[#ff3b00] text-[#ff3b00]' }
  if (score >= 740) return { label: 'Gold',     cls: 'border-[#888] text-[#888]' }
  if (score >= 680) return { label: 'Silver',   cls: 'border-[#aaa] text-[#aaa]' }
  return              { label: 'Standard', cls: 'border-gray-300 text-gray-400' }
}

const SCORE_COLOR = (score) => {
  if (score >= 750) return 'text-green-600'
  if (score >= 650) return 'text-orange-500'
  return 'text-red-500'
}

export default function Customers() {
  const [customers, setCustomers] = useState(MOCK)

  useEffect(() => {
    api.customers().then(d => { if (d?.length) setCustomers(d) }).catch(() => {})
  }, [])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-4xl font-black tracking-tighter text-[#1a1a1a] uppercase leading-none">
          Customers.
        </h1>
        <p className="text-sm font-semibold text-[#1a1a1a] opacity-40 mt-2 uppercase tracking-widest">
          Information
        </p>
      </div>

      <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b-2 border-[#1a1a1a] bg-[#f5f0e8]">
                {['Segment','Customer','Email','Credit Score','Accounts','Total Balance','Member Since'].map(h => (
                  <th key={h} className="text-left px-4 py-3 text-[10px] font-black uppercase tracking-widest text-[#1a1a1a] opacity-40 whitespace-nowrap">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {customers.map((c, i) => {
                const seg = SEGMENT(c.credit_score)
                return (
                  <tr key={c.customer_id} className={`border-b border-[#1a1a1a] border-opacity-10 hover:bg-[#f5f0e8] transition-colors ${i % 2 === 0 ? '' : 'bg-[#fafaf8]'}`}>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2 py-0.5 text-[10px] font-black uppercase tracking-wide border-2 ${seg.cls}`}>
                        {seg.label}
                      </span>
                    </td>
                    <td className="px-4 py-3 font-black text-[#1a1a1a]">{c.customer_name}</td>
                    <td className="px-4 py-3 font-semibold text-[#1a1a1a] opacity-50 text-xs">{c.email}</td>
                    <td className={`px-4 py-3 font-black text-lg ${SCORE_COLOR(c.credit_score)}`}>{c.credit_score}</td>
                    <td className="px-4 py-3 font-bold text-[#1a1a1a]">{c.account_count}</td>
                    <td className="px-4 py-3 font-black text-[#ff3b00]">${Number(c.total_balance).toLocaleString()}</td>
                    <td className="px-4 py-3 font-semibold text-[#1a1a1a] opacity-40 text-xs">
                      {new Date(c.join_date).getFullYear()}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
