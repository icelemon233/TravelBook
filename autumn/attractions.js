import {attractionGroups,attractionDays} from './attractions-data.js';
const esc=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const external=(url,label)=>`<a href="${esc(url)}" target="_blank" rel="noopener noreferrer">${label} ↗</a>`;
export function mountAttractions(onDay){
  const list=document.getElementById('attraction-list'),filters=document.getElementById('attraction-filters');
  let plan=[],region='全部',photos={};
  function render(){
    const groups=attractionGroups.filter(group=>region==='全部'||group.region.includes(region));
    document.getElementById('attraction-count').textContent=`显示 ${groups.reduce((n,g)=>n+g.spots.length,0)} / 12 处景点`;
    list.innerHTML=groups.map(group=>{
      const photo=photos[group.photo];
      return `<article class="attraction-card ${group.photo?'':'attraction-text-card'}" aria-labelledby="spot-group-${group.id}">${photo?`<figure><img src="${esc(photo.local)}" alt="${esc(group.caption)}" width="${photo.width}" height="${photo.height}" loading="lazy" decoding="async"><figcaption>${esc(group.caption)}</figcaption></figure>`:''}<div class="attraction-content"><p class="attraction-region">${esc(group.region)}</p><h3 id="spot-group-${group.id}">${esc(group.title)}</h3><ul class="attraction-spots">${group.spots.map(spot=>{
        const days=attractionDays(spot,plan),label=days.length?days.map(day=>`<button data-spot-day="${day.id}" aria-label="查看Day ${day.number}行程">Day ${day.number}</button>`).join(''):spot.dayIds.length?'本版本未安排':'未排入默认日程';
        const search=`https://uri.amap.com/search?keyword=${encodeURIComponent(group.region.replaceAll(' · ','')+spot.name.split(' · ')[0])}&view=map`;
        return `<li><div class="attraction-spot-head"><h4>${esc(spot.name)}</h4><span class="attraction-type">${esc(spot.type)}</span></div><div class="attraction-days">${label}</div><p>${esc(spot.text)}</p><div class="attraction-links">${external(search,'地图搜地点')}${external(spot.source,'景点资料')}</div></li>`;
      }).join('')}</ul>${photo?`<p class="photo-credit">图片：${external(photo.source,esc(photo.author))} · ${external(photo.licenseUrl,esc(photo.license))}<br>历史实景图，缩放与版面裁切；非本次出行实拍。</p>`:''}</div></article>`;
    }).join('');
    list.querySelectorAll('img').forEach(img=>img.addEventListener('error',()=>{const figure=img.closest('figure');figure.classList.add('photo-unavailable');figure.querySelector('figcaption').textContent='图片暂未加载，可在图片来源页查看';img.hidden=true;},{once:true}));
  }
  filters.addEventListener('click',event=>{const button=event.target.closest('[data-region]');if(!button)return;region=button.dataset.region;filters.querySelectorAll('button').forEach(el=>el.setAttribute('aria-pressed',String(el===button)));render();});
  list.addEventListener('click',event=>{const button=event.target.closest('[data-spot-day]');if(button)onDay(button.dataset.spotDay);});
  fetch(new URL('./photo-sources.json',import.meta.url)).then(response=>{if(!response.ok)throw new Error('photos');return response.json();}).then(data=>{photos=data;render();}).catch(()=>{document.getElementById('attraction-image-status').textContent='配图资料暂未加载，景点目录仍可使用。';});
  return {update(nextPlan){plan=nextPlan;render();}};
}
