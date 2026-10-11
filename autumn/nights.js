import {nightModeLabels} from './nights-data.js';
const escape=value=>String(value).replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const mapLink=place=>`https://uri.amap.com/search?keyword=${encodeURIComponent(place.region.replaceAll(' · ','')+place.name)}&view=map`;
const links=place=>`<a href="${mapLink(place)}" target="_blank" rel="noopener noreferrer">高德查地点 ↗</a>${place.source?`<a href="${place.source}" target="_blank" rel="noopener noreferrer">${escape(place.sourceLabel)} ↗</a>`:''}`;

export function renderNights(plan){
  const counts=mode=>plan.filter(day=>day.overnight.mode===mode).length;
  document.getElementById('night-counts').innerHTML=[['car','车宿',counts('car')],['hotel','酒店',counts('hotel')],['home','回家',counts('home')]].map(([mode,label,count])=>`<span class="night-count night-${mode}"><b>${count}</b>${label}${mode==='home'?'天':'晚'}</span>`).join('');
  document.getElementById('hotel-nights').textContent=`${plan.length}天版 · 酒店晚：${plan.flatMap((day,i)=>day.overnight.mode==='hotel'?[`Day${i+1}`]:[]).join('、')}。其余在外夜晚按下表车宿安排。`;
  document.getElementById('night-rows').innerHTML=plan.map((day,index)=>{
    const {mode,place,fallback,reason,status}=day.overnight;
    return `<tr data-night-id="${day.id}"><th scope="row"><a href="#day-${day.id}" data-night-day="${day.id}">Day${String(index+1).padStart(2,'0')}</a></th><td class="night-mode-cell"><span class="night-mode night-${mode}">${nightModeLabels[mode]}</span></td><td class="night-place"><strong>${escape(place.name)}</strong><span>${escape(place.region)}</span><span>${escape(place.address)}</span>${mode==='home'?'':`<div class="night-links">${links(place)}</div>`}</td><td class="night-arrangement"><p>${escape(reason)}</p><small class="night-status">${escape(status)}</small>${mode==='home'?'':`<details class="night-confirm"><summary>${mode==='car'?'确认条件与备用酒店':'停车与入住说明'}</summary><p>${escape(place.note)}</p>${fallback?`<div class="night-fallback"><b>未获准车宿 → 住酒店</b><strong>${escape(fallback.name)}</strong><span>${escape(fallback.region)}</span><span>${escape(fallback.address)}</span><p>${escape(fallback.note)}</p><div class="night-links">${links(fallback)}</div></div>`:''}</details>`}</td></tr>`;
  }).join('');
}
