/* ALS in-game vehicle editor */
(() => {
  const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ALS';
  const IN_GAME = typeof GetParentResourceName === 'function';
  const COLORS = ['red', 'blue', 'green', 'amber', 'white'];
  const STAGES = ['Primary', 'Secondary', 'Warning'];
  const STAGE_LABEL = { Primary: 'Primary (S-3)', Secondary: 'Secondary (S-2)', Warning: 'Warning (S-1)' };

  const $ = (id) => document.getElementById(id);

  const state = {
    data: null,       // working copy
    saved: null,      // last saved copy (for revert)
    vehicle: null,    // info about the car you're sitting in
    vehIdx: 0,
    patIdx: 0,
    lightIdx: null,
    previewStep: null, // { stage, index } step being held on the car
    dirty: false,
  };

  /* ---------- helpers ---------- */
  function post(name, body = {}) {
    if (!IN_GAME) return Promise.resolve(mockPost(name, body));
    return fetch(`https://${RES}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body),
    }).then((r) => r.json()).catch(() => ({}));
  }

  function el(tag, attrs = {}, ...kids) {
    const n = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
      if (v === undefined || v === null || v === false) continue;
      if (k === 'class') n.className = v;
      else if (k.startsWith('on')) n.addEventListener(k.slice(2), v);
      else if (k === 'value') n.value = v;
      else n.setAttribute(k, v === true ? '' : v);
    }
    for (const kid of kids.flat()) {
      if (kid === null || kid === undefined || kid === false) continue;
      n.append(kid instanceof Node ? kid : document.createTextNode(String(kid)));
    }
    return n;
  }

  const arr = (x) => (Array.isArray(x) ? x : []);
  const clone = (x) => JSON.parse(JSON.stringify(x));

  // Lua sends empty tables as {} sometimes - normalise everything to arrays
  function normalise(d) {
    const out = { vehicles: [], patterns: [] };
    for (const v of arr(d && d.vehicles)) {
      out.vehicles.push({
        model: String(v.model || ''),
        pattern: Number(v.pattern) || 1,
        lights: arr(v.lights).map((l) => ({
          bone: String(l.bone || ''),
          offset: [0, 1, 2].map((i) => Number(arr(l.offset)[i]) || 0),
          color: COLORS.includes(l.color) ? l.color : 'white',
          extras: arr(l.extras).map(Number),
        })),
      });
    }
    for (const p of arr(d && d.patterns)) {
      const np = { id: Number(p.id), flashDelay: Number(p.flashDelay) || 250 };
      for (const s of STAGES) np[s] = arr(p[s]).map((step) => arr(step).map(Number));
      out.patterns.push(np);
    }
    return out;
  }

  let toastTimer;
  function toast(msg, ok = true) {
    const t = $('toast');
    t.textContent = msg;
    t.className = 'toast show ' + (ok ? 'ok' : 'bad');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => (t.className = 'toast'), 3200);
  }

  let previewTimer;
  function changed() {
    state.dirty = true;
    $('dirty').classList.remove('hidden');
    clearTimeout(previewTimer);
    previewTimer = setTimeout(() => {
      post('preview', { data: state.data }).then((r) => {
        if (r && r.ok === false && r.error) toast(r.error, false);
      });
    }, 120);
  }

  function setClean() {
    state.dirty = false;
    $('dirty').classList.add('hidden');
  }

  const curVehicle = () => state.data.vehicles[state.vehIdx];
  const curPattern = () => state.data.patterns[state.patIdx];
  const isThisCar = (v) => state.vehicle && v && v.model.toLowerCase() === state.vehicle.model.toLowerCase();

  function extraRange(used = []) {
    let max = 12;
    for (const e of arr(state.vehicle && state.vehicle.extras)) max = Math.max(max, e);
    for (const e of used) max = Math.max(max, e);
    return Array.from({ length: Math.min(max, 20) }, (_, i) => i + 1);
  }

  function chips(list, onToggle, usedForRange) {
    const existing = new Set(arr(state.vehicle && state.vehicle.extras));
    return el('div', { class: 'chips' },
      extraRange(usedForRange || list).map((n) =>
        el('button', {
          class: 'chip' + (list.includes(n) ? ' on' : '') + (existing.has(n) ? ' exists' : ''),
          title: existing.has(n) ? `Extra ${n} (on this car)` : `Extra ${n}`,
          onclick: (e) => { e.stopPropagation(); onToggle(n); },
        }, n)));
  }

  function toggleIn(list, n) {
    const i = list.indexOf(n);
    if (i >= 0) list.splice(i, 1); else list.push(n);
    list.sort((a, b) => a - b);
  }

  function selectLight(idx) {
    state.lightIdx = idx;
    const v = curVehicle();
    post('selectLight', v && idx !== null ? { model: v.model, index: idx + 1 } : {});
  }

  /* ---------- step preview (hold a pattern step on the car) ---------- */
  let warnedNoCar = false;
  function sendStepPreview() {
    const p = curPattern();
    const ps = state.previewStep;
    const step = p && ps && p[ps.stage] && p[ps.stage][ps.index];
    if (!step) { state.previewStep = null; post('previewStep', {}); return; }
    if (!state.vehicle && !warnedNoCar) {
      warnedNoCar = true;
      toast('Get in a vehicle to see steps on the car.', false);
    }
    post('previewStep', { extras: step });
  }

  function previewStep(stage, index) {
    state.previewStep = { stage, index };
    sendStepPreview();
  }

  function stopStepPreview() {
    if (!state.previewStep) return;
    state.previewStep = null;
    post('previewStep', {});
  }

  /* ---------- header / car info ---------- */
  function renderCarInfo() {
    const info = $('carInfo');
    const v = state.vehicle;
    if (!v) { info.textContent = 'Not in a vehicle'; return; }
    info.innerHTML = '';
    info.append('In: ', el('b', {}, v.model),
      v.extras.length ? ` · extras ${v.extras.join(', ')}` : ' · no extras',
      v.emergency ? '' : ' · not emergency class');
    document.querySelectorAll('.stages button').forEach((b) => {
      b.classList.toggle('on', !!(v.stages && v.stages[b.dataset.stage]));
    });
  }

  /* ---------- vehicles tab ---------- */
  function renderVehicleSelect() {
    const sel = $('vehSelect');
    sel.innerHTML = '';
    if (!state.data.vehicles.length) sel.append(el('option', {}, 'No vehicles yet'));
    state.data.vehicles.forEach((v, i) => {
      sel.append(el('option', { value: i }, v.model + (isThisCar(v) ? '  (this car)' : '')));
    });
    sel.value = state.vehIdx;
    $('addCurrentVeh').disabled = !state.vehicle ||
      state.data.vehicles.some((v) => isThisCar(v));
  }

  function renderVehicleEditor() {
    const root = $('vehEditor');
    root.innerHTML = '';
    const v = curVehicle();
    if (!v) {
      root.append(el('p', { class: 'hint' },
        'No vehicles set up. Get in a car and press "+ This car", or add one by model name.'));
      return;
    }

    // Model + pattern
    root.append(
      el('div', { class: 'field' },
        el('label', {}, 'Model (spawn name)'),
        el('div', { class: 'row' },
          el('input', {
            type: 'text', value: v.model, spellcheck: 'false',
            onchange: (e) => {
              const val = e.target.value.trim();
              if (!/^[\w-]+$/.test(val)) { toast('Model names can only use letters, numbers, - and _', false); e.target.value = v.model; return; }
              if (state.data.vehicles.some((o) => o !== v && o.model.toLowerCase() === val.toLowerCase())) {
                toast(`"${val}" is already in the list`, false); e.target.value = v.model; return;
              }
              v.model = val; changed(); renderVehicleSelect(); selectLight(state.lightIdx);
            },
          }),
          el('button', {
            class: 'danger shrink',
            onclick: () => {
              state.data.vehicles.splice(state.vehIdx, 1);
              state.vehIdx = Math.max(0, state.vehIdx - 1);
              state.lightIdx = null;
              changed(); renderVehicles();
            },
          }, 'Delete'))),
      el('div', { class: 'field' },
        el('label', {}, 'Flash pattern'),
        el('div', { class: 'row' },
          (() => {
            const s = el('select', {
              onchange: (e) => { v.pattern = Number(e.target.value); changed(); },
            }, state.data.patterns.map((p) => el('option', { value: p.id }, `Pattern ${p.id}  ·  ${p.flashDelay} ms`)));
            s.value = v.pattern;
            return s;
          })(),
          el('button', {
            class: 'ghost shrink',
            onclick: () => {
              state.patIdx = Math.max(0, state.data.patterns.findIndex((p) => p.id === v.pattern));
              switchTab('patterns');
            },
          }, 'Edit pattern'))),
    );
    if (!isThisCar(v)) {
      root.append(el('p', { class: 'warn' },
        state.vehicle ? `You're in "${state.vehicle.model}", so light markers won't show for this vehicle.`
                      : 'Get in this vehicle to see light markers while you edit.'));
    }

    // Lights
    root.append(el('div', { class: 'section-head' },
      el('h3', {}, `Environment lights (${v.lights.length})`),
      el('button', {
        class: 'small',
        onclick: () => {
          const bones = arr(state.vehicle && state.vehicle.bones);
          v.lights.push({ bone: bones.includes('extra_1') ? 'extra_1' : (bones[0] || 'bodyshell'), offset: [0, 0, 0], color: 'red', extras: [] });
          selectLight(v.lights.length - 1);
          changed(); renderVehicleEditor();
        },
      }, '+ Add light')));

    if (!v.lights.length) {
      root.append(el('p', { class: 'empty' }, 'No environment lights. These cast coloured light on the ground and walls when the matching extras flash.'));
    }

    const datalist = el('datalist', { id: 'boneList' },
      arr(state.vehicle && state.vehicle.bones).map((b) => el('option', { value: b })));
    root.append(datalist);

    v.lights.forEach((l, i) => {
      const card = el('div', {
        class: 'card' + (state.lightIdx === i ? ' selected' : ''),
        onclick: () => { selectLight(i); renderVehicleEditor(); },
      });

      card.append(el('div', { class: 'card-head' },
        el('span', { class: 'dot', style: `color: var(--${l.color}); background: var(--${l.color})` }),
        el('span', { class: 'name' }, `Light ${i + 1}`),
        el('button', {
          class: 'ghost small', title: 'Duplicate',
          onclick: (e) => { e.stopPropagation(); v.lights.splice(i + 1, 0, clone(l)); selectLight(i + 1); changed(); renderVehicleEditor(); },
        }, 'Copy'),
        el('button', {
          class: 'ghost small danger', title: 'Remove',
          onclick: (e) => {
            e.stopPropagation(); v.lights.splice(i, 1);
            selectLight(state.lightIdx === i ? null : (state.lightIdx > i ? state.lightIdx - 1 : state.lightIdx));
            changed(); renderVehicleEditor();
          },
        }, 'Remove')));

      const bones = arr(state.vehicle && state.vehicle.bones);
      const boneInput = el('input', {
        type: 'text', value: l.bone, list: 'boneList', spellcheck: 'false',
        onclick: (e) => e.stopPropagation(),
        onchange: (e) => { l.bone = e.target.value.trim(); changed(); renderVehicleEditor(); },
      });
      card.append(el('div', { class: 'field' }, el('label', {}, 'Bone'), boneInput,
        isThisCar(v) && l.bone && !bones.includes(l.bone)
          ? el('div', { class: 'warn' }, `"${l.bone}" isn't in the common bone list for this car. It may still exist - check the marker.`)
          : null));

      card.append(el('div', { class: 'field' },
        el('label', {}, 'Offset from bone (metres: right, forward, up)'),
        el('div', { class: 'row' }, [0, 1, 2].map((axis) =>
          el('input', {
            type: 'number', step: '0.05', value: l.offset[axis],
            onclick: (e) => e.stopPropagation(),
            oninput: (e) => { l.offset[axis] = Number(e.target.value) || 0; changed(); },
          })))));

      card.append(el('div', { class: 'field' },
        el('label', {}, 'Colour'),
        el('div', { class: 'colors' }, COLORS.map((c) =>
          el('button', {
            class: 'swatch' + (l.color === c ? ' on' : ''), title: c,
            style: `background: var(--${c})`,
            onclick: (e) => { e.stopPropagation(); l.color = c; changed(); renderVehicleEditor(); },
          })))));

      card.append(el('div', { class: 'field', style: 'margin-bottom:0' },
        el('label', {}, 'Glows when any of these extras are on'),
        chips(l.extras, (n) => { toggleIn(l.extras, n); selectLight(i); changed(); renderVehicleEditor(); })));

      root.append(card);
    });
  }

  function renderVehicles() {
    renderVehicleSelect();
    renderVehicleEditor();
  }

  /* ---------- patterns tab ---------- */
  function renderPatternSelect() {
    const sel = $('patSelect');
    sel.innerHTML = '';
    state.data.patterns.forEach((p, i) => sel.append(el('option', { value: i }, `Pattern ${p.id}`)));
    sel.value = state.patIdx;
  }

  function renderPatternEditor() {
    const root = $('patEditor');
    root.innerHTML = '';
    const p = curPattern();
    if (!p) return;

    const users = state.data.vehicles.filter((v) => v.pattern === p.id).map((v) => v.model);

    root.append(
      el('div', { class: 'field' },
        el('label', {}, 'Flash delay (ms per step)'),
        el('div', { class: 'row' },
          el('input', {
            type: 'number', min: '30', max: '5000', step: '10', value: p.flashDelay,
            oninput: (e) => { p.flashDelay = Math.max(30, Math.min(5000, Number(e.target.value) || 250)); changed(); },
          }),
          el('button', {
            class: 'danger shrink',
            disabled: users.length > 0 || state.data.patterns.length <= 1,
            title: users.length ? 'Still used by a vehicle' : (state.data.patterns.length <= 1 ? 'You need at least one pattern' : ''),
            onclick: () => {
              stopStepPreview();
              state.data.patterns.splice(state.patIdx, 1);
              state.patIdx = Math.max(0, state.patIdx - 1);
              changed(); renderPatterns(); renderVehicles();
            },
          }, 'Delete'))),
      el('p', { class: 'hint' },
        users.length ? `Used by: ${users.join(', ')}. Changes affect all of them.` : 'Not used by any vehicle yet.'),
    );

    const allUsed = STAGES.flatMap((s) => p[s].flat());
    const ps = state.previewStep;

    root.append(el('div', { class: 'preview-bar' + (ps ? ' on' : '') },
      ps
        ? el('span', {}, el('b', {}, 'Showing on car: '), `${ps.stage} step ${ps.index + 1}`)
        : el('span', {}, 'Click a step or an extra to show that step on your car.'),
      ps ? el('button', { class: 'small', onclick: () => { stopStepPreview(); renderPatternEditor(); } }, '\u25B6 Play pattern') : null));

    for (const s of STAGES) {
      const steps = p[s];
      root.append(el('div', { class: 'section-head' },
        el('h3', {}, `${STAGE_LABEL[s]} · ${steps.length} step${steps.length === 1 ? '' : 's'}`),
        el('button', {
          class: 'small',
          onclick: () => { steps.push([]); previewStep(s, steps.length - 1); changed(); renderPatternEditor(); },
        }, '+ Step')));

      const card = el('div', { class: 'card', style: 'cursor:default' });
      if (!steps.length) card.append(el('p', { class: 'empty' }, 'No steps - this stage does nothing.'));
      steps.forEach((step, i) => {
        const showing = ps && ps.stage === s && ps.index === i;
        card.append(el('div', {
          class: 'step' + (showing ? ' showing' : ''),
          title: 'Click to show this step on your car',
          onclick: () => { previewStep(s, i); renderPatternEditor(); },
        },
          el('span', { class: 'num' }, i + 1),
          chips(step, (n) => { toggleIn(step, n); previewStep(s, i); changed(); renderPatternEditor(); }, allUsed),
          el('div', { class: 'row shrink', style: 'gap:3px' },
            el('button', { class: 'ghost small', title: 'Move up', disabled: i === 0,
              onclick: (e) => {
                e.stopPropagation();
                steps.splice(i - 1, 0, steps.splice(i, 1)[0]);
                if (ps && ps.stage === s) {
                  if (ps.index === i) ps.index = i - 1; else if (ps.index === i - 1) ps.index = i;
                }
                changed(); renderPatternEditor();
              } }, '↑'),
            el('button', { class: 'ghost small danger', title: 'Remove step',
              onclick: (e) => {
                e.stopPropagation();
                steps.splice(i, 1);
                if (ps && ps.stage === s) {
                  if (ps.index === i) stopStepPreview(); else if (ps.index > i) { ps.index -= 1; sendStepPreview(); }
                }
                changed(); renderPatternEditor();
              } }, '✕'))));
      });
      root.append(card);
    }
    root.append(el('p', { class: 'hint', style: 'margin-top:8px' },
      'Each step turns on the highlighted extras for one flash delay, then moves to the next step. Brighter numbers are extras that exist on the car you are in.'));
  }

  function renderPatterns() {
    renderPatternSelect();
    renderPatternEditor();
  }

  function renderAll() {
    renderCarInfo();
    renderVehicles();
    renderPatterns();
  }

  /* ---------- tabs ---------- */
  function switchTab(name) {
    document.querySelectorAll('.tabs button').forEach((b) => b.classList.toggle('active', b.dataset.tab === name));
    $('tab-vehicles').classList.toggle('hidden', name !== 'vehicles');
    $('tab-patterns').classList.toggle('hidden', name !== 'patterns');
    if (name !== 'patterns') stopStepPreview();
    if (name === 'patterns') renderPatterns(); else renderVehicles();
  }
  document.querySelectorAll('.tabs button').forEach((b) => b.addEventListener('click', () => switchTab(b.dataset.tab)));

  /* ---------- prompt ---------- */
  function promptModel(title, initial, onOk) {
    $('promptTitle').textContent = title;
    $('promptInput').value = initial || '';
    $('promptError').textContent = '';
    $('promptModal').classList.remove('hidden');
    $('promptInput').focus();
    const ok = () => {
      const val = $('promptInput').value.trim();
      if (!/^[\w-]+$/.test(val)) { $('promptError').textContent = 'Use letters, numbers, - and _ only.'; return; }
      if (state.data.vehicles.some((v) => v.model.toLowerCase() === val.toLowerCase())) {
        $('promptError').textContent = 'That vehicle is already in the list.'; return;
      }
      $('promptModal').classList.add('hidden');
      onOk(val);
    };
    $('promptOk').onclick = ok;
    $('promptInput').onkeydown = (e) => { if (e.key === 'Enter') ok(); };
    $('promptCancel').onclick = () => $('promptModal').classList.add('hidden');
  }

  /* ---------- toolbar actions ---------- */
  function addVehicle(model) {
    const v = { model, pattern: state.data.patterns[0] ? state.data.patterns[0].id : 1, lights: [] };
    state.data.vehicles.push(v);
    state.data.vehicles.sort((a, b) => a.model.toLowerCase().localeCompare(b.model.toLowerCase()));
    state.vehIdx = state.data.vehicles.indexOf(v);
    selectLight(null);
    changed(); renderVehicles();
  }

  $('vehSelect').addEventListener('change', (e) => {
    state.vehIdx = Number(e.target.value) || 0; selectLight(null); renderVehicleEditor();
  });
  $('addCurrentVeh').addEventListener('click', () => state.vehicle && addVehicle(state.vehicle.model));
  $('addVeh').addEventListener('click', () => promptModel('Vehicle model (spawn name)', '', addVehicle));

  $('patSelect').addEventListener('change', (e) => { stopStepPreview(); state.patIdx = Number(e.target.value) || 0; renderPatternEditor(); });
  function nextPatternId() { return state.data.patterns.reduce((m, p) => Math.max(m, p.id), 0) + 1; }
  $('addPat').addEventListener('click', () => {
    stopStepPreview();
    state.data.patterns.push({ id: nextPatternId(), flashDelay: 250, Primary: [[], []], Secondary: [], Warning: [] });
    state.patIdx = state.data.patterns.length - 1;
    changed(); renderPatterns();
  });
  $('dupPat').addEventListener('click', () => {
    const p = curPattern(); if (!p) return;
    stopStepPreview();
    const copy = clone(p); copy.id = nextPatternId();
    state.data.patterns.push(copy);
    state.patIdx = state.data.patterns.length - 1;
    changed(); renderPatterns();
  });

  document.querySelectorAll('.stages button').forEach((b) => b.addEventListener('click', () => {
    if (!state.vehicle) { toast('Get in a vehicle to test lights.', false); return; }
    state.previewStep = null; // Lua side stops the step preview too
    if (!$('tab-patterns').classList.contains('hidden')) renderPatternEditor();
    post('toggleStage', { stage: b.dataset.stage }).then((info) => {
      if (info && !info.none) { state.vehicle = info; renderCarInfo(); }
    });
  }));

  $('saveBtn').addEventListener('click', () => {
    post('save', { data: state.data }).then((r) => {
      if (r && r.ok === false) toast(r.error || 'Could not save', false);
      else toast('Saving…');
    });
  });

  $('revertBtn').addEventListener('click', () => {
    stopStepPreview();
    state.data = clone(state.saved);
    state.vehIdx = Math.min(state.vehIdx, Math.max(0, state.data.vehicles.length - 1));
    state.patIdx = Math.min(state.patIdx, Math.max(0, state.data.patterns.length - 1));
    selectLight(null);
    post('preview', { data: state.data });
    setClean(); renderAll();
    toast('Reverted to the last saved setup.');
  });

  $('exportBtn').addEventListener('click', () => {
    post('exportLua', { data: state.data }).then((r) => {
      if (!r || r.ok === false) { toast((r && r.error) || 'Export failed', false); return; }
      $('exportText').value = r.text;
      $('exportModal').classList.remove('hidden');
    });
  });
  $('exportClose').addEventListener('click', () => $('exportModal').classList.add('hidden'));
  $('exportCopy').addEventListener('click', () => {
    const t = $('exportText');
    t.focus(); t.select();
    try { document.execCommand('copy'); toast('Copied to clipboard.'); } catch (e) { toast('Select the text and press Ctrl+C.', false); }
  });

  $('closeBtn').addEventListener('click', () => post('close'));
  $('releaseBtn').addEventListener('click', () => post('releaseFocus'));

  document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    if (!$('exportModal').classList.contains('hidden')) { $('exportModal').classList.add('hidden'); return; }
    if (!$('promptModal').classList.contains('hidden')) { $('promptModal').classList.add('hidden'); return; }
    post('close');
  });

  /* ---------- messages from Lua ---------- */
  window.addEventListener('message', (e) => {
    const m = e.data || {};
    switch (m.action) {
      case 'open': {
        state.data = normalise(m.data);
        state.saved = clone(state.data);
        state.vehicle = m.vehicle && !m.vehicle.none ? m.vehicle : null;
        if (state.vehicle) {
          state.vehicle.extras = arr(state.vehicle.extras);
          state.vehicle.bones = arr(state.vehicle.bones);
          const i = state.data.vehicles.findIndex((v) => isThisCar(v));
          if (i >= 0) state.vehIdx = i;
        }
        state.vehIdx = Math.min(state.vehIdx, Math.max(0, state.data.vehicles.length - 1));
        state.patIdx = Math.min(state.patIdx, Math.max(0, state.data.patterns.length - 1));
        state.lightIdx = null;
        state.previewStep = null;
        warnedNoCar = false;
        setClean();
        $('app').classList.remove('hidden');
        renderAll();
        break;
      }
      case 'close':
        state.previewStep = null;
        $('app').classList.add('hidden');
        $('released').classList.add('hidden');
        $('exportModal').classList.add('hidden');
        $('promptModal').classList.add('hidden');
        break;
      case 'focus':
        $('app').classList.toggle('unfocused', !m.focused);
        $('released').classList.toggle('hidden', !!m.focused || $('app').classList.contains('hidden'));
        if (m.focused) {
          post('vehicleInfo').then((info) => {
            state.vehicle = info && !info.none ? info : null;
            if (state.vehicle) { state.vehicle.extras = arr(state.vehicle.extras); state.vehicle.bones = arr(state.vehicle.bones); }
            renderAll();
          });
        }
        break;
      case 'saveResult':
        toast(m.message, !!m.ok);
        if (m.ok) { state.saved = clone(state.data); setClean(); }
        break;
      case 'remoteSaved':
        if (!state.dirty) {
          state.data = normalise(m.data);
          state.saved = clone(state.data);
          renderAll();
        } else {
          state.saved = normalise(m.data);
          toast('Someone else saved changes. Revert to load theirs, or Save to keep yours.', false);
        }
        break;
    }
  });

  /* ---------- browser preview (outside the game) ---------- */
  function mockPost(name, body) {
    (window.__alsPosts = window.__alsPosts || []).push([name, JSON.stringify(body || {})]);
    if (name === 'vehicleInfo' || name === 'toggleStage') return state.vehicle || { none: true };
    if (name === 'exportLua') return { ok: true, text: '-- export preview\n' };
    if (name === 'save') { setTimeout(() => window.postMessage({ action: 'saveResult', ok: true, message: 'Saved (preview)' }, '*'), 200); }
    return { ok: true };
  }
  if (!IN_GAME) {
    document.body.style.background = '#3a4048';
    window.postMessage({
      action: 'open',
      vehicle: { model: 'lspd1', emergency: true, extras: [1, 2, 3, 4, 7, 8, 9], bones: ['bodyshell', 'chassis', 'extra_1', 'extra_2', 'siren1', 'siren2'], stages: { Primary: true } },
      data: {
        vehicles: [
          { model: 'FBI2', pattern: 1, lights: [{ bone: 'extra_1', offset: [0, 0, 0], color: 'red', extras: [1, 2] }] },
          { model: 'lspd1', pattern: 1, lights: [
            { bone: 'extra_1', offset: [0, 0, 0], color: 'red', extras: [1, 3] },
            { bone: 'extra_1', offset: [0, 0, 0], color: 'blue', extras: [2, 4] },
          ] },
        ],
        patterns: [{ id: 1, flashDelay: 250, Primary: [[1, 2], [3, 4]], Secondary: [[1], [4]], Warning: [[7, 9], [8]] }],
      },
    }, '*');
  }
})();
