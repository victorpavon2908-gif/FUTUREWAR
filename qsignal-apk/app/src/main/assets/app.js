(() => {
  const market=[
    {asset:'EUR/USD',payout:88,dir:'CALL',score:86},
    {asset:'GBP/USD',payout:84,dir:'PUT',score:82},
    {asset:'USD/JPY',payout:91,dir:'CALL',score:79},
    {asset:'AUD/USD',payout:80,dir:'PUT',score:76}
  ];
  const state={expiry:1,apiBase:localStorage.getItem('qsignal_api')||'',timer:null};
  const $=s=>document.querySelector(s), $$=s=>[...document.querySelectorAll(s)];
  function renderMarket(rows=market){$('#marketList').innerHTML=rows.map(x=>`<article class="market-row"><div class="asset"><b>${x.asset}</b><small>Payout ${x.payout}%</small></div><span class="dir ${x.dir.toLowerCase()}">${x.dir==='CALL'?'↑':'↓'} ${x.dir}</span><div class="score"><b>${x.score}%</b><small>conf.</small></div></article>`).join('')}
  function applySignal(s){
    if(!s||s.status==='NO_SIGNAL'){
      $('#signalState').textContent='Sin entrada clara · esperando confirmación';
      $('#directionText').textContent='ESPERAR';$('#directionArrow').textContent='·';$('#directionBadge').className='signal-badge';return;
    }
    const dir=(s.direction||'CALL').toUpperCase();
    $('#assetName').textContent=(s.asset||'EURUSD').replace(/([A-Z]{3})([A-Z]{3})/,'$1/$2');
    $('#entryPrice').textContent=s.entry_reference??'—';
    $('#directionText').textContent=dir;$('#directionArrow').textContent=dir==='CALL'?'↑':'↓';
    $('#directionBadge').className='signal-badge '+(dir==='CALL'?'call':'put');
    $('#confidence').textContent=`${s.confidence??0}%`;$('#confidenceBar').style.width=`${Math.max(0,Math.min(100,s.confidence??0))}%`;
    $('#payout').textContent=s.payout!=null?`${Math.round(s.payout)}%`:'—';$('#expiryText').textContent=`${state.expiry} min`;
    $('#signalState').textContent=(s.confidence>=84)?'Señal fuerte · esperar apertura de vela':'Señal válida · confirmar entrada';
    const reasons=Array.isArray(s.reasons)?s.reasons.slice(0,4):[];
    $('#reasonGrid').innerHTML=reasons.map(r=>`<span>${String(r)}</span>`).join('')||'<span>Esperando datos</span>';
  }
  async function loadSignal(){
    $('#expiryText').textContent=`${state.expiry} min`;$('#updatedAt').textContent='Actualizando…';
    if(!state.apiBase){
      $('#connPill').textContent='Demo UI';$('#connPill').className='pill';
      applySignal({asset:'EURUSD',direction:state.expiry%2?'CALL':'PUT',confidence:Math.max(78,88-state.expiry),payout:88,entry_reference:'1.08642',reasons:['EMA alineadas','RSI 58.4','MACD confirma','Volatilidad sana']});
      $('#updatedAt').textContent='Vista de demostración';return;
    }
    try{
      const url=`${state.apiBase.replace(/\/$/,'')}/api/signals/latest?expiry=${state.expiry}`;
      const res=await fetch(url,{cache:'no-store'});if(!res.ok)throw new Error('HTTP '+res.status);
      const data=await res.json();applySignal(data.signal||data);$('#connPill').textContent='Conectado';$('#connPill').className='pill live';$('#updatedAt').textContent='Actualizado ahora';
    }catch(e){$('#connPill').textContent='Sin conexión';$('#connPill').className='pill';$('#updatedAt').textContent='No se pudo actualizar'}
  }
  $$('.expiry').forEach(btn=>btn.addEventListener('click',()=>{$$('.expiry').forEach(x=>x.classList.remove('active'));btn.classList.add('active');state.expiry=Number(btn.dataset.expiry);loadSignal()}));
  $('#refreshBtn').addEventListener('click',loadSignal);
  $('#apiUrl').value=state.apiBase;
  $('#saveApiBtn').addEventListener('click',()=>{const raw=$('#apiUrl').value.trim().replace(/\/$/,'');if(raw&&!raw.startsWith('https://')){alert('Usa una URL HTTPS para proteger la conexión.');return}state.apiBase=raw;localStorage.setItem('qsignal_api',raw);loadSignal()});
  const scrollTargets={top:'.hero',market:'.market-list',history:'.history-card',settings:'.settings-card'};
  $$('.nav-item').forEach(btn=>btn.addEventListener('click',()=>{$$('.nav-item').forEach(x=>x.classList.remove('active'));btn.classList.add('active');const el=$(scrollTargets[btn.dataset.scroll]);if(el)el.scrollIntoView({behavior:'smooth',block:'start'})}));
  renderMarket();loadSignal();state.timer=setInterval(loadSignal,15000);
})();
