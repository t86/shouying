/* ==========================================================================
   Shouyin Multi-Skin Preview Controller — 8 Skins (3 Core + 5 Extended)
   Shared by S1 (index.html) / S2 (order.html) / S3 (cashier.html) / compare.html
   ========================================================================== */
(function () {
  const STORAGE_KEY = 'shouyin_preview_skin';
  const MOTION_KEY = 'shouyin_reduced_motion';

  const SKINS = [
    {
      id: 'midnightBlue',
      group: 'core',
      isLight: false,
      name: '午夜深蓝',
      shortLabel: '🌙 午夜深蓝',
      modeTag: '深色 · 默认 · Phase 5 卡台 AA',
      cardStyleTag: '经典实色满铺 · 发光边 · 卡台全 7 态 AA',
      dot: '#202C4A',
      desc: '原 Shouyin 夜场深蓝实色满铺配白字与顶缘高光；已提前应用 Phase 5 卡台 AA 修正（加深开台/预订/点单/锁定卡底并提亮 12px 次字至 ≥4.5:1），老员工零切换成本且小字清晰可读。',
      thumb: {
        canvas: '#202C4A',
        header: '#222D47',
        footer: '#0D172D',
        brand: '#455EFF',
        text: '#FFFFFF',
        style: 'solid',
        cards: [
          { id: 'V01', fill: '#007379', accent: '#007379', bd: 'rgba(255,255,255,0.28)', fg: '#FFFFFF', chip: 'rgba(8,12,26,0.48)' },
          { id: 'A08', fill: '#9E5606', accent: '#9E5606', bd: 'rgba(255,255,255,0.28)', fg: '#FFFFFF', chip: 'rgba(8,12,26,0.48)' },
          { id: 'A12', fill: '#B02345', accent: '#B02345', bd: '#FFAD45', fg: '#FFFFFF', chip: '#FFBD00', partial: true },
        ],
      },
      swatches: ['#202C4A', '#455EFF', '#007379', '#9E5606', '#B02345', '#5C3BC1'],
      tokens: [
        ['主画布', '#202C4A'],
        ['顶栏', '#222D47'],
        ['底栏', '#0D172D'],
        ['主按钮', '#455EFF'],
        ['微光描边', '#32B9FF'],
        ['空台(1)', '#465675'],
        ['锁定(2·P5AA)', '#6C5B28'],
        ['预订(8·P5AA)', '#007379'],
        ['开台(4·P5AA)', '#9E5606'],
        ['点单(5·P5AA)', '#B02345'],
        ['部分结(6)', '#FFAD45'],
        ['已结(7)', '#5C3BC1'],
        ['金额绿', '#1EDAAD'],
      ],
      recipeSummary: {
        fillStyle: '实色满铺（Phase 5 提前 AA 修正：锁定/预订/开台/点单加深）',
        accentStyle: '整卡实色 + 顶缘高光',
        textStyle: '纯白 #FFFFFF + 次字 94% 透明白（全态 ≥ 5.11:1）',
        partialStyle: '玫红底 + 2px 琥珀粗边 + 角标 + 亮黄部分结标',
      },
    },
    {
      id: 'obsidianCarbon',
      group: 'core',
      isLight: false,
      name: '曜石暗黑',
      shortLabel: '🖤 曜石暗黑',
      modeTag: '深色 · AA',
      cardStyleTag: '炭黑叠色 · 左 4px 条 · 无发光',
      dot: '#111318',
      desc: '炭黑底叠 15~17% 状态色 + 左侧 4px 鲜明色条 + 状态色胶囊，零发光低眩光，极暗吧台与手持机护眼。',
      thumb: {
        canvas: '#111318',
        header: '#161920',
        footer: '#0E1117',
        brand: '#2563EB',
        text: '#F3F4F6',
        style: 'leftBar',
        cards: [
          { id: 'V01', fill: '#153540', accent: '#06B6D4', bd: '#1C5B6B', fg: '#F3F4F6', chip: '#0E6B74' },
          { id: 'A08', fill: '#3F2A18', accent: '#F97316', bd: '#8A4E1A', fg: '#F3F4F6', chip: '#A84E06' },
          { id: 'A12', fill: '#3D222E', accent: '#F43F5E', bd: '#F59E0B', fg: '#F3F4F6', chip: '#FBBF24', partial: true },
        ],
      },
      swatches: ['#111318', '#2B2A26', '#06B6D4', '#F97316', '#F43F5E', '#8B5CF6'],
      tokens: [
        ['主画布', '#111318'],
        ['顶栏', '#161920'],
        ['主按钮', '#2563EB'],
        ['空台底/条', '#232933'],
        ['锁定灰暗金', '#2B2A26'],
        ['预订底/条', '#153540'],
        ['开台暖橙', '#3F2A18'],
        ['点单底/条', '#3B222D'],
        ['部分结琥珀', '#F59E0B'],
        ['已结底/条', '#2A2646'],
        ['金额绿', '#34D399'],
      ],
      recipeSummary: {
        fillStyle: '炭黑叠 15~17% 状态色（锁定灰暗金 vs 开台暖橙）',
        accentStyle: '左侧 4px 状态色条（无发光）',
        textStyle: '雾白 #F3F4F6',
        partialStyle: '玫红左条 + 2px 琥珀三边 + 角标 + 金黄未付块',
      },
    },
    {
      id: 'daylightSlate',
      group: 'core',
      isLight: true,
      name: '晴空灰蓝',
      shortLabel: '☀️ 晴空灰蓝',
      modeTag: '浅色 · AA',
      cardStyleTag: '加深浅彩底 · 顶 6px 粗带 · 深炭字',
      dot: '#E6ECF5',
      desc: '加深 7 态清爽浅彩底配 6px 醒目顶部色带、深炭文字与实色高对比标签，1.5 米外扫一眼即辨全态，白天与财务核账利器。',
      thumb: {
        canvas: '#E6ECF5',
        header: '#FFFFFF',
        footer: '#FFFFFF',
        brand: '#2563EB',
        text: '#121A2C',
        style: 'topBar',
        cards: [
          { id: 'V01', fill: '#D2F3F7', accent: '#0891B2', bd: '#38B2C2', fg: '#121A2C', chip: '#0B6E75' },
          { id: 'A08', fill: '#FDE6C9', accent: '#D97706', bd: '#E89B48', fg: '#121A2C', chip: '#9A5205' },
          { id: 'A12', fill: '#FDDCE2', accent: '#E11D48', bd: '#D97706', fg: '#121A2C', chip: '#A35605', partial: true },
        ],
      },
      swatches: ['#E6ECF5', '#D2F3F7', '#FDE6C9', '#FDDCE2', '#E4DCFD', '#0891B2'],
      tokens: [
        ['主画布', '#E6ECF5'],
        ['顶栏/底栏', '#FFFFFF'],
        ['主按钮', '#2563EB'],
        ['空台底', '#E8EEF6'],
        ['锁定底', '#F3ECCF'],
        ['预订底', '#D2F3F7'],
        ['开台底', '#FDE6C9'],
        ['点单底', '#FDDCE2'],
        ['部分结琥珀', '#D97706'],
        ['已结底', '#E4DCFD'],
        ['金额深绿', '#035941'],
      ],
      recipeSummary: {
        fillStyle: '加深清爽状态彩底（脱离纯白）',
        accentStyle: '顶部 6px 粗状态色带 + 状态描边',
        textStyle: '深炭 #121A2C + 实色白字标签',
        partialStyle: '顶 6px 玫红带 + 2px 琥珀框 + 角标 + 暖琥珀未付块',
      },
    },
    {
      id: 'blackGoldLounge',
      group: 'ext',
      isLight: false,
      name: '黑金尊享',
      shortLabel: '✨ 黑金尊享',
      modeTag: '深色 · AA',
      cardStyleTag: '哑光暖黑 · 拉丝金顶线 · 左宝石条',
      dot: '#D4A853',
      desc: '哑光暖黑叠宝石暗彩，拉丝香槟金顶线配左侧 4px 宝石条与鎏金台号，高端 Lounge 与 VIP 厅专属。',
      thumb: {
        canvas: '#12100E',
        header: '#181512',
        footer: '#100E0C',
        brand: '#D4A853',
        text: '#F8F3E8',
        style: 'blackGold',
        cards: [
          { id: 'V01', fill: '#162D28', accent: '#14B8A6', bd: '#26594D', fg: '#F5D68E', chip: '#0D6E6E' },
          { id: 'A08', fill: '#382914', accent: '#F59E0B', bd: '#78541F', fg: '#F5D68E', chip: '#9A5306' },
          { id: 'A12', fill: '#3A1A22', accent: '#E11D48', bd: '#F59E0B', fg: '#F5D68E', chip: '#E5B95C', partial: true },
        ],
      },
      swatches: ['#12100E', '#D4A853', '#14B8A6', '#F59E0B', '#E11D48', '#8B5CF6'],
      tokens: [
        ['主画布', '#12100E'],
        ['香槟金', '#D4A853'],
        ['鎏金台号', '#F5D68E'],
        ['预订宝石', '#162D28'],
        ['开台宝石', '#382914'],
        ['点单红宝', '#381920'],
        ['部分结金框', '#F59E0B'],
        ['已结紫晶', '#291F38'],
      ],
      recipeSummary: {
        fillStyle: '暖黑哑光叠宝石色',
        accentStyle: '拉丝金顶线 + 左 4px 宝石条',
        textStyle: '鎏金台号 #F5D68E + 象牙白',
        partialStyle: '红宝左条 + 2px 琥珀金框 + 香槟金标签',
      },
    },
    {
      id: 'cyberNeonViolet',
      group: 'ext',
      isLight: false,
      name: '赛博霓紫',
      shortLabel: '⚡ 赛博霓紫',
      modeTag: '深色 · AA',
      cardStyleTag: '深紫玻璃 · 霓虹外发光边 · 顶光条',
      dot: '#7C3AED',
      desc: '深紫外黑底配彩色霓虹外发光描边与 3px 顶光条，电光青高亮金额，电音夜店与派对现场感拉满。',
      thumb: {
        canvas: '#120D24',
        header: '#1A1333',
        footer: '#0D091B',
        brand: '#7C3AED',
        text: '#F6F3FF',
        style: 'neon',
        cards: [
          { id: 'V01', fill: '#132E47', accent: '#06B6D4', bd: '#22D3EE', fg: '#F6F3FF', chip: '#0D6E7A' },
          { id: 'A08', fill: '#3B2823', accent: '#F59E0B', bd: '#F59E0B', fg: '#F6F3FF', chip: '#9A5306' },
          { id: 'A12', fill: '#411B40', accent: '#EC4899', bd: '#FBBF24', fg: '#F6F3FF', chip: '#FBBF24', partial: true },
        ],
      },
      swatches: ['#120D24', '#7C3AED', '#22D3EE', '#F59E0B', '#EC4899', '#A855F7'],
      tokens: [
        ['主画布', '#120D24'],
        ['电光紫', '#7C3AED'],
        ['霓虹青', '#22D3EE'],
        ['霓虹粉', '#EC4899'],
        ['部分结霓黄', '#FBBF24'],
        ['已结霓紫', '#A855F7'],
      ],
      recipeSummary: {
        fillStyle: '深紫外黑底叠荧光色',
        accentStyle: '3px 顶光条 + 彩色霓虹外发光描边',
        textStyle: '冷紫白 #F6F3FF + 霓青金额',
        partialStyle: '顶霓粉条 + 2px 霓黄外光框 + 亮黄标签',
      },
    },
    {
      id: 'emeraldJazz',
      group: 'ext',
      isLight: false,
      name: '墨绿爵士',
      shortLabel: '🎷 墨绿爵士',
      modeTag: '深色 · AA',
      cardStyleTag: '宝石丝绒渐变 · 暖黄铜细边',
      dot: '#047857',
      desc: '深墨绿底配复古宝石丝绒渐变实色卡与暖黄铜细边，浓郁而不刺眼，威士忌吧与清吧高级质感。',
      thumb: {
        canvas: '#0D1916',
        header: '#12221E',
        footer: '#0A1412',
        brand: '#047857',
        text: '#EDF7F4',
        style: 'velvet',
        cards: [
          { id: 'V01', fill: '#0E686B', accent: '#0E686B', bd: '#C9A45C', fg: '#FFFFFF', chip: '#092122' },
          { id: 'A08', fill: '#96500E', accent: '#96500E', bd: '#C9A45C', fg: '#FFFFFF', chip: '#241506' },
          { id: 'A12', fill: '#9B2342', accent: '#9B2342', bd: '#F5B749', fg: '#FFFFFF', chip: '#FBBF24', partial: true },
        ],
      },
      swatches: ['#0D1916', '#047857', '#C9A45C', '#0E686B', '#96500E', '#9B2342'],
      tokens: [
        ['主画布', '#0D1916'],
        ['爵士绿', '#047857'],
        ['黄铜边', '#C9A45C'],
        ['预订孔雀', '#0E686B'],
        ['开台琥珀', '#96500E'],
        ['点单酒红', '#9B2342'],
        ['部分结金边', '#F5B749'],
        ['已结深紫', '#4B3596'],
      ],
      recipeSummary: {
        fillStyle: '低明度宝石丝绒渐变',
        accentStyle: '整卡丝绒 + 暖黄铜细边',
        textStyle: '纯白 #FFFFFF + 薄荷金额',
        partialStyle: '酒红丝绒 + 2px 暖金框 + 角标 + 金黄标签',
      },
    },
    {
      id: 'emeraldFresh',
      group: 'ext',
      isLight: true,
      name: '翡翠白玉',
      shortLabel: '🌿 翡翠白玉',
      modeTag: '浅色 · AA',
      cardStyleTag: '纯白玉卡 · 顶部实色头栏',
      dot: '#0F766E',
      desc: '纯白玉卡体配顶部全宽实色状态头栏（现代餐饮中控风格），信息分区干脆利落，全天清新耐看。',
      thumb: {
        canvas: '#E8F0EE',
        header: '#FFFFFF',
        footer: '#FFFFFF',
        brand: '#0F766E',
        text: '#10201C',
        style: 'headerBand',
        cards: [
          { id: 'V01', fill: '#FFFFFF', accent: '#0C7B81', bd: '#5ECAD4', fg: '#10201C', chip: '#0C7B81' },
          { id: 'A08', fill: '#FFFFFF', accent: '#A85B06', bd: '#F5B56E', fg: '#10201C', chip: '#A85B06' },
          { id: 'A12', fill: '#FFFFFF', accent: '#C2264B', bd: '#D97706', fg: '#10201C', chip: '#A85B06', partial: true },
        ],
      },
      swatches: ['#E8F0EE', '#FFFFFF', '#0F766E', '#0C7B81', '#A85B06', '#C2264B'],
      tokens: [
        ['主画布', '#E8F0EE'],
        ['白玉卡底', '#FFFFFF'],
        ['翡翠主色', '#0F766E'],
        ['预订头栏', '#0C7B81'],
        ['开台头栏', '#A85B06'],
        ['点单头栏', '#C2264B'],
        ['部分结琥珀', '#D97706'],
        ['已结头栏', '#4C31B8'],
      ],
      recipeSummary: {
        fillStyle: '纯白玉卡体 #FFFFFF',
        accentStyle: '顶部全宽实色状态头栏（白字）',
        textStyle: '深玉墨 #10201C + 实色胶囊',
        partialStyle: '玫红头栏 + 2px 琥珀框 + 亮黄角标 + 暖琥珀未付',
      },
    },
    {
      id: 'warmIvoryBistro',
      group: 'ext',
      isLight: true,
      name: '暖杏轻咖',
      shortLabel: '☕ 暖杏轻咖',
      modeTag: '浅色 · AA',
      cardStyleTag: '奶油浅彩底 · 左 5px 彩条 · 暖棕护眼',
      dot: '#F0E9DF',
      desc: '低蓝光暖奶油浅彩底配左侧 5px 宽状态彩条与暖棕文字，长时间盯屏无冷白刺眼感，餐酒馆/Bistro 首选。',
      thumb: {
        canvas: '#F0E9DF',
        header: '#FFFDF9',
        footer: '#FFFDF9',
        brand: '#B45309',
        text: '#261E18',
        style: 'warmLeftBar',
        cards: [
          { id: 'V01', fill: '#EFFAF8', accent: '#0891B2', bd: '#6FC9C4', fg: '#261E18', chip: '#0C7B81' },
          { id: 'A08', fill: '#FEF5EB', accent: '#D97706', bd: '#F2B572', fg: '#261E18', chip: '#A85B06' },
          { id: 'A12', fill: '#FDF2F2', accent: '#E11D48', bd: '#D97706', fg: '#261E18', chip: '#A85B06', partial: true },
        ],
      },
      swatches: ['#F0E9DF', '#FFFDF9', '#B45309', '#0891B2', '#D97706', '#E11D48'],
      tokens: [
        ['奶油画布', '#F0E9DF'],
        ['轻咖主色', '#B45309'],
        ['暖棕主字', '#261E18'],
        ['预订底', '#EFFAF8'],
        ['开台底', '#FEF5EB'],
        ['点单底', '#FDF2F2'],
        ['部分结琥珀', '#D97706'],
        ['已结底', '#F6F2FC'],
      ],
      recipeSummary: {
        fillStyle: '低蓝光奶油浅彩洗底',
        accentStyle: '左侧 5px 宽状态彩条 + 暖描边',
        textStyle: '深咖棕 #261E18 + 实色胶囊',
        partialStyle: '左 5px 玫红条 + 2px 琥珀框 + 角标 + 暖杏未付',
      },
    },
  ];

  const SKIN_MAP = Object.fromEntries(SKINS.map((s) => [s.id, s]));
  const CORE_SKINS = SKINS.filter((s) => s.group === 'core');
  const EXT_SKINS = SKINS.filter((s) => s.group === 'ext');

  function readInitialSkin() {
    try {
      const qs = new URLSearchParams(window.location.search).get('skin');
      if (qs && SKIN_MAP[qs]) return qs;
    } catch (_) {}
    try {
      const saved = window.localStorage.getItem(STORAGE_KEY);
      if (saved && SKIN_MAP[saved]) return saved;
    } catch (_) {}
    return 'midnightBlue';
  }

  function readInitialReducedMotion() {
    try {
      const saved = window.localStorage.getItem(MOTION_KEY);
      if (saved === 'true') return true;
      if (saved === 'false') return false;
    } catch (_) {}
    try {
      return Boolean(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
    } catch (_) {
      return false;
    }
  }

  let currentSkin = readInitialSkin();
  let reducedMotion = readInitialReducedMotion();

  function applyReducedMotion(flag, { persist = true, silent = false } = {}) {
    reducedMotion = Boolean(flag);
    if (persist) {
      try {
        window.localStorage.setItem(MOTION_KEY, reducedMotion ? 'true' : 'false');
      } catch (_) {}
    }
    const val = reducedMotion ? 'true' : 'false';
    document.documentElement.setAttribute('data-reduced-motion', val);
    const frame = document.getElementById('deviceFrame');
    if (frame) {
      frame.setAttribute('data-reduced-motion', val);
    }
    document.querySelectorAll('[data-reduced-motion-toggle]').forEach((btn) => {
      btn.classList.toggle('active', reducedMotion);
      btn.setAttribute('aria-pressed', reducedMotion ? 'true' : 'false');
      btn.textContent = reducedMotion ? '⏸ 减少动效：开' : '🎞 减少动效：关';
    });
    if (!silent) {
      window.dispatchEvent(new CustomEvent('shouyin-motion-change', { detail: { reducedMotion } }));
    }
  }

  function flashStateChange(el) {
    if (!el || reducedMotion) return;
    el.classList.remove('rc-state-changed');
    void el.offsetWidth;
    el.classList.add('rc-state-changed');
    clearTimeout(el._rcFlashTimer);
    el._rcFlashTimer = setTimeout(() => {
      el.classList.remove('rc-state-changed');
    }, 440);
  }

  function getSkinMeta(id) {
    return SKIN_MAP[id || currentSkin] || SKIN_MAP.midnightBlue;
  }

  function isLightSkin(id) {
    return Boolean(getSkinMeta(id).isLight);
  }

  function renderThumbCardHtml(c, style) {
    let sty = `background:${c.fill};color:${c.fg};`;
    let hdrHtml = '';
    let extraCls = c.partial ? ' is-partial' : '';

    if (style === 'solid') {
      sty += `border:${c.partial ? '1.5px' : '1px'} solid ${c.bd};box-shadow:inset 0 1px 0 rgba(255,255,255,0.35);`;
    } else if (style === 'leftBar') {
      sty += `border:${c.partial ? '1.5px' : '1px'} solid ${c.bd};border-left:3.5px solid ${c.accent};`;
    } else if (style === 'topBar') {
      sty += `border:${c.partial ? '1.5px' : '1px'} solid ${c.bd};border-top:4px solid ${c.accent};`;
    } else if (style === 'blackGold') {
      sty += `border:${c.partial ? '1.5px' : '1px'} solid ${c.bd};border-top:1.5px solid rgba(212,168,83,0.75);border-left:3.5px solid ${c.accent};`;
    } else if (style === 'neon') {
      sty += `border:1.5px solid ${c.bd};border-top:2.5px solid ${c.accent};box-shadow:0 0 6px ${c.bd}80;`;
    } else if (style === 'velvet') {
      sty += `background:linear-gradient(165deg,${c.fill} 0%,#0B1613 130%);border:${c.partial ? '1.5px' : '1px'} solid ${c.bd};`;
    } else if (style === 'headerBand') {
      sty += `border:${c.partial ? '1.5px' : '1px'} solid ${c.bd};`;
      hdrHtml = `<span class="sp-tc-hdr" style="background:${c.accent}"></span>`;
      extraCls += ' has-hdr';
    } else if (style === 'warmLeftBar') {
      sty += `border:${c.partial ? '1.5px' : '1px'} solid ${c.bd};border-left:4px solid ${c.accent};`;
    }

    return `<div class="sp-thumb-card${extraCls}" style="${sty}">${hdrHtml}<b>${c.id}</b><span class="sp-tc-chip" style="background:${c.chip}"></span></div>`;
  }

  function renderThumbHtml(s) {
    const t = s.thumb;
    return `
      <div class="sp-thumb" style="background:${t.canvas}">
        <div class="sp-thumb-hd" style="background:${t.header}">
          <div class="sp-thumb-dots">
            <i style="background:${t.text};opacity:.55"></i>
            <i style="background:${t.text};opacity:.32"></i>
            <i style="background:${t.text};opacity:.32"></i>
          </div>
          <div class="sp-thumb-cta" style="background:${t.brand}"></div>
        </div>
        <div class="sp-thumb-bd">
          ${t.cards.map((c) => renderThumbCardHtml(c, t.style)).join('')}
        </div>
        <div class="sp-thumb-ft" style="background:${t.footer}">
          <div class="sp-thumb-bar" style="background:${t.text};opacity:.35"></div>
          <div class="sp-thumb-cta" style="background:${t.brand};width:16px;height:5px"></div>
        </div>
      </div>
    `;
  }

  function renderSkinCard(s) {
    const active = s.id === currentSkin;
    return `
      <button type="button" class="sp-card ${active ? 'active' : ''}" data-skin-card="${s.id}" onclick="ShouyinSkin.set('${s.id}')">
        ${renderThumbHtml(s)}
        <div class="sp-card-meta">
          <div class="sp-card-top">
            <span class="sp-card-name">${s.name}</span>
            <span class="sp-card-tag">${active ? '✓ 使用中' : s.modeTag}</span>
          </div>
          <div class="sp-card-desc">${s.group === 'core' ? s.desc : s.cardStyleTag}</div>
          <div class="sp-swatches">
            ${s.swatches.map((hex) => `<i style="background:${hex}" title="${hex}"></i>`).join('')}
          </div>
        </div>
      </button>
    `;
  }

  function injectStudioControls() {
    const controls = document.querySelector('.studio-controls');
    if (!controls || document.getElementById('skinSegGroup')) return;

    // Remove legacy S2 binary theme toggle chip if present
    const legacyToggle = document.getElementById('themeToggleTop');
    if (legacyToggle) legacyToggle.remove();

    // 1. Core 3-skin fast switcher
    const seg = document.createElement('div');
    seg.className = 'skin-seg-group';
    seg.id = 'skinSegGroup';
    seg.setAttribute('role', 'group');
    seg.setAttribute('aria-label', '首发 3 套核心皮肤快切');
    seg.innerHTML = CORE_SKINS.map(
      (s) =>
        `<button type="button" class="skin-seg-btn" data-skin-opt="${s.id}" onclick="ShouyinSkin.set('${s.id}')">` +
        `<span class="skin-dot" style="background:${s.dot}"></span>${s.name}</button>`
    ).join('');

    // 2. All 8 skins picker button
    const pickerBtn = document.createElement('button');
    pickerBtn.type = 'button';
    pickerBtn.className = 'skin-picker-open-btn';
    pickerBtn.id = 'studioSkinPickerBtn';
    pickerBtn.innerHTML = '🎨 全部皮肤 (8)';
    pickerBtn.onclick = () => openPicker();

    // 3. 7-state comparison matrix link
    const compareLink = document.createElement('a');
    compareLink.className = 'skin-compare-link';
    compareLink.id = 'studioCompareLink';
    compareLink.href = 'compare.html?skin=' + encodeURIComponent(currentSkin);
    compareLink.innerHTML = '📊 7态对比';

    // 4. Reduced Motion toggle (Studio Bar)
    const motionBtn = document.createElement('button');
    motionBtn.type = 'button';
    motionBtn.className = 'skin-motion-btn';
    motionBtn.id = 'studioReducedMotionBtn';
    motionBtn.setAttribute('data-reduced-motion-toggle', '1');
    motionBtn.title = '开启后立即禁用全部动效、过渡与弹窗毛玻璃（低配平板兜底）';
    motionBtn.onclick = () => applyReducedMotion(!reducedMotion);

    controls.appendChild(seg);
    controls.appendChild(pickerBtn);
    controls.appendChild(compareLink);
    controls.appendChild(motionBtn);
  }

  function injectPickerOverlay() {
    const frame = document.getElementById('deviceFrame');
    if (!frame || document.getElementById('skinPickerOverlay')) return;

    const overlay = document.createElement('div');
    overlay.className = 'sp-overlay';
    overlay.id = 'skinPickerOverlay';
    overlay.onclick = (e) => {
      if (e.target === overlay) closePicker();
    };

    overlay.innerHTML = `
      <div class="sp-dialog" role="dialog" aria-modal="true" aria-label="界面皮肤选择">
        <div class="sp-handle"></div>
        <div class="sp-hd">
          <div class="sp-hd-title">
            <strong>🎨 界面皮肤 · 10 字段卡片配方体系（共 8 套）</strong>
            <span>同状态色相统一 · 1.5 米外一眼可辨 · 瞬切皮肤不中断点单与结账</span>
          </div>
          <button type="button" class="sp-close" onclick="ShouyinSkin.closePicker()" title="关闭 (Esc)">✕</button>
        </div>
        <div class="sp-body">
          <div class="sp-sec-hd">
            <span>★ 首发 3 套核心皮肤（本期开发范围）</span>
            <small>实色满铺 / 炭黑左条 / 加深浅底 + 6px 顶带 · 三种截然不同的卡台视觉语言</small>
          </div>
          <div class="sp-grid-3" id="skinPickerCoreGrid"></div>

          <div class="sp-sec-hd">
            <span>✦ 5 套拓展风格（仅作选型参考，不进入计划）</span>
            <small>均基于同一套 10 字段卡片配方 · 全量通过 WCAG 2.1 AA (≥ 4.5:1)</small>
          </div>
          <div class="sp-grid-5" id="skinPickerExtGrid"></div>

          <div class="sp-note">
            <b>收银风控与质感规范：</b>
            ① <b>部分结（状态 6）</b>全皮肤锁定「玫红语义 + 2px 琥珀粗边 + 右上琥珀角标 + 醒目部分结标签 + 高亮未付金额块」；
            ② <b>精致静态阴影 + 弹框轻毛玻璃 + 3 种轻量动效</b>（按压 0.97 / 单卡状态变色微闪 / 180ms 抽屉滑入）；
            ③ 开启「减少动效」时一键关闭全部动效与毛玻璃，兼顾高级感与低配平板性能。
          </div>
        </div>
        <div class="sp-ft">
          <span class="sp-ft-info" id="skinPickerStatus">当前皮肤：午夜深蓝</span>
          <div class="sp-ft-acts">
            <button type="button" class="sp-motion-toggle" data-reduced-motion-toggle="1" onclick="ShouyinSkin.toggleReducedMotion()" title="一键关闭全部动效与弹框毛玻璃">🎞 减少动效：关</button>
            <a class="skin-compare-link" id="pickerCompareLink" href="compare.html">📊 打开 7 态横向对比矩阵 →</a>
            <button type="button" class="btn btn-primary btn-primary-pill btn-brand btn-sm" style="height:30px;padding:0 16px;border-radius:15px" onclick="ShouyinSkin.closePicker()">完成</button>
          </div>
        </div>
      </div>
    `;
    frame.appendChild(overlay);
    renderPickerCards();
  }

  function renderPickerCards() {
    const coreGrid = document.getElementById('skinPickerCoreGrid');
    const extGrid = document.getElementById('skinPickerExtGrid');
    if (coreGrid) {
      coreGrid.innerHTML = CORE_SKINS.map(renderSkinCard).join('');
    }
    if (extGrid) {
      extGrid.innerHTML = EXT_SKINS.map(renderSkinCard).join('');
    }
  }

  function updateTokenStrip(meta) {
    const strip = document.getElementById('tokenSwatches');
    if (!strip) return;
    const title = document.getElementById('tokenStripTitle');
    if (title) {
      title.textContent = `当前皮肤核心色板：${meta.name}（${meta.id} · ${meta.modeTag} · ${meta.cardStyleTag}）`;
    }
    strip.innerHTML = meta.tokens
      .map(
        ([label, hex]) =>
          `<div class="sw"><span class="sw-box" style="background:${hex}"></span>${label} ${hex}</div>`
      )
      .join('');
  }

  function syncNavLinks(skinId) {
    const cmp = document.getElementById('studioCompareLink');
    if (cmp) cmp.href = 'compare.html?skin=' + encodeURIComponent(skinId);
    const pickerCmp = document.getElementById('pickerCompareLink');
    if (pickerCmp) pickerCmp.href = 'compare.html?skin=' + encodeURIComponent(skinId);
  }

  function applySkin(id, { silent = false } = {}) {
    const meta = getSkinMeta(id);
    currentSkin = meta.id;
    try {
      window.localStorage.setItem(STORAGE_KEY, currentSkin);
    } catch (_) {}

    const frame = document.getElementById('deviceFrame');
    if (frame) {
      frame.dataset.skin = currentSkin;
      frame.classList.toggle('theme-light', Boolean(meta.isLight));
    }

    document.querySelectorAll('.skin-seg-btn').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.skinOpt === currentSkin);
    });

    const pickerBtn = document.getElementById('studioSkinPickerBtn');
    if (pickerBtn) {
      const isExt = meta.group === 'ext';
      pickerBtn.classList.toggle('ext-active', isExt);
      pickerBtn.innerHTML = isExt ? `🎨 ${meta.name} (8)` : '🎨 全部皮肤 (8)';
    }

    document.querySelectorAll('[data-theme-pill], [data-skin-pill]').forEach((el) => {
      el.textContent = meta.shortLabel + ' ▾';
    });

    const themeMetaTxt = document.getElementById('themeMetaTxt');
    if (themeMetaTxt) {
      themeMetaTxt.textContent = `${meta.name} (${meta.id} · ${meta.cardStyleTag})`;
    }

    const pickerStatus = document.getElementById('skinPickerStatus');
    if (pickerStatus) {
      pickerStatus.textContent = `当前皮肤：${meta.name}（${meta.modeTag} · ${meta.cardStyleTag}）`;
    }

    syncNavLinks(currentSkin);
    renderPickerCards();
    updateTokenStrip(meta);

    if (!silent) {
      window.dispatchEvent(new CustomEvent('shouyin-skin-change', { detail: meta }));
    }
  }

  function openPicker() {
    const overlay = document.getElementById('skinPickerOverlay');
    if (overlay) {
      renderPickerCards();
      applyReducedMotion(reducedMotion, { persist: false, silent: true });
      overlay.classList.add('open');
      const frame = document.getElementById('deviceFrame');
      if (frame && typeof frame.scrollIntoView === 'function') {
        frame.scrollIntoView({ behavior: reducedMotion ? 'auto' : 'smooth', block: 'center' });
      }
    }
  }

  function closePicker() {
    const overlay = document.getElementById('skinPickerOverlay');
    if (overlay) overlay.classList.remove('open');
  }

  function updateOneScrollFade(wrap) {
    const scroller = wrap.querySelector('[data-scroll-inner]') || wrap.firstElementChild;
    if (!scroller) return;
    const hasMore = scroller.scrollWidth > scroller.clientWidth + 3 &&
      (scroller.scrollLeft + scroller.clientWidth) < (scroller.scrollWidth - 3);
    wrap.classList.toggle('has-more', hasMore);
  }

  function refreshScrollFades() {
    document.querySelectorAll('.scroll-fade-wrap').forEach((wrap) => {
      const scroller = wrap.querySelector('[data-scroll-inner]') || wrap.firstElementChild;
      if (scroller && !scroller.dataset.fadeBound) {
        scroller.dataset.fadeBound = '1';
        scroller.addEventListener('scroll', () => updateOneScrollFade(wrap), { passive: true });
      }
      updateOneScrollFade(wrap);
    });
  }

  window.ShouyinSkin = {
    skins: SKINS,
    coreSkins: CORE_SKINS,
    extSkins: EXT_SKINS,
    isLight: isLightSkin,
    get: () => currentSkin,
    meta: (id) => getSkinMeta(id),
    set: (id) => applySkin(id),
    getReducedMotion: () => reducedMotion,
    setReducedMotion: (flag) => applyReducedMotion(flag),
    toggleReducedMotion: () => applyReducedMotion(!reducedMotion),
    flashStateChange,
    refreshScrollFades,
    openPicker,
    closePicker,
    renderThumbHtml,
  };

  // Override legacy S2 toggleOrderTheme so clicking any in-app pill opens the 8-skin picker
  window.toggleOrderTheme = function () {
    openPicker();
  };

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      const overlay = document.getElementById('skinPickerOverlay');
      if (overlay && overlay.classList.contains('open')) {
        closePicker();
      }
    }
  });

  function init() {
    injectStudioControls();
    injectPickerOverlay();
    applySkin(currentSkin, { silent: true });
    applyReducedMotion(reducedMotion, { persist: false, silent: true });
    setTimeout(refreshScrollFades, 120);
    window.addEventListener('resize', () => setTimeout(refreshScrollFades, 80));
    document.addEventListener('click', () => setTimeout(refreshScrollFades, 180));
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
