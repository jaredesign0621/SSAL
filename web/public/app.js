// --- Firebase 초기화 및 설정 (제공해주신 프로젝트 연동) ---
const firebaseConfig = {
  apiKey: "AIzaSyDBdCwv1gkmOIj6acZLIdXvlko8ONnhdxU",
  authDomain: "ssal-1bd3b.firebaseapp.com",
  projectId: "ssal-1bd3b",
  storageBucket: "ssal-1bd3b.firebasestorage.app",
  messagingSenderId: "54806698292",
  appId: "1:54806698292:web:0094b69e50d754fa542d61",
  measurementId: "G-WVBGHF7G9G"
};

let fbApp = null;
let fbAuth = null;
let fbDb = null;
let isFirebaseReady = false;

try {
  if (typeof firebase !== 'undefined') {
    fbApp = firebase.initializeApp(firebaseConfig);
    fbAuth = firebase.auth();
    fbDb = firebase.firestore();
    isFirebaseReady = true;
    console.log('🔥 Firebase Cloud Connected successfully to ssal-1bd3b');
  }
} catch (err) {
  console.warn('Firebase initialization error, fallback to local storage:', err);
}

// --- 초기 기본 데이터 (가라데이터 없는 순수 상태) ---
const INITIAL_DATA = {
  games: [],
  servers: [],
  characters: [],
  currencies: [],
  marketItems: [],
  exchangeRecords: [],
  selectedGameId: null,
  selectedServerId: null,
  selectedCharId: null,
  users: [
    { id: 1, username: 'jared0621', password: 'Tlsgn112!', nickname: 'Jared (마스터)', role: 'admin', createdAt: '2026-10-21' },
    { id: 2, username: 'admin', password: 'admin', nickname: '최고관리자', role: 'admin', createdAt: '2026-10-15' }
  ],
  currentUser: null
};

// --- 로컬 & 클라우드 스토리지 관리 ---
const STORAGE_KEY = 'ssal_offline_app_state_v2';

function loadState() {
  const saved = localStorage.getItem(STORAGE_KEY);
  let state = null;
  if (saved) {
    try {
      state = JSON.parse(saved);
    } catch (e) {
      console.error('Error loading state:', e);
    }
  }
  if (!state) {
    state = JSON.parse(JSON.stringify(INITIAL_DATA));
  }
  // jared0621 계정 자동 보장
  if (!state.users) state.users = [];
  const existingJared = state.users.find(u => u.username === 'jared0621');
  if (existingJared) {
    existingJared.password = 'Tlsgn112!';
    existingJared.role = 'admin';
  } else {
    state.users.unshift({
      id: 1,
      username: 'jared0621',
      password: 'Tlsgn112!',
      nickname: 'Jared (마스터)',
      role: 'admin',
      createdAt: '2026-10-21'
    });
  }
  return state;
}

let appState = loadState();

// 실시간 저장 (로컬 캐시 저장 + 로그인 시 Firebase 클라우드 자동 동기화)
function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(appState));
  renderAll();

  // 로그인된 유저가 있으면 Firebase Cloud Firestore에 실시간 동기화
  if (isFirebaseReady && fbDb && appState.currentUser) {
    const userDocId = String(appState.currentUser.id || appState.currentUser.username || 'user');
    fbDb.collection('user_data').doc(userDocId).set({
      games: appState.games,
      servers: appState.servers,
      characters: appState.characters,
      currencies: appState.currencies,
      marketItems: appState.marketItems,
      exchangeRecords: appState.exchangeRecords,
      selectedGameId: appState.selectedGameId,
      selectedServerId: appState.selectedServerId,
      selectedCharId: appState.selectedCharId,
      lastUpdated: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true }).catch(e => console.warn('Cloud sync error:', e));
  }
}

let cloudUnsubscribe = null;

// 클라우드 실시간 리스너 연동 (웹과 앱 화면 간 실시간 양방향 싱크)
function attachCloudSyncListener(userId) {
  if (!isFirebaseReady || !fbDb || !userId) return;
  if (cloudUnsubscribe) {
    cloudUnsubscribe();
    cloudUnsubscribe = null;
  }

  const userDocRef = fbDb.collection('user_data').doc(String(userId));
  cloudUnsubscribe = userDocRef.onSnapshot(doc => {
    if (doc.exists) {
      const cloudData = doc.data();
      // 원격 클라우드 최신 데이터로 로컬 메모리 상태 갱신
      appState.games = cloudData.games || [];
      appState.servers = cloudData.servers || [];
      appState.characters = cloudData.characters || [];
      appState.currencies = cloudData.currencies || [];
      appState.marketItems = cloudData.marketItems || [];
      appState.exchangeRecords = cloudData.exchangeRecords || [];
      if (cloudData.selectedGameId !== undefined) appState.selectedGameId = cloudData.selectedGameId;
      if (cloudData.selectedServerId !== undefined) appState.selectedServerId = cloudData.selectedServerId;
      if (cloudData.selectedCharId !== undefined) appState.selectedCharId = cloudData.selectedCharId;

      localStorage.setItem(STORAGE_KEY, JSON.stringify(appState));
      renderAll();
      console.log('🔄 Firestore Real-time Cloud Sync updated across devices');
    }
  }, err => {
    console.warn('Real-time sync listener error:', err);
  });
}

// 클라우드에서 유저 데이터 불러오기
async function loadUserDataFromCloud(userId) {
  if (!isFirebaseReady || !fbDb || !userId) return;
  attachCloudSyncListener(userId);
  try {
    const doc = await fbDb.collection('user_data').doc(String(userId)).get();
    if (doc.exists) {
      const cloudData = doc.data();
      appState.games = cloudData.games || [];
      appState.servers = cloudData.servers || [];
      appState.characters = cloudData.characters || [];
      appState.currencies = cloudData.currencies || [];
      appState.marketItems = cloudData.marketItems || [];
      appState.exchangeRecords = cloudData.exchangeRecords || [];
      appState.selectedGameId = cloudData.selectedGameId || null;
      appState.selectedServerId = cloudData.selectedServerId || null;
      appState.selectedCharId = cloudData.selectedCharId || null;
      saveState();
      showToast('☁️ 클라우드 데이터를 성공적으로 동기화했습니다.');
    }
  } catch (err) {
    console.warn('Cloud load error:', err);
  }
}

function resetData() {
  if (confirm('모든 데이터를 초기 상태로 리셋하시겠습니까?')) {
    appState = JSON.parse(JSON.stringify(INITIAL_DATA));
    saveState();
    showToast('데이터가 초기화되었습니다.');
  }
}

// --- 유틸리티 함수 ---
function formatNumber(num) {
  return (num || 0).toLocaleString();
}

function showToast(msg) {
  const toast = document.getElementById('toast');
  toast.innerText = msg;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2000);
}

// --- 캐릭터별 재화 헬퍼 ---
function getCharDiamond(charId) {
  const dia = appState.currencies.find(c => c.characterId === charId && (c.name === '재화' || c.name === '다이아'));
  return dia ? Number(dia.amount) : 0;
}

function setCharDiamond(charId, amount) {
  const val = Math.max(0, Number(amount) || 0);
  let dia = appState.currencies.find(c => c.characterId === charId && (c.name === '재화' || c.name === '다이아'));
  if (dia) {
    dia.name = '재화';
    dia.amount = val;
    dia.updatedAt = new Date().toISOString();
  } else {
    appState.currencies.push({
      id: Date.now() + Math.floor(Math.random() * 1000),
      characterId: charId,
      name: '재화',
      amount: val,
      updatedAt: new Date().toISOString()
    });
  }
}

// --- 탭 전환 ---
function switchTab(tabId) {
  document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));

  const targetPane = document.getElementById(tabId);
  if (targetPane) targetPane.classList.add('active');

  // 네비게이션 버튼 활성화 매핑 (캐릭터 화면은 게임/서버 탭의 하위이므로 navIndex 1 활성화)
  const navMap = {
    'tab-dashboard': 0,
    'tab-games': 1,
    'tab-characters': 1,
    'tab-market': 2,
    'tab-exchange': 3
  };
  const navIndex = navMap[tabId] ?? 0;
  const navButtons = document.querySelectorAll('.nav-item');
  if (navButtons[navIndex]) navButtons[navIndex].classList.add('active');

  renderAll();
}

// 서버 클릭 시 해당 서버의 캐릭터 등록/관리 화면으로 바로 진입
function openServerCharacters(serverId) {
  appState.selectedServerId = serverId;
  const chars = appState.characters.filter(c => c.serverId === serverId);
  if (chars.length > 0) {
    if (!chars.some(c => c.id === appState.selectedCharId)) {
      appState.selectedCharId = chars[0].id;
    }
  } else {
    appState.selectedCharId = null;
  }
  saveState();
  switchTab('tab-characters');
}

// 대시보드에서 캐릭터 관리로 이동 시
function goToCharacterScreen() {
  const server = getSelectedServer();
  if (server) {
    openServerCharacters(server.id);
  } else {
    switchTab('tab-characters');
  }
}

// --- 뷰어 모드 전환 (스마트폰 모드 / 전체화면 모드) ---
document.getElementById('view-mode-phone').addEventListener('click', () => {
  document.getElementById('app-wrapper').className = 'app-wrapper phone-mode';
  document.getElementById('view-mode-phone').classList.add('active');
  document.getElementById('view-mode-full').classList.remove('active');
});

document.getElementById('view-mode-full').addEventListener('click', () => {
  document.getElementById('app-wrapper').className = 'app-wrapper fullscreen-mode';
  document.getElementById('view-mode-full').classList.add('active');
  document.getElementById('view-mode-phone').classList.remove('active');
});

document.getElementById('reset-data-btn').addEventListener('click', resetData);

// --- 현재 선택 객체 헬퍼 ---
function getSelectedGame() {
  if (!appState.games || appState.games.length === 0) return null;
  return appState.games.find(g => g.id === appState.selectedGameId) || appState.games[0] || null;
}

function getSelectedServer() {
  if (!appState.servers || appState.servers.length === 0) return null;
  const currentServers = appState.servers.filter(s => s.gameId === appState.selectedGameId);
  return currentServers.find(s => s.id === appState.selectedServerId) || currentServers[0] || null;
}

function getSelectedCharacter() {
  if (!appState.characters || appState.characters.length === 0) return null;
  const currentChars = appState.characters.filter(c => c.serverId === appState.selectedServerId);
  return currentChars.find(c => c.id === appState.selectedCharId) || currentChars[0] || null;
}

// --- 전체 렌더링 ---
function renderAll() {
  renderAuthArea();
  renderQuickSelectors();
  renderDashboard();
  renderGamesAndServers();
  renderCharactersAndCurrencies();
  renderMarketItems();
  renderExchangeTab();
  renderAdminDashboard();
}

// --- 1. 상단 퀵 셀렉터 렌더링 ---
function renderQuickSelectors() {
  const gameSelect = document.getElementById('quick-game-select');
  const serverSelect = document.getElementById('quick-server-select');

  // 게임 드롭다운
  if (!appState.games || appState.games.length === 0) {
    gameSelect.innerHTML = '<option value="">(게임 없음)</option>';
  } else {
    gameSelect.innerHTML = appState.games.map(g => 
      `<option value="${g.id}" ${g.id === appState.selectedGameId ? 'selected' : ''}>${g.name}</option>`
    ).join('');
  }

  // 현재 게임의 서버 드롭다운
  const currentServers = appState.servers.filter(s => s.gameId === appState.selectedGameId);
  if (currentServers.length === 0) {
    serverSelect.innerHTML = '<option value="">(서버 없음)</option>';
  } else {
    serverSelect.innerHTML = currentServers.map(s => 
      `<option value="${s.id}" ${s.id === appState.selectedServerId ? 'selected' : ''}>${s.name}</option>`
    ).join('');
  }
}

// 셀렉터 이벤트 리스너
document.getElementById('quick-game-select').addEventListener('change', (e) => {
  appState.selectedGameId = Number(e.target.value);
  const servers = appState.servers.filter(s => s.gameId === appState.selectedGameId);
  appState.selectedServerId = servers.length > 0 ? servers[0].id : null;
  const chars = appState.characters.filter(c => c.serverId === appState.selectedServerId);
  appState.selectedCharId = chars.length > 0 ? chars[0].id : null;
  saveState();
});

document.getElementById('quick-server-select').addEventListener('change', (e) => {
  appState.selectedServerId = Number(e.target.value);
  const chars = appState.characters.filter(c => c.serverId === appState.selectedServerId);
  appState.selectedCharId = chars.length > 0 ? chars[0].id : null;
  saveState();
});

// --- 2. 대시보드 (홈) 렌더링 ---
function renderDashboard() {
  const game = getSelectedGame();
  const server = getSelectedServer();
  const char = getSelectedCharacter();

  const summaryEl = document.getElementById('dash-active-summary');
  if (summaryEl) {
    if (game && server) {
      summaryEl.innerText = `[${game.name}] ${server.name} (수수료 ${Number(server.feeRate).toFixed(1)}%)`;
    } else {
      summaryEl.innerText = '게임을 선택해 주세요.';
    }
  }

  // 누적 환전액
  const totalKrw = appState.exchangeRecords.reduce((sum, r) => sum + r.netKrwAmount, 0);
  const totalKrwEl = document.getElementById('dash-total-krw');
  if (totalKrwEl) totalKrwEl.innerText = `₩ ${formatNumber(totalKrw)}`;
  const krwCountEl = document.getElementById('dash-krw-count');
  if (krwCountEl) krwCountEl.innerText = `${appState.exchangeRecords.length}건 거래 완료`;

  // 거래소 아이템 (요소 존재 시 업데이트)
  const marketCountEl = document.getElementById('dash-market-count');
  const marketSubEl = document.getElementById('dash-market-sub');
  if (marketCountEl || marketSubEl) {
    const totalItems = appState.marketItems.length;
    const sellingItems = appState.marketItems.filter(i => i.status === '판매중').length;
    if (marketCountEl) marketCountEl.innerText = `${totalItems} 건`;
    if (marketSubEl) marketSubEl.innerText = `판매중 ${sellingItems}건`;
  }

  // 캐릭터 수
  const chars = appState.characters.filter(c => c.serverId === appState.selectedServerId);
  document.getElementById('dash-char-count').innerText = `${chars.length} 명`;

  // 수수료율
  document.getElementById('dash-fee-rate').innerText = server ? `${Number(server.feeRate).toFixed(1)}%` : '0.0%';

  // 선택 캐릭터 재화 리스트
  const currListEl = document.getElementById('dash-currency-list');
  if (char) {
    const dia = getCharDiamond(char.id);
    const serverChars = appState.characters.filter(c => c.serverId === appState.selectedServerId);
    const serverTotalDia = serverChars.reduce((sum, c) => sum + getCharDiamond(c.id), 0);

    currListEl.innerHTML = `
      <div class="currency-compact-row">
        <span class="currency-name-tag">[${char.name}] 보유 재화</span>
        <span class="currency-amount-tag">${formatNumber(dia)}</span>
      </div>
      <div class="currency-compact-row">
        <span class="currency-name-tag">[${server ? server.name : '서버'}] 전체 재화 총합</span>
        <span class="currency-amount-tag" style="color:var(--primary-gold-light);">${formatNumber(serverTotalDia)}</span>
      </div>
    `;
  } else {
    currListEl.innerHTML = '<div class="text-muted" style="font-size:12px;">캐릭터를 먼저 등록해 주세요.</div>';
  }
}

// --- 3. 게임 & 서버 관리 렌더링 ---
function renderGamesAndServers() {
  // 게임 칩 리스트 (카테고리 컨테이너 존재 시에만 렌더)
  const chipsContainer = document.getElementById('game-chips-container');
  if (chipsContainer) {
    chipsContainer.innerHTML = appState.games.map(g => {
      const isActive = g.id === appState.selectedGameId;
      return `
        <div class="chip-item ${isActive ? 'active' : ''}" onclick="selectGame(${g.id})">
          <span>🎮 ${g.name}</span>
          <div class="chip-actions">
            <button class="chip-action-btn" title="수정" onclick="event.stopPropagation(); openEditGameModal(${g.id})">✎</button>
            <button class="chip-action-btn" title="삭제" onclick="event.stopPropagation(); deleteGame(${g.id})">✕</button>
          </div>
        </div>
      `;
    }).join('');
  }

  // 서버 카드 리스트
  const serverList = document.getElementById('server-card-list');
  const currentServers = appState.servers.filter(s => s.gameId === appState.selectedGameId);

  if (currentServers.length === 0) {
    serverList.innerHTML = `
      <div class="text-muted text-center p-4">등록된 서버가 없습니다. 우측 상단 [+ 새 서버]를 눌러보세요.</div>
    `;
  } else {
    serverList.innerHTML = currentServers.map(s => {
      const isSelected = s.id === appState.selectedServerId;
      const chars = appState.characters.filter(c => c.serverId === s.id);
      const charCountBadge = chars.length > 0 
        ? `<span class="server-char-badge count-active">👤 ${chars.length}</span>` 
        : `<span class="server-char-badge count-empty">👤 0</span>`;

      return `
        <div class="server-card ${isSelected ? 'active' : ''}" onclick="openServerCharacters(${s.id})" title="클릭 시 [${s.name}] 캐릭터 관리 화면으로 이동">
          <div class="server-left">
            <div class="server-info-col">
              <div class="server-title-row">
                <span class="server-name">${s.name} ${isSelected ? '★' : ''}</span>
                ${charCountBadge}
              </div>
              <div class="server-sub">
                <span class="server-fee-tag">수수료 ${Number(s.feeRate).toFixed(1)}%</span>
              </div>
            </div>
          </div>
          <div class="server-right-side">
            <div class="card-actions" onclick="event.stopPropagation()">
              <button class="icon-btn" title="서버 정보 수정" onclick="openEditServerModal(${s.id})">✎</button>
              <button class="icon-btn delete" title="서버 삭제" onclick="deleteServer(${s.id})">🗑</button>
            </div>
          </div>
        </div>
      `;
    }).join('');
  }
}

function selectGame(gameId) {
  appState.selectedGameId = gameId;
  const servers = appState.servers.filter(s => s.gameId === gameId);
  appState.selectedServerId = servers.length > 0 ? servers[0].id : null;
  const chars = appState.characters.filter(c => c.serverId === appState.selectedServerId);
  appState.selectedCharId = chars.length > 0 ? chars[0].id : null;
  saveState();
}

function selectServer(serverId) {
  appState.selectedServerId = serverId;
  const chars = appState.characters.filter(c => c.serverId === serverId);
  appState.selectedCharId = chars.length > 0 ? chars[0].id : null;
  saveState();
}

// --- 4. 캐릭터 및 재화 관리 렌더링 (서버 하위 화면) ---
function renderCharactersAndCurrencies() {
  const server = getSelectedServer();

  const currentChars = appState.characters.filter(c => c.serverId === appState.selectedServerId);
  const groupedContainer = document.getElementById('char-account-grouped-list');
  const summaryContainer = document.getElementById('server-diamond-summary');

  // 등록된 캐릭터가 없는 경우
  if (currentChars.length === 0) {
    groupedContainer.innerHTML = `
      <div class="empty-char-banner">
        <div class="empty-icon">👤</div>
        <div class="empty-info">
          <div class="empty-title">등록된 캐릭터가 없습니다</div>
          <div class="empty-sub">[${server ? server.name : '선택된 서버'}]에 첫 번째 캐릭터를 등록해 보세요.</div>
        </div>
        <button class="btn btn-sm btn-primary" onclick="openAddCharModal()">+ 캐릭터 등록</button>
      </div>
    `;
    summaryContainer.innerHTML = '<div class="text-muted text-center p-3" style="font-size:12px;">캐릭터를 등록하면 보유 재화 합계가 계산됩니다.</div>';
    return;
  }

  // 1) 계정 정보별로 캐릭터 그룹화 (Account Grouping)
  const accountGroups = {};
  currentChars.forEach(c => {
    const acc = c.accountInfo?.trim() || '미지정 계정';
    if (!accountGroups[acc]) accountGroups[acc] = [];
    accountGroups[acc].push(c);
  });

  // 계정별 캐릭터 리스트 렌더링 (정리 및 간소화, 활성화는 account-group-card에 표현)
  groupedContainer.innerHTML = Object.entries(accountGroups).map(([accountName, chars]) => {
    const isGroupActive = chars.some(c => c.id === appState.selectedCharId);
    return `
      <div class="account-group-card ${isGroupActive ? 'active' : ''}" onclick="selectCharacter(${chars[0].id})">
        <div class="account-group-header">
          <div class="account-title-box">
            <span class="account-name">${accountName}</span>
          </div>
        </div>
        <div class="account-char-list">
          ${chars.map(c => {
            const diaAmount = getCharDiamond(c.id);
            return `
              <div class="char-row-card" onclick="event.stopPropagation(); selectCharacter(${c.id})">
                <div class="char-row-left">
                  <div class="char-meta">
                    <div class="char-name-line">
                      <span class="char-name">${c.name}</span>
                      ${c.device ? `<span class="char-device-badge">${c.device}</span>` : ''}
                    </div>
                    ${c.note ? `<div class="char-note-line">${c.note}</div>` : ''}
                  </div>
                </div>
                <div class="char-row-right">
                  <div class="char-diamond-pill" title="보유 재화 수량">
                    <span class="dia-icon">💎</span>
                    <span class="dia-value">${formatNumber(diaAmount)}</span>
                  </div>
                  <div class="card-actions" onclick="event.stopPropagation()">
                    <button class="icon-btn" title="캐릭터 및 재화 수정" onclick="openEditCharModal(${c.id})">✎</button>
                    <button class="icon-btn delete" title="캐릭터 삭제" onclick="deleteCharacter(${c.id})">🗑</button>
                  </div>
                </div>
              </div>
            `;
          }).join('')}
        </div>
      </div>
    `;
  }).join('');

  // 2) 보유재화 현황: 합계 및 캐릭터별 상세 (계정정보, 점유율/%, 다이아/개 문구 제거)
  const totalServerDiamonds = currentChars.reduce((sum, c) => sum + getCharDiamond(c.id), 0);

  summaryContainer.innerHTML = `
    <div class="diamond-grand-card">
      <div class="grand-header">
        <div class="grand-title-group">
          <div class="grand-title">합계</div>
        </div>
        <div class="grand-amount">${formatNumber(totalServerDiamonds)}</div>
      </div>

      <div class="diamond-breakdown-list">
        <div class="breakdown-header">
          <span>캐릭터별 보유 재화 상세</span>
          <span>수량</span>
        </div>
        ${currentChars.map(c => {
          const dia = getCharDiamond(c.id);
          return `
            <div class="breakdown-row ${c.id === appState.selectedCharId ? 'active' : ''}" onclick="selectCharacter(${c.id})">
              <div class="breakdown-char-info">
                <span class="bd-char-name">${c.name}</span>
              </div>
              <div class="breakdown-amount-info">
                <span class="bd-amount">${formatNumber(dia)}</span>
              </div>
            </div>
          `;
        }).join('')}
      </div>
    </div>
  `;
}

function selectCharacter(charId) {
  appState.selectedCharId = charId;
  saveState();
}

// --- 5. 거래소 수수료 계산기 렌더링 & 실시간 계산 ---
function renderMarketItems() {
  const server = getSelectedServer();
  const feeRateInput = document.getElementById('mcalc-fee-rate');
  const serverBadge = document.getElementById('market-calc-server-badge');

  if (server) {
    if (serverBadge) {
      serverBadge.innerText = `${server.name} 기본 수수료 ${Number(server.feeRate).toFixed(1)}%`;
    }
    // 사용자가 직접 입력한 상태가 아니거나 초기 상태인 경우 서버 수수료율 자동 반영
    if (feeRateInput && (!feeRateInput.dataset.userEdited || feeRateInput.value === '')) {
      feeRateInput.value = Number(server.feeRate).toFixed(1);
    }
  } else {
    if (serverBadge) serverBadge.innerText = '수수료 5.0%';
  }

  recalculateMarketCalculator();
}

function recalculateMarketCalculator() {
  const priceInput = document.getElementById('mcalc-price');
  const qtyInput = document.getElementById('mcalc-qty');
  const feeRateInput = document.getElementById('mcalc-fee-rate');

  if (!priceInput || !qtyInput || !feeRateInput) return;

  const price = Math.max(0, Number(priceInput.value) || 0);
  const qty = Math.max(1, Number(qtyInput.value) || 1);
  const feeRate = Math.max(0, Math.min(100, Number(feeRateInput.value) || 0));

  const gross = price * qty;
  const feeAmount = Math.round(gross * (feeRate / 100.0));
  const netAmount = Math.max(0, gross - feeAmount);

  const grossEl = document.getElementById('mcalc-gross-val');
  const feePercentEl = document.getElementById('mcalc-fee-percent-label');
  const feeValEl = document.getElementById('mcalc-fee-val');
  const netValEl = document.getElementById('mcalc-net-val');

  if (grossEl) grossEl.innerText = `${formatNumber(gross)} 재화`;
  if (feePercentEl) feePercentEl.innerText = `${feeRate.toFixed(1)}%`;
  if (feeValEl) feeValEl.innerText = `-${formatNumber(feeAmount)} 재화`;
  if (netValEl) netValEl.innerText = formatNumber(netAmount);
}

function setMarketFeeRate(rate) {
  const feeRateInput = document.getElementById('mcalc-fee-rate');
  if (feeRateInput) {
    feeRateInput.value = Number(rate).toFixed(1);
    feeRateInput.dataset.userEdited = 'true';
    recalculateMarketCalculator();
  }
}

function syncServerFeeRate() {
  const server = getSelectedServer();
  const feeRateInput = document.getElementById('mcalc-fee-rate');
  if (server && feeRateInput) {
    feeRateInput.value = Number(server.feeRate).toFixed(1);
    feeRateInput.dataset.userEdited = 'true';
    recalculateMarketCalculator();
    showToast(`현재 서버(${server.name}) 수수료 ${Number(server.feeRate).toFixed(1)}%가 적용되었습니다.`);
  }
}

// 계산기 입력 이벤트 바인딩
const mcalcPriceEl = document.getElementById('mcalc-price');
if (mcalcPriceEl) mcalcPriceEl.addEventListener('input', recalculateMarketCalculator);

const mcalcQtyEl = document.getElementById('mcalc-qty');
if (mcalcQtyEl) mcalcQtyEl.addEventListener('input', recalculateMarketCalculator);

const mcalcFeeEl = document.getElementById('mcalc-fee-rate');
if (mcalcFeeEl) {
  mcalcFeeEl.addEventListener('input', () => {
    mcalcFeeEl.dataset.userEdited = 'true';
    recalculateMarketCalculator();
  });
}

function openMarketItemModal() {
  const char = getSelectedCharacter();
  const server = getSelectedServer();
  if (!char || !server) {
    alert('먼저 게임과 캐릭터를 선택해 주세요.');
    return;
  }
  document.getElementById('m-item-name').value = '';
  document.getElementById('m-item-price').value = '';
  document.getElementById('m-item-qty').value = '1';
  document.getElementById('m-item-fee').value = Number(server.feeRate).toFixed(1);
  recalculateMarketModal();
  openModal('modal-market-item');
}

function submitAddMarketItem() {
  const name = document.getElementById('m-item-name').value.trim();
  const price = Number(document.getElementById('m-item-price').value) || 0;
  const qty = Math.max(1, Number(document.getElementById('m-item-qty').value) || 1);
  const feeRate = Number(document.getElementById('m-item-fee').value) || 0;
  const char = getSelectedCharacter();

  if (!name || price <= 0) {
    alert('아이템 이름과 등록 가격을 올바르게 입력해 주세요.');
    return;
  }

  const total = price * qty;
  const fee = Math.round(total * (feeRate / 100.0));
  const net = Math.max(0, total - fee);

  const newItem = {
    id: Date.now(),
    characterId: char.id,
    itemName: name,
    price: price,
    quantity: qty,
    feeRate: feeRate,
    netAmount: net,
    status: '판매중'
  };

  appState.marketItems.unshift(newItem);
  saveState();
  closeModal('modal-market-item');
  showToast(`'${name}' 거래소 등록 완료 (실수령: ${formatNumber(net)} 재화)`);
}

// --- 6. 환전 및 출금 수수료 관리 렌더링 & 실시간 계산 ---
function renderExchangeTab() {
  const char = getSelectedCharacter();
  const server = getSelectedServer();
  const badgeEl = document.getElementById('exchange-char-badge');
  badgeEl.innerText = char ? `${char.name} (${server ? server.name : ''})` : '캐릭터 미선택';

  recalculateExchange();
  renderExchangeHistory();
}

// 핵심 환전 계산 로직
function recalculateExchange() {
  const amount = Number(document.getElementById('ex-amount').value) || 0;
  const rate = Number(document.getElementById('ex-rate').value) || 0;
  const feeRate = Number(document.getElementById('ex-fee-rate').value) || 0;
  const isWithdraw = document.getElementById('ex-withdraw-check').checked;
  const withdrawFee = Number(document.getElementById('ex-withdraw-fee-val').value) || 0;

  // 체크박스 UI 상태 동기화
  const withdrawBox = document.getElementById('withdraw-box');
  const withdrawFeeAmountText = document.getElementById('withdraw-fee-amount-text');
  
  if (isWithdraw) {
    withdrawBox.classList.add('checked');
    withdrawFeeAmountText.innerText = `-${formatNumber(withdrawFee)}원 적용중`;
  } else {
    withdrawBox.classList.remove('checked');
    withdrawFeeAmountText.innerText = '미적용';
  }

  // 금액 계산
  const gross = Math.round(amount * rate);
  const platformFee = Math.round(gross * (feeRate / 100.0));
  const afterPlatform = Math.max(0, gross - platformFee);
  const netFinal = isWithdraw ? Math.max(0, afterPlatform - withdrawFee) : afterPlatform;

  // 영수증 표시
  document.getElementById('rcpt-gross').innerText = `${formatNumber(gross)} 원`;
  document.getElementById('rcpt-fee-rate-label').innerText = `${feeRate.toFixed(1)}%`;
  document.getElementById('rcpt-platform-fee').innerText = `-${formatNumber(platformFee)} 원`;
  
  const withdrawRow = document.getElementById('rcpt-withdraw-fee-row');
  if (isWithdraw) {
    withdrawRow.style.display = 'flex';
    document.getElementById('rcpt-withdraw-fee').innerText = `-${formatNumber(withdrawFee)} 원`;
  } else {
    withdrawRow.style.display = 'none';
  }

  document.getElementById('rcpt-final').innerText = `₩ ${formatNumber(netFinal)}`;
}

// 리스너 연결
document.getElementById('ex-amount').addEventListener('input', recalculateExchange);
document.getElementById('ex-rate').addEventListener('input', recalculateExchange);
document.getElementById('ex-fee-rate').addEventListener('input', recalculateExchange);
document.getElementById('ex-withdraw-check').addEventListener('change', recalculateExchange);
document.getElementById('ex-withdraw-fee-val').addEventListener('input', recalculateExchange);

function saveExchangeRecord() {
  const amount = Number(document.getElementById('ex-amount').value) || 0;
  const rate = Number(document.getElementById('ex-rate').value) || 0;
  const feeRate = Number(document.getElementById('ex-fee-rate').value) || 0;
  const isWithdraw = document.getElementById('ex-withdraw-check').checked;
  const withdrawFee = Number(document.getElementById('ex-withdraw-fee-val').value) || 0;
  const memo = document.getElementById('ex-memo').value.trim();

  if (amount <= 0 || rate <= 0) {
    alert('재화 수량과 단가를 올바르게 입력해 주세요.');
    return;
  }

  const gross = Math.round(amount * rate);
  const platformFee = Math.round(gross * (feeRate / 100.0));
  const afterPlatform = Math.max(0, gross - platformFee);
  const netFinal = isWithdraw ? Math.max(0, afterPlatform - withdrawFee) : afterPlatform;

  const char = getSelectedCharacter();
  const server = getSelectedServer();

  const newRecord = {
    id: Date.now(),
    characterName: char ? char.name : '캐릭터 미지정',
    serverName: server ? server.name : '서버 미지정',
    currencyName: '재화',
    currencyAmount: amount,
    exchangeRate: rate,
    grossAmount: gross,
    feeRate: feeRate,
    feeAmount: platformFee,
    isWithdrawFeeApplied: isWithdraw,
    withdrawFee: withdrawFee,
    netKrwAmount: netFinal,
    memo: memo,
    date: new Date().toISOString().split('T')[0]
  };

  appState.exchangeRecords.unshift(newRecord);
  saveState();
  document.getElementById('ex-memo').value = '';
  showToast(`환전 기록 저장 완료 (실수령: ₩ ${formatNumber(netFinal)})`);
}

function renderExchangeHistory() {
  const listEl = document.getElementById('exchange-history-list');
  const totalTag = document.getElementById('ex-history-total');

  const total = appState.exchangeRecords.reduce((sum, r) => sum + r.netKrwAmount, 0);
  totalTag.innerText = `총 실수령: ₩ ${formatNumber(total)}`;

  if (appState.exchangeRecords.length === 0) {
    listEl.innerHTML = '<div class="text-muted text-center p-4">저장된 환전 내역이 없습니다.</div>';
    return;
  }

  listEl.innerHTML = appState.exchangeRecords.map(r => `
    <div class="history-item-card">
      <div>
        <div class="history-item-title">
          ${formatNumber(r.currencyAmount)} ${r.currencyName} ➔ ₩ ${formatNumber(r.netKrwAmount)}
        </div>
        <div class="history-item-sub">
          [${r.date}] ${r.characterName} (${r.serverName}) | 출금수수료: ${r.isWithdrawFeeApplied ? `적용(-${formatNumber(r.withdrawFee)}원)` : '미적용'}
          ${r.memo ? ` | <span style="color:var(--primary-gold-light);">${r.memo}</span>` : ''}
        </div>
      </div>
      <div class="history-item-right">
        <span class="history-item-amount">₩ ${formatNumber(r.netKrwAmount)}</span>
        <button class="icon-btn delete" onclick="deleteExchangeRecord(${r.id})">🗑</button>
      </div>
    </div>
  `).join('');
}

function deleteExchangeRecord(recordId) {
  if (confirm('이 환전 내역을 삭제하시겠습니까?')) {
    appState.exchangeRecords = appState.exchangeRecords.filter(r => r.id !== recordId);
    saveState();
    showToast('환전 기록이 삭제되었습니다.');
  }
}

// --- 모달 헬퍼 함수들 ---
function openModal(id) {
  document.getElementById(id).classList.add('open');
}

function closeModal(id) {
  document.getElementById(id).classList.remove('open');
}

// 게임 모달
function openAddGameModal() {
  document.getElementById('modal-game-title').innerText = '신규 게임 등록';
  document.getElementById('g-edit-id').value = '';
  document.getElementById('g-name').value = '';
  document.getElementById('g-memo').value = '';
  openModal('modal-game');
}

function openEditGameModal(gameId) {
  const g = appState.games.find(item => item.id === gameId);
  if (!g) return;
  document.getElementById('modal-game-title').innerText = '게임 정보 수정';
  document.getElementById('g-edit-id').value = g.id;
  document.getElementById('g-name').value = g.name;
  document.getElementById('g-memo').value = g.memo || '';
  openModal('modal-game');
}

function submitGameForm() {
  const editId = document.getElementById('g-edit-id').value;
  const name = document.getElementById('g-name').value.trim();
  const memo = document.getElementById('g-memo').value.trim();

  if (!name) return alert('게임 이름을 입력해 주세요.');

  if (editId) {
    const g = appState.games.find(item => item.id === Number(editId));
    if (g) {
      g.name = name;
      g.memo = memo;
    }
  } else {
    const newId = Date.now();
    appState.games.push({ id: newId, name, memo });
    appState.selectedGameId = newId;
  }

  saveState();
  closeModal('modal-game');
  showToast('게임이 저장되었습니다.');
}

function deleteGame(gameId) {
  const g = appState.games.find(item => item.id === gameId);
  if (!g) return;
  if (confirm(`'${g.name}' 게임과 관련된 모든 서버, 캐릭터, 재화 데이터가 함께 삭제됩니다. 계속하시겠습니까?`)) {
    appState.games = appState.games.filter(item => item.id !== gameId);
    // 연관 서버 및 하위 데이터 정리
    const serverIds = appState.servers.filter(s => s.gameId === gameId).map(s => s.id);
    appState.servers = appState.servers.filter(s => s.gameId !== gameId);
    const charIds = appState.characters.filter(c => serverIds.includes(c.serverId)).map(c => c.id);
    appState.characters = appState.characters.filter(c => !serverIds.includes(c.serverId));
    appState.currencies = appState.currencies.filter(cur => !charIds.includes(cur.characterId));
    appState.marketItems = appState.marketItems.filter(m => !charIds.includes(m.characterId));

    if (appState.games.length > 0) {
      selectGame(appState.games[0].id);
    } else {
      appState.selectedGameId = null;
      appState.selectedServerId = null;
      appState.selectedCharId = null;
      saveState();
    }
    showToast('게임이 삭제되었습니다.');
  }
}

// 서버 모달
function openAddServerModal() {
  document.getElementById('modal-server-title').innerText = '서버 추가 및 수수료 설정';
  document.getElementById('s-edit-id').value = '';
  document.getElementById('s-name').value = '';
  document.getElementById('s-fee-rate').value = '5.0';
  document.getElementById('s-memo').value = '';
  openModal('modal-server');
}

function openEditServerModal(serverId) {
  const s = appState.servers.find(item => item.id === serverId);
  if (!s) return;
  document.getElementById('modal-server-title').innerText = '서버 및 수수료 수정';
  document.getElementById('s-edit-id').value = s.id;
  document.getElementById('s-name').value = s.name;
  document.getElementById('s-fee-rate').value = Number(s.feeRate).toFixed(1);
  document.getElementById('s-memo').value = s.memo || '';
  openModal('modal-server');
}

function submitServerForm() {
  const editId = document.getElementById('s-edit-id').value;
  const name = document.getElementById('s-name').value.trim();
  const feeRate = Number(document.getElementById('s-fee-rate').value) || 0;
  const memo = document.getElementById('s-memo').value.trim();

  if (!name) return alert('서버 이름을 입력해 주세요.');

  if (editId) {
    const s = appState.servers.find(item => item.id === Number(editId));
    if (s) {
      s.name = name;
      s.feeRate = feeRate;
      s.memo = memo;
    }
  } else {
    const newId = Date.now();
    appState.servers.push({
      id: newId,
      gameId: appState.selectedGameId,
      name,
      feeRate,
      memo
    });
    appState.selectedServerId = newId;
  }

  saveState();
  closeModal('modal-server');
  showToast('서버 정보가 저장되었습니다.');
}

function deleteServer(serverId) {
  const s = appState.servers.find(item => item.id === serverId);
  if (!s) return;
  if (confirm(`'${s.name}' 서버와 연동된 캐릭터 데이터가 함께 삭제됩니다. 계속하시겠습니까?`)) {
    appState.servers = appState.servers.filter(item => item.id !== serverId);
    const charIds = appState.characters.filter(c => c.serverId === serverId).map(c => c.id);
    appState.characters = appState.characters.filter(c => c.serverId !== serverId);
    appState.currencies = appState.currencies.filter(cur => !charIds.includes(cur.characterId));
    appState.marketItems = appState.marketItems.filter(m => !charIds.includes(m.characterId));

    const remainServers = appState.servers.filter(item => item.gameId === appState.selectedGameId);
    if (remainServers.length > 0) {
      selectServer(remainServers[0].id);
    } else {
      appState.selectedServerId = null;
      appState.selectedCharId = null;
      saveState();
    }
    showToast('서버가 삭제되었습니다.');
  }
}

// 캐릭터 모달
function openAddCharModal() {
  document.getElementById('modal-char-title').innerText = '캐릭터 & 계정 등록';
  document.getElementById('c-edit-id').value = '';
  document.getElementById('c-name').value = '';
  document.getElementById('c-account').value = '';
  document.getElementById('c-device').value = '';
  document.getElementById('c-diamond').value = '0';
  document.getElementById('c-note').value = '';
  openModal('modal-character');
}

function openEditCharModal(charId) {
  const c = appState.characters.find(item => item.id === charId);
  if (!c) return;
  document.getElementById('modal-char-title').innerText = '캐릭터 정보 수정';
  document.getElementById('c-edit-id').value = c.id;
  document.getElementById('c-name').value = c.name;
  document.getElementById('c-account').value = c.accountInfo;
  document.getElementById('c-device').value = c.device || '';
  document.getElementById('c-diamond').value = getCharDiamond(charId);
  document.getElementById('c-note').value = c.note || '';
  openModal('modal-character');
}

function submitCharForm() {
  const editId = document.getElementById('c-edit-id').value;
  const name = document.getElementById('c-name').value.trim();
  const account = document.getElementById('c-account').value.trim();
  const device = document.getElementById('c-device').value.trim();
  const diamond = Math.max(0, Number(document.getElementById('c-diamond').value) || 0);
  const note = document.getElementById('c-note').value.trim();

  if (!name || !account) return alert('캐릭터 이름과 연동 계정 정보를 입력해 주세요.');

  if (editId) {
    const c = appState.characters.find(item => item.id === Number(editId));
    if (c) {
      c.name = name;
      c.accountInfo = account;
      c.device = device;
      c.note = note;
      setCharDiamond(c.id, diamond);
    }
  } else {
    const newId = Date.now();
    appState.characters.push({
      id: newId,
      serverId: appState.selectedServerId,
      name,
      accountInfo: account,
      device,
      note
    });
    setCharDiamond(newId, diamond);
    appState.selectedCharId = newId;
  }

  saveState();
  closeModal('modal-character');
  showToast('캐릭터 정보 및 보유 재화가 저장되었습니다.');
}

function deleteCharacter(charId) {
  const c = appState.characters.find(item => item.id === charId);
  if (!c) return;
  if (confirm(`'${c.name}' 캐릭터와 등록된 재화 및 아이템이 삭제됩니다. 계속하시겠습니까?`)) {
    appState.characters = appState.characters.filter(item => item.id !== charId);
    appState.currencies = appState.currencies.filter(cur => cur.characterId !== charId);
    appState.marketItems = appState.marketItems.filter(m => m.characterId !== charId);

    const remainChars = appState.characters.filter(item => item.serverId === appState.selectedServerId);
    appState.selectedCharId = remainChars.length > 0 ? remainChars[0].id : null;
    saveState();
    showToast('캐릭터가 삭제되었습니다.');
  }
}

// 재화 모달
function openAddCurrencyModal() {
  document.getElementById('cur-edit-id').value = '';
  document.getElementById('cur-name').value = '재화';
  document.getElementById('cur-amount').value = '0';
  openModal('modal-currency');
}

function openEditCurrencyModal(curId) {
  const cur = appState.currencies.find(item => item.id === curId);
  if (!cur) return;
  document.getElementById('cur-edit-id').value = cur.id;
  document.getElementById('cur-name').value = cur.name;
  document.getElementById('cur-amount').value = cur.amount;
  openModal('modal-currency');
}

function submitCurrencyForm() {
  const editId = document.getElementById('cur-edit-id').value;
  const name = document.getElementById('cur-name').value.trim();
  const amount = Number(document.getElementById('cur-amount').value) || 0;
  const char = getSelectedCharacter();

  if (!name) return alert('재화 종류를 입력해 주세요.');

  if (editId) {
    const cur = appState.currencies.find(item => item.id === Number(editId));
    if (cur) {
      cur.name = name;
      cur.amount = amount;
    }
  } else {
    appState.currencies.push({
      id: Date.now(),
      characterId: char.id,
      name,
      amount
    });
  }

  saveState();
  closeModal('modal-currency');
  showToast('재화가 저장되었습니다.');
}

function deleteCurrency(curId) {
  if (confirm('이 재화를 삭제하시겠습니까?')) {
    appState.currencies = appState.currencies.filter(c => c.id !== curId);
    saveState();
    showToast('재화가 삭제되었습니다.');
  }
}

// =========================================================
// 8. 인증(로그인 / 회원가입) 및 관리자(Admin) 콘솔 로직
// =========================================================

let currentAuthMode = 'login'; // 'login' | 'register'

function renderAuthArea() {
  const userArea = document.getElementById('app-bar-user-area');
  if (!userArea) return;

  const user = appState.currentUser;
  if (user) {
    const isAdmin = user.role === 'admin';
    userArea.innerHTML = `
      <div class="user-profile-badge">
        <span class="user-avatar-tag ${isAdmin ? 'admin-tag' : ''}">${isAdmin ? '👑' : '👤'}</span>
        <span class="user-name-text">${user.nickname || user.username}</span>
        ${isAdmin ? `<button class="btn-admin-pill" onclick="switchTab('tab-admin')">⚙️ 관리자</button>` : ''}
        <button class="btn-logout-tiny" title="로그아웃" onclick="handleLogout()">로그아웃</button>
      </div>
    `;
  } else {
    userArea.innerHTML = `
      <div class="auth-btn-group">
        <button class="btn btn-xs btn-outline" onclick="openAuthModal('login')">로그인</button>
        <button class="btn btn-xs btn-primary" onclick="openAuthModal('register')">회원가입</button>
      </div>
    `;
  }
}

function openAuthModal(mode = 'login') {
  switchAuthMode(mode);
  openModal('modal-auth');
}

function switchAuthMode(mode) {
  currentAuthMode = mode;
  const isLogin = mode === 'login';

  document.getElementById('auth-modal-title').innerText = isLogin ? '로그인' : '회원가입';
  document.getElementById('auth-submit-btn').innerText = isLogin ? '로그인' : '회원가입 완료';

  const loginTab = document.getElementById('auth-tab-login');
  const regTab = document.getElementById('auth-tab-register');
  if (loginTab && regTab) {
    if (isLogin) {
      loginTab.classList.add('active');
      regTab.classList.remove('active');
    } else {
      regTab.classList.add('active');
      loginTab.classList.remove('active');
    }
  }

  const nickGroup = document.getElementById('auth-nickname-group');
  const pwConfirmGroup = document.getElementById('auth-password-confirm-group');
  const quickHint = document.getElementById('auth-quick-hint');

  if (nickGroup) nickGroup.style.display = isLogin ? 'none' : 'block';
  if (pwConfirmGroup) pwConfirmGroup.style.display = isLogin ? 'none' : 'block';
  if (quickHint) quickHint.style.display = isLogin ? 'block' : 'none';

  document.getElementById('auth-password').value = '';
  const pwConfirmInput = document.getElementById('auth-password-confirm');
  if (pwConfirmInput) pwConfirmInput.value = '';
}

function handleAuthSubmit(e) {
  e.preventDefault();
  const username = document.getElementById('auth-username').value.trim();
  const password = document.getElementById('auth-password').value;

  if (!username || !password) {
    alert('아이디와 비밀번호를 모두 입력해 주세요.');
    return;
  }

  if (currentAuthMode === 'login') {
    const user = appState.users.find(u => u.username === username && u.password === password);
    if (!user) {
      alert('아이디 또는 비밀번호가 일치하지 않습니다.');
      return;
    }

    appState.currentUser = {
      id: user.id,
      username: user.username,
      nickname: user.nickname,
      role: user.role
    };
    saveState();
    closeModal('modal-auth');
    showToast(`${user.nickname || user.username}님, 환영합니다!`);
    loadUserDataFromCloud(user.id);
  } else {
    // 회원가입
    const nickname = document.getElementById('auth-nickname').value.trim() || username;
    const confirmPw = document.getElementById('auth-password-confirm').value;

    if (password !== confirmPw) {
      alert('비밀번호가 일치하지 않습니다.');
      return;
    }

    const exists = appState.users.some(u => u.username === username);
    if (exists) {
      alert('이미 사용 중인 아이디입니다.');
      return;
    }

    const newUser = {
      id: Date.now(),
      username,
      password,
      nickname,
      role: 'user',
      createdAt: new Date().toISOString().split('T')[0]
    };

    appState.users.push(newUser);
    appState.currentUser = {
      id: newUser.id,
      username: newUser.username,
      nickname: newUser.nickname,
      role: newUser.role
    };

    saveState();
    closeModal('modal-auth');
    showToast(`회원가입이 완료되었습니다! (${nickname}님)`);
  }
}

// 구글 원클릭 로그인 연동
async function handleGoogleSignIn() {
  if (!isFirebaseReady || !fbAuth) {
    alert('Firebase 서비스가 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.');
    return;
  }
  const provider = new firebase.auth.GoogleAuthProvider();
  try {
    const result = await fbAuth.signInWithPopup(provider);
    const user = result.user;
    if (user) {
      const googleUser = {
        id: user.uid,
        username: user.email || user.displayName || 'google_user',
        nickname: user.displayName || '구글사용자',
        role: user.email === 'jaredesign0621@gmail.com' ? 'admin' : 'user'
      };

      // 로컬 users에 없으면 추가
      if (!appState.users.some(u => u.id === googleUser.id)) {
        appState.users.push({
          ...googleUser,
          createdAt: new Date().toISOString().split('T')[0]
        });
      }

      appState.currentUser = googleUser;
      saveState();
      closeModal('modal-auth');
      showToast(`Google 로그인 완료: ${googleUser.nickname}님 환영합니다!`);
      await loadUserDataFromCloud(googleUser.id);
    }
  } catch (err) {
    console.error('Google Sign-In Error:', err);
    if (err.code === 'auth/popup-closed-by-user') return;
    alert(`Google 로그인 실패: ${err.message}`);
  }
}

function handleLogout() {
  if (confirm('로그아웃 하시겠습니까?')) {
    if (cloudUnsubscribe) {
      cloudUnsubscribe();
      cloudUnsubscribe = null;
    }
    if (isFirebaseReady && fbAuth && fbAuth.currentUser) {
      fbAuth.signOut().catch(() => {});
    }
    appState.currentUser = null;
    saveState();
    showToast('로그아웃 되었습니다.');
    // 관리자 탭에 머물러 있었다면 대시보드로 복귀
    const adminPane = document.getElementById('tab-admin');
    if (adminPane && adminPane.classList.contains('active')) {
      switchTab('tab-dashboard');
    }
  }
}

// --- 관리자 콘솔 렌더링 ---
function renderAdminDashboard() {
  const adminPane = document.getElementById('tab-admin');
  if (!adminPane) return;

  // 관리자 통계 카드
  const userCountEl = document.getElementById('admin-user-count');
  const charCountEl = document.getElementById('admin-char-count');
  const serverCountEl = document.getElementById('admin-server-count');
  const currencySumEl = document.getElementById('admin-currency-sum');

  if (userCountEl) userCountEl.innerText = `${(appState.users || []).length}명`;
  if (charCountEl) charCountEl.innerText = `${appState.characters.length}개`;
  if (serverCountEl) serverCountEl.innerText = `${appState.games.length}게임 / ${appState.servers.length}서버`;

  const totalCurrency = appState.currencies.reduce((sum, c) => sum + (Number(c.amount) || 0), 0);
  if (currencySumEl) currencySumEl.innerText = formatNumber(totalCurrency);

  // 회원 테이블 렌더링
  const userTableContainer = document.getElementById('admin-user-table-container');
  if (userTableContainer) {
    if (!appState.users || appState.users.length === 0) {
      userTableContainer.innerHTML = '<div class="text-muted text-center p-3">등록된 회원이 없습니다.</div>';
    } else {
      userTableContainer.innerHTML = `
        <table class="admin-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>아이디</th>
              <th>닉네임</th>
              <th>권한</th>
              <th>가입일</th>
              <th>관리</th>
            </tr>
          </thead>
          <tbody>
            ${appState.users.map(u => {
              const isCurrent = appState.currentUser && appState.currentUser.id === u.id;
              const isAdmin = u.role === 'admin';
              return `
                <tr>
                  <td>${u.id}</td>
                  <td><strong>${u.username}</strong> ${isCurrent ? '<span class="self-tag">(나)</span>' : ''}</td>
                  <td>${u.nickname || '-'}</td>
                  <td><span class="role-pill ${isAdmin ? 'admin' : 'user'}">${isAdmin ? '관리자' : '일반'}</span></td>
                  <td>${u.createdAt || '-'}</td>
                  <td>
                    <div class="action-btn-row">
                      <button class="btn btn-xs btn-outline" onclick="openEditUserModal(${u.id})">수정</button>
                      ${!isCurrent ? `<button class="btn btn-xs danger-btn" onclick="deleteUserByAdmin(${u.id})">삭제</button>` : ''}
                    </div>
                  </td>
                </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      `;
    }
  }

  // 서버 수수료 마스터 테이블 렌더링
  const serverListContainer = document.getElementById('admin-server-list-container');
  if (serverListContainer) {
    serverListContainer.innerHTML = `
      <table class="admin-table">
        <thead>
          <tr>
            <th>소속 게임</th>
            <th>서버명</th>
            <th>거래소 수수료율</th>
            <th>즉시 변경</th>
          </tr>
        </thead>
        <tbody>
          ${appState.servers.map(s => {
            const game = appState.games.find(g => g.id === s.gameId);
            return `
              <tr>
                <td>${game ? game.name : '-'}</td>
                <td><strong>${s.name}</strong></td>
                <td>
                  <div class="input-inline-wrap">
                    <input type="number" id="adm-fee-${s.id}" value="${Number(s.feeRate).toFixed(1)}" step="0.1" min="0" max="100" class="mini-inline-input">
                    <span>%</span>
                  </div>
                </td>
                <td>
                  <button class="btn btn-xs btn-primary" onclick="updateServerFeeByAdmin(${s.id})">저장</button>
                </td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    `;
  }
}

// 관리자: 회원 추가/수정
function openAddUserModal() {
  document.getElementById('modal-admin-user-title').innerText = '신규 회원 계정 등록';
  document.getElementById('adm-user-id').value = '';
  document.getElementById('adm-user-username').value = '';
  document.getElementById('adm-user-nickname').value = '';
  document.getElementById('adm-user-password').value = '';
  document.getElementById('adm-user-role').value = 'user';
  openModal('modal-admin-user');
}

function openEditUserModal(userId) {
  const user = appState.users.find(u => u.id === userId);
  if (!user) return;
  document.getElementById('modal-admin-user-title').innerText = '회원 정보 수정';
  document.getElementById('adm-user-id').value = user.id;
  document.getElementById('adm-user-username').value = user.username;
  document.getElementById('adm-user-nickname').value = user.nickname || '';
  document.getElementById('adm-user-password').value = user.password;
  document.getElementById('adm-user-role').value = user.role;
  openModal('modal-admin-user');
}

function submitAdminUserForm() {
  const editId = document.getElementById('adm-user-id').value;
  const username = document.getElementById('adm-user-username').value.trim();
  const nickname = document.getElementById('adm-user-nickname').value.trim() || username;
  const password = document.getElementById('adm-user-password').value;
  const role = document.getElementById('adm-user-role').value;

  if (!username || !password) {
    alert('아이디와 비밀번호를 입력해 주세요.');
    return;
  }

  if (editId) {
    const user = appState.users.find(u => u.id === Number(editId));
    if (user) {
      user.username = username;
      user.nickname = nickname;
      user.password = password;
      user.role = role;
      if (appState.currentUser && appState.currentUser.id === user.id) {
        appState.currentUser.username = username;
        appState.currentUser.nickname = nickname;
        appState.currentUser.role = role;
      }
    }
  } else {
    const exists = appState.users.some(u => u.username === username);
    if (exists) {
      alert('이미 존재하는 아이디입니다.');
      return;
    }
    appState.users.push({
      id: Date.now(),
      username,
      nickname,
      password,
      role,
      createdAt: new Date().toISOString().split('T')[0]
    });
  }

  saveState();
  closeModal('modal-admin-user');
  showToast('회원 정보가 저장되었습니다.');
}

function deleteUserByAdmin(userId) {
  if (confirm('이 회원 계정을 영구 삭제하시겠습니까?')) {
    appState.users = appState.users.filter(u => u.id !== userId);
    saveState();
    showToast('회원 계정이 삭제되었습니다.');
  }
}

function updateServerFeeByAdmin(serverId) {
  const input = document.getElementById(`adm-fee-${serverId}`);
  if (!input) return;
  const newFee = Math.max(0, Math.min(100, Number(input.value) || 0));
  const server = appState.servers.find(s => s.id === serverId);
  if (server) {
    server.feeRate = newFee;
    saveState();
    showToast(`'${server.name}' 기본 수수료가 ${newFee.toFixed(1)}%로 변경되었습니다.`);
  }
}

// JSON 백업 다운로드
function exportAppDataJson() {
  const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(appState, null, 2));
  const downloadAnchor = document.createElement('a');
  downloadAnchor.setAttribute("href", dataStr);
  const nowStr = new Date().toISOString().replace(/[:.]/g, '-');
  downloadAnchor.setAttribute("download", `SSAL_BACKUP_${nowStr}.json`);
  document.body.appendChild(downloadAnchor);
  downloadAnchor.click();
  downloadAnchor.remove();
  showToast('전체 데이터 백업 파일이 다운로드되었습니다.');
}

// JSON 백업 복원
function importAppDataJson(event) {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = function(e) {
    try {
      const parsed = JSON.parse(e.target.result);
      if (!parsed.games || !parsed.servers || !parsed.characters) {
        throw new Error('유효한 SSAL 백업 파일 형식이 아닙니다.');
      }
      if (confirm('백업 파일로 복원하시겠습니까? 현재 데이터가 덮어씌워집니다.')) {
        appState = parsed;
        saveState();
        showToast('시스템 데이터가 성공적으로 복원되었습니다.');
      }
    } catch (err) {
      alert(`복원 실패: ${err.message}`);
    }
  };
  reader.readAsText(file);
}

// --- 초기화 실행 ---
renderAll();
if (!appState.currentUser) {
  setTimeout(() => {
    openAuthModal('login');
  }, 300);
}
console.log('🌾 SSAL App Ready.');
