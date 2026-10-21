// =========================================================================
// UniMeet Client Application State & Handlers
// =========================================================================

const API_BASE = 'http://localhost:3000/api/v1';

const AppState = {
  currentScreen: 1,
  screenHistory: [1],
  selectedCampus: 'BINUS Anggrek Campus',
  selectedDomain: '@binus.ac.id',
  activeCategory: 'all',
  hostCapacity: 6,
  selectedHostCat: 'SPORTS',
  pollVotes: [3, 1], // [Opt0, Opt1]
  hasVotedPoll: false,

  currentUser: {
    name: 'Marcelinus Wijaya Oey',
    nim: '2602194831',
    email: 'marcelinus.wijaya@binus.ac.id',
    major: "Computer Science '24",
    campus: 'BINUS Anggrek Campus',
    avatar: 'MW',
    reputation: 4.95,
  },

  meetups: [
    {
      id: 'meet-1',
      title: 'Badminton Double Sparring 🏸',
      category: 'SPORTS',
      categoryLabel: 'Sports & Recreation',
      host: {
        name: 'Kevin Wijaya',
        major: "CS '24",
        reputation: 4.9,
        meetupsHosted: 18,
        avatar: 'KW',
      },
      time: 'Today, 18:30 WIB',
      timeDuration: 'Today, Oct 24 · 18:30 - 20:30 WIB',
      location: 'Sport Hall Lt. 3 (Court 2)',
      campus: 'BINUS Anggrek Campus',
      cost: 'Rp 25.000 / person',
      slotsLeft: 2,
      maxSlots: 8,
      currentSlots: 6,
      isJoined: false,
      image: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=800&q=80',
      description: 'Looking for intermediate players to play mixed doubles! Bring your own racket, shuttles provided. Great way to de-stress before midterm exams and meet fellow sports enthusiasts!',
      tags: ['#Badminton', '#Sparring', '#Intermediate'],
      roster: [
        { name: 'Kevin W.', role: 'Host', major: 'CS' },
        { name: 'Sarah M.', role: 'Joined', major: "DS '23" },
        { name: 'Rizky A.', role: 'Joined', major: "IS '22" },
        { name: 'Nadine T.', role: 'Joined', major: "DKV '24" },
        { name: 'Aris C.', role: 'Joined', major: "Buss '23" },
        { name: 'Michelle K.', role: 'Joined', major: "CS '24" },
      ],
    },
    {
      id: 'meet-2',
      title: 'Calculus II Practice & Chill 📚',
      category: 'ACADEMIC',
      categoryLabel: 'Study & Academic',
      host: {
        name: 'Michelle Hartono',
        major: "IS '25",
        reputation: 4.95,
        meetupsHosted: 8,
        avatar: 'MH',
      },
      time: 'Tomorrow, 14:00 WIB',
      timeDuration: 'Tomorrow · 14:00 - 16:30 WIB',
      location: 'Central Library Study Room 4B',
      campus: 'BINUS Anggrek Campus',
      cost: 'Free (Fore Coffee Sponsored)',
      slotsLeft: 1,
      maxSlots: 5,
      currentSlots: 4,
      isJoined: false,
      image: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=800&q=80',
      description: 'Review bedah soal Kalkulus II persiapan UAS bareng peer mentor. Disediakan kopi Fore gratis dari host!',
      tags: ['#Calculus', '#StudyGroup', '#FreeForeCoffee'],
      roster: [
        { name: 'Michelle H.', role: 'Host', major: "IS '25" },
        { name: 'Rian N.', role: 'Joined', major: "CS '24" },
        { name: 'Budi K.', role: 'Joined', major: "CS '25" },
        { name: 'Clara L.', role: 'Joined', major: "Design '24" },
      ],
    },
    {
      id: 'meet-3',
      title: 'Valorant 5v5 Custom & Boba 🎮',
      category: 'GAMING',
      categoryLabel: 'Gaming & Esports',
      host: {
        name: 'Aris Thorne',
        major: "Game Dev '23",
        reputation: 4.8,
        meetupsHosted: 12,
        avatar: 'AT',
      },
      time: 'Friday, 20:00 WIB',
      timeDuration: 'Friday Night · 20:00 - 23:00 WIB',
      location: 'Discord Voice & Syahdan Net Cafe',
      campus: 'BINUS Syahdan Campus',
      cost: 'Gratis / Bayar Minum Sendiri',
      slotsLeft: 3,
      maxSlots: 10,
      currentSlots: 7,
      isJoined: false,
      image: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=800&q=80',
      description: 'Custom match santai 5v5 antar mahasiswa Binus. Rank Gold sampai Diamond welcome, no toxicity!',
      tags: ['#Valorant', '#GoldToDiamond', '#BobaSyahdan'],
      roster: [
        { name: 'Aris T.', role: 'Host', major: 'Game Dev' },
        { name: 'Vito G.', role: 'Joined', major: 'Cyber' },
        { name: 'Kevin P.', role: 'Joined', major: 'CS' },
      ],
    },
    {
      id: 'meet-4',
      title: 'Freshman Intro Walk & Campus Tour 🌿',
      category: 'OUTDOOR',
      categoryLabel: 'Campus Community',
      host: {
        name: 'Sarah Oktavia',
        major: 'Ambassador',
        reputation: 4.9,
        meetupsHosted: 24,
        avatar: 'SO',
      },
      time: 'Saturday, 10:00 WIB',
      timeDuration: 'Saturday Morning · 10:00 - 12:30 WIB',
      location: 'Main Fountain Plaza (Near Gate 1)',
      campus: 'BINUS Anggrek Campus',
      cost: 'Free Gelato Included',
      slotsLeft: 6,
      maxSlots: 20,
      currentSlots: 14,
      isJoined: false,
      image: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=800&q=80',
      description: 'New to BINUS Anggrek? Lets explore secret study spots, best canteen food stalls, and finish with complimentary gelato!',
      tags: ['#FreshmanGuide', '#GelatoWalk', '#Binusian2028'],
      roster: [
        { name: 'Sarah O.', role: 'Host', major: 'Ambassador' },
        { name: 'Teguh L.', role: 'Joined', major: 'CS' },
      ],
    },
  ],
};

// =========================================================================
// Navigation & Screen Switcher
// =========================================================================

function navigateTo(screenNum) {
  if (AppState.currentScreen !== screenNum) {
    AppState.screenHistory.push(screenNum);
  }
  AppState.currentScreen = screenNum;

  // Toggle active screen view
  document.querySelectorAll('.screen-view').forEach((sec) => {
    sec.classList.remove('active');
  });
  const target = document.getElementById(`screen-${screenNum}`);
  if (target) {
    target.classList.add('active');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // Update desktop jump bar buttons
  for (let i = 1; i <= 6; i++) {
    const btn = document.getElementById(`jump-${i}`);
    if (btn) {
      if (i === screenNum) {
        btn.className = 'px-2.5 py-1.5 rounded-xl font-bold text-white bg-primary transition-all whitespace-nowrap shadow-md';
      } else {
        btn.className = 'px-2.5 py-1.5 rounded-xl font-bold text-slate-300 hover:text-white transition-all whitespace-nowrap';
      }
    }
  }

  // Show/Hide Global Header and Bottom Nav
  const globalHeader = document.getElementById('global-header');
  const globalNav = document.getElementById('global-bottom-nav');
  const headerBackBtn = document.getElementById('header-back-btn');
  const headerTitle = document.getElementById('header-title');

  if (screenNum === 1) {
    globalHeader.classList.add('hidden');
    globalNav.classList.add('hidden');
  } else {
    globalHeader.classList.remove('hidden');
    globalNav.classList.remove('hidden');

    if (screenNum === 3 || screenNum === 4) {
      headerBackBtn?.classList.remove('hidden');
      headerTitle.textContent = screenNum === 3 ? 'Meetup Details' : 'Host Meetup';
    } else {
      headerBackBtn?.classList.add('hidden');
      headerTitle.textContent = 'UniMeet';
    }
  }

  // Update bottom navigation bar active button
  const navFeed = document.getElementById('nav-btn-feed');
  const navDetail = document.getElementById('nav-btn-detail');
  const navChat = document.getElementById('nav-btn-chat');
  const navProfile = document.getElementById('nav-btn-profile');

  [navFeed, navDetail, navChat, navProfile].forEach((btn) => {
    if (btn) {
      btn.classList.remove('text-primary');
      btn.classList.add('text-on-surface-variant');
    }
  });

  if (screenNum === 2 && navFeed) navFeed.className = 'flex flex-col items-center justify-center gap-0.5 w-14 h-12 text-primary font-bold transition-colors';
  if (screenNum === 3 && navDetail) navDetail.className = 'flex flex-col items-center justify-center gap-0.5 w-14 h-12 text-primary font-bold transition-colors';
  if (screenNum === 5 && navChat) navChat.className = 'relative flex flex-col items-center justify-center gap-0.5 w-14 h-12 text-primary font-bold transition-colors';
  if (screenNum === 6 && navProfile) navProfile.className = 'flex flex-col items-center justify-center gap-0.5 w-14 h-12 text-primary font-bold transition-colors';

  if (screenNum === 2) {
    renderFeed();
  }
}

function navigateBack() {
  if (AppState.screenHistory.length > 1) {
    AppState.screenHistory.pop(); // Current
    const prev = AppState.screenHistory.pop(); // Previous
    navigateTo(prev || 2);
  } else {
    navigateTo(2);
  }
}

// =========================================================================
// Screen 1: Verification Gate
// =========================================================================

function selectDomain(domain, campusName, btnElement) {
  AppState.selectedDomain = domain;
  document.getElementById('active-domain-suffix').textContent = domain;
  document.getElementById('campus-name-hint').innerHTML =
    'Preset set to <span class="font-bold text-on-surface">' + campusName + '</span>';

  document.querySelectorAll('.domain-chip').forEach((el) => {
    el.className =
      'domain-chip flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-surface-container text-on-surface-variant text-[11px] font-bold shrink-0 transition-all';
  });
  btnElement.className =
    'domain-chip active flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-on-surface text-white text-[11px] font-bold shrink-0 shadow-sm transition-all';
}

function handleAuthSubmit() {
  const prefix = document.getElementById('campus-email-prefix').value.trim();
  const nim = document.getElementById('student-nim-input').value.trim();
  const btn = document.getElementById('send-code-btn');
  const toast = document.getElementById('code-status-toast');

  if (!prefix) {
    showToast('Masukkan prefix email kampus Anda', '⚠️');
    return;
  }

  btn.innerHTML =
    '<span class="material-symbols-outlined text-base animate-spin">progress_activity</span><span>Verifying BINUS ID...</span>';

  setTimeout(() => {
    btn.innerHTML =
      '<span class="material-symbols-outlined text-base">check_circle</span><span>Email Verified ✓</span>';
    btn.className =
      'w-full mt-1 flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-status-open-emerald text-white font-bold text-xs shadow-md transition-all';

    toast.classList.remove('hidden');
    toast.classList.add('flex');

    showToast('Login berhasil! Selamat datang di UniMeet 🚀', '✓');

    setTimeout(() => {
      navigateTo(2);
    }, 700);
  }, 600);
}

function handleSsoSubmit() {
  showToast('Menghubungkan ke Portal Binusmaya SSO...', '🔐');
  setTimeout(() => {
    showToast('SSO Verified! Selamat datang Marcelinus', '🎓');
    navigateTo(2);
  }, 600);
}

// =========================================================================
// Screen 2: Feed & Activity Cards
// =========================================================================

function renderFeed() {
  const container = document.getElementById('feed-container');
  if (!container) return;

  const category = AppState.activeCategory;
  const filtered = AppState.meetups.filter((item) => {
    if (category === 'all') return true;
    return item.category.toUpperCase() === category.toUpperCase();
  });

  container.innerHTML = filtered
    .map((item) => {
      return `
      <article class="bg-surface-card rounded-2xl p-3.5 shadow-sm border border-surface-border flex flex-col gap-3 transition-all hover:shadow-md cursor-pointer" onclick="openMeetupDetail('${item.id}')">
        <!-- Host Header -->
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <div class="relative">
              <div class="w-10 h-10 rounded-full bg-primary text-white font-black text-xs flex items-center justify-center shadow-sm">
                ${item.host.avatar}
              </div>
              <span class="absolute -bottom-1 -right-1 bg-campus-blue text-white rounded-full p-0.5 flex items-center justify-center text-[10px]">
                ✓
              </span>
            </div>
            <div class="flex flex-col">
              <div class="flex items-center gap-1.5">
                <span class="font-bold text-xs text-on-surface">${item.host.name}</span>
                <span class="px-1.5 py-0.2 rounded bg-surface-container-high text-campus-blue text-[9px] font-bold">${item.host.major}</span>
              </div>
              <span class="text-[10px] text-outline font-medium">Verified Host · ${item.host.reputation} ★</span>
            </div>
          </div>
          <button onclick="event.stopPropagation(); showToast('Tersimpan di bookmark', '📌')" class="w-8 h-8 rounded-full flex items-center justify-center text-outline hover:text-primary transition-colors">
            <span class="material-symbols-outlined text-[18px]">bookmark_border</span>
          </button>
        </div>

        <!-- Content Details -->
        <div class="flex flex-col gap-1">
          <div class="flex items-center justify-between">
            <h3 class="font-black text-xs text-on-surface flex items-center gap-1">
              ${item.title}
            </h3>
            <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-status-trending-soft text-status-trending-coral text-[10px] font-bold">
              <span class="w-1.5 h-1.5 rounded-full bg-status-trending-coral animate-ping"></span>
              ${item.slotsLeft} slots left!
            </span>
          </div>

          <div class="flex flex-wrap items-center gap-y-1 gap-x-2 text-on-surface-variant text-[11px] font-medium mt-0.5">
            <div class="flex items-center gap-1">
              <span class="material-symbols-outlined text-[14px] text-primary">schedule</span>
              <span>${item.time}</span>
            </div>
            <div class="flex items-center gap-1">
              <span class="material-symbols-outlined text-[14px] text-campus-orange">location_on</span>
              <span class="truncate max-w-[170px]">${item.location}</span>
            </div>
          </div>

          <div class="flex items-center gap-1 mt-1">
            ${item.tags.map((t) => `<span class="px-2 py-0.5 rounded bg-surface-container-low text-on-secondary-fixed text-[10px] font-bold">${t}</span>`).join('')}
          </div>
        </div>

        <!-- Cover Image with Gradient -->
        <div class="relative w-full h-32 rounded-xl overflow-hidden shadow-inner bg-slate-900">
          <img class="w-full h-full object-cover opacity-90" src="${item.image}" alt="${item.title}"/>
          <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent"></div>
          <div class="absolute bottom-2 left-2.5 right-2.5 flex items-center justify-between text-white text-[10px] font-bold">
            <span class="bg-black/50 backdrop-blur-md px-2 py-0.5 rounded">Rackets & shuttles ready</span>
            <span class="bg-primary/80 backdrop-blur-md px-2 py-0.5 rounded">${item.cost}</span>
          </div>
        </div>

        <!-- Roster & Join Action -->
        <div class="flex items-center justify-between pt-1">
          <div class="flex items-center gap-1.5">
            <div class="flex -space-x-1.5 overflow-hidden">
              <div class="w-6 h-6 rounded-full bg-blue-600 text-white font-bold text-[9px] flex items-center justify-center ring-1 ring-white">KW</div>
              <div class="w-6 h-6 rounded-full bg-emerald-600 text-white font-bold text-[9px] flex items-center justify-center ring-1 ring-white">SM</div>
              <div class="w-6 h-6 rounded-full bg-purple-600 text-white font-bold text-[9px] flex items-center justify-center ring-1 ring-white">RA</div>
            </div>
            <span class="text-[10px] font-semibold text-on-surface-variant">${item.currentSlots}/${item.maxSlots} confirmed</span>
          </div>

          <button onclick="event.stopPropagation(); toggleQuickJoin('${item.id}', this)" class="px-3.5 py-1.5 rounded-xl ${item.isJoined ? 'bg-status-open-light text-status-open-emerald' : 'bg-primary-container text-white'} font-bold text-xs shadow-sm hover:bg-primary active:scale-95 transition-all flex items-center gap-1">
            <span>${item.isJoined ? 'Joined! ✓' : 'Quick Join'}</span>
            <span class="material-symbols-outlined text-[14px]">${item.isJoined ? 'check' : 'arrow_forward'}</span>
          </button>
        </div>
      </article>
      `;
    })
    .join('');
}

function filterCategory(cat, btn) {
  AppState.activeCategory = cat;
  document.querySelectorAll('#category-pills .cat-pill').forEach((pill) => {
    pill.className =
      'cat-pill flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-surface-card text-on-surface font-bold text-xs shadow-sm border border-surface-border hover:bg-surface-container-low transition-all';
  });
  btn.className =
    'cat-pill active flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-on-secondary-fixed text-white font-bold text-xs shadow-sm transition-all';
  renderFeed();
}

function handleSearch(query) {
  const q = query.toLowerCase().trim();
  const filtered = AppState.meetups.filter(
    (m) =>
      m.title.toLowerCase().includes(q) ||
      m.location.toLowerCase().includes(q) ||
      m.description.toLowerCase().includes(q),
  );

  const container = document.getElementById('feed-container');
  if (container && q.length > 0) {
    if (filtered.length === 0) {
      container.innerHTML = `
        <div class="p-8 text-center text-on-surface-variant text-xs">
          <span class="text-3xl block mb-2">🔍</span>
          Tidak ditemukan aktivitas dengan kata kunci "<strong>${query}</strong>"
        </div>`;
      return;
    }
  }
  renderFeed();
}

function toggleQuickJoin(meetupId, btn) {
  const meetup = AppState.meetups.find((m) => m.id === meetupId);
  if (!meetup) return;

  meetup.isJoined = !meetup.isJoined;
  if (meetup.isJoined) {
    meetup.currentSlots += 1;
    meetup.slotsLeft -= 1;
    btn.className =
      'px-3.5 py-1.5 rounded-xl bg-status-open-light text-status-open-emerald font-bold text-xs shadow-sm flex items-center gap-1';
    btn.innerHTML = '<span>Joined! ✓</span><span class="material-symbols-outlined text-[14px]">check</span>';
    showToast(`Berhasil join ${meetup.title}! Passcode: #4402`, '🎟️');
  } else {
    meetup.currentSlots -= 1;
    meetup.slotsLeft += 1;
    btn.className =
      'px-3.5 py-1.5 rounded-xl bg-primary-container text-white font-bold text-xs shadow-sm hover:bg-primary active:scale-95 transition-all flex items-center gap-1';
    btn.innerHTML = '<span>Quick Join</span><span class="material-symbols-outlined text-[14px]">arrow_forward</span>';
    showToast('Keluar dari squad meetup', '👋');
  }
}

// =========================================================================
// Screen 3: Meetup Details
// =========================================================================

function openMeetupDetail(meetupId) {
  const meetup = AppState.meetups.find((m) => m.id === meetupId) || AppState.meetups[0];
  
  document.getElementById('detail-title').textContent = meetup.title;
  document.getElementById('detail-cover-img').src = meetup.image;
  document.getElementById('detail-host-name').textContent = meetup.host.name;
  document.getElementById('detail-host-major').textContent = meetup.host.major;
  document.getElementById('detail-host-avatar').textContent = meetup.host.avatar;
  document.getElementById('detail-time-text').textContent = meetup.timeDuration || meetup.time;
  document.getElementById('detail-location-text').textContent = meetup.location;
  document.getElementById('detail-campus-text').textContent = meetup.campus;
  document.getElementById('detail-cost-text').textContent = meetup.cost.split('/')[0].trim();
  document.getElementById('detail-bar-cost').textContent = meetup.cost.split('/')[0].trim();
  document.getElementById('detail-description').textContent = meetup.description;
  document.getElementById('detail-roster-count').textContent = `${meetup.currentSlots} / ${meetup.maxSlots} Spots Taken`;
  
  const pct = Math.round((meetup.currentSlots / meetup.maxSlots) * 100);
  document.getElementById('detail-progress-bar').style.width = `${pct}%`;

  // Render roster chips
  const rosterContainer = document.getElementById('detail-roster-container');
  rosterContainer.innerHTML = meetup.roster
    .map(
      (p) => `
      <div class="flex items-center gap-1 px-2.5 py-1 rounded-full bg-surface-container-low text-on-surface text-[11px] font-bold">
        <span>${p.name}</span>
        <span class="text-[9px] text-on-surface-variant font-medium">(${p.major})</span>
      </div>`,
    )
    .join('') + `
      <div class="flex items-center gap-1 px-2.5 py-1 rounded-full bg-surface-container-highest text-primary text-[11px] font-bold">
        <span class="material-symbols-outlined text-[13px]">person_add</span>
        <span>Open Spot</span>
      </div>`;

  navigateTo(3);
}

function handleDetailRsvp() {
  const modal = document.getElementById('rsvp-modal');
  modal.classList.remove('hidden');
  setTimeout(() => {
    modal.classList.remove('opacity-0');
  }, 20);

  const btn = document.getElementById('detail-rsvp-action-btn');
  const label = document.getElementById('detail-rsvp-btn-label');
  btn.className =
    'flex-1 max-w-[210px] py-2.5 px-4 rounded-xl bg-status-open-light text-status-open-emerald font-bold text-xs shadow-md transition-all flex flex-col items-center justify-center text-center';
  label.textContent = 'Spot Confirmed ✓';
}

function closeRsvpModal() {
  const modal = document.getElementById('rsvp-modal');
  modal.classList.add('opacity-0');
  setTimeout(() => {
    modal.classList.add('hidden');
  }, 300);
}

// =========================================================================
// Screen 4: Host Meetup
// =========================================================================

function selectHostCat(cat, btn) {
  AppState.selectedHostCat = cat;
  document.querySelectorAll('#hostCategoryGroup .host-cat-pill').forEach((pill) => {
    pill.className =
      'host-cat-pill flex flex-col items-center justify-center p-2 rounded-xl bg-surface-container-low text-on-surface font-bold text-xs hover:bg-surface-container transition-all';
  });
  btn.className =
    'host-cat-pill active flex flex-col items-center justify-center p-2 rounded-xl bg-primary text-white font-bold text-xs shadow-sm transition-all';
}

function setHostLocation(loc) {
  document.getElementById('host-location-input').value = loc;
}

function stepHostCapacity(delta) {
  let val = AppState.hostCapacity + delta;
  if (val >= 2 && val <= 40) {
    AppState.hostCapacity = val;
    document.getElementById('host-capacity-val').textContent = val;
  }
}

function appendHostTag(tag) {
  const area = document.getElementById('host-desc-input');
  area.value = (area.value + ' ' + tag).trim();
  area.focus();
}

function handlePublishMeetup() {
  const title = document.getElementById('host-title-input').value.trim();
  const time = document.getElementById('host-time-input').value.trim();
  const location = document.getElementById('host-location-input').value.trim();
  const cost = document.getElementById('host-cost-input').value.trim();
  const desc = document.getElementById('host-desc-input').value.trim();

  if (!title) {
    showToast('Tolong isi judul aktivitas meetup!', '⚠️');
    return;
  }

  const newMeetup = {
    id: `meet-${Date.now()}`,
    title: `${title} 🚀`,
    category: AppState.selectedHostCat,
    categoryLabel: AppState.selectedHostCat,
    host: {
      name: AppState.currentUser.name,
      major: AppState.currentUser.major,
      reputation: AppState.currentUser.reputation,
      meetupsHosted: 4,
      avatar: AppState.currentUser.avatar,
    },
    time: time || 'Besok, 18:30 WIB',
    timeDuration: time || 'Besok, 18:30 WIB',
    location: location || 'Sports Hall Lt. 3 (BINUS Anggrek)',
    campus: 'BINUS Anggrek Campus',
    cost: cost || 'Free',
    slotsLeft: AppState.hostCapacity - 1,
    maxSlots: AppState.hostCapacity,
    currentSlots: 1,
    isJoined: true,
    image: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=800&q=80',
    description: desc || 'Meetup baru di kampus BINUS.',
    tags: ['#NewMeetup', `#${AppState.selectedHostCat}`, '#VerifiedStudent'],
    roster: [{ name: 'Marcelinus W.', role: 'Host', major: 'CS' }],
  };

  AppState.meetups.unshift(newMeetup);
  showToast('Meetup berhasil dipublikasikan ke kampus! 🎉', '🚀');
  navigateTo(2);
}

// =========================================================================
// Screen 5: Squad Chat & Real-Time In-Chat Polling
// =========================================================================

function voteChatPoll(optIndex) {
  if (AppState.hasVotedPoll) {
    showToast('Anda sudah memberikan voting pada polling ini', 'ℹ️');
    return;
  }

  AppState.hasVotedPoll = true;
  AppState.pollVotes[optIndex] += 1;
  const total = AppState.pollVotes[0] + AppState.pollVotes[1];

  const pct0 = Math.round((AppState.pollVotes[0] / total) * 100);
  const pct1 = Math.round((AppState.pollVotes[1] / total) * 100);

  document.getElementById('poll-bar-0').style.width = `${pct0}%`;
  document.getElementById('poll-bar-1').style.width = `${pct1}%`;

  document.getElementById('poll-val-0').textContent = `${pct0}% (${AppState.pollVotes[0]} votes)`;
  document.getElementById('poll-val-1').textContent = `${pct1}% (${AppState.pollVotes[1]} votes)`;
  document.getElementById('poll-votes-counter').textContent = `${total} votes`;

  showToast('Voting Anda berhasil dicatat! ✓', '🗳️');
}

function sendChatMessage() {
  const input = document.getElementById('chat-input-text');
  const text = input.value.trim();
  if (!text) return;

  const stream = document.getElementById('chat-stream');
  const now = new Date();
  const timeStr = now.getHours().toString().padStart(2, '0') + ':' + now.getMinutes().toString().padStart(2, '0');

  const msgDiv = document.createElement('div');
  msgDiv.className = 'flex items-start justify-end gap-2 ml-auto max-w-[85%]';
  msgDiv.innerHTML = `
    <div class="flex flex-col items-end gap-0.5">
      <div class="flex items-baseline gap-1 text-[11px]">
        <span class="text-outline text-[9px]">${timeStr}</span>
        <span class="font-bold text-primary">You</span>
      </div>
      <div class="bg-primary-container text-on-primary p-2.5 rounded-2xl rounded-tr-sm shadow-md text-xs leading-relaxed">
        ${text}
      </div>
    </div>
  `;

  stream.appendChild(msgDiv);
  input.value = '';
  stream.scrollTop = stream.scrollHeight;
}

function autofillChat(text) {
  const input = document.getElementById('chat-input-text');
  input.value = text;
  input.focus();
}

function toggleVenueDrawer() {
  const drawer = document.getElementById('venue-drawer');
  drawer.classList.toggle('hidden');
}

// =========================================================================
// Screen 6: Student Profile & Preferences
// =========================================================================

function switchProfileTab(tab, btn) {
  document.querySelectorAll('.profile-tab-btn').forEach((b) => {
    b.className = 'profile-tab-btn flex-1 py-1.5 rounded-lg text-on-surface-variant';
  });
  btn.className = 'profile-tab-btn flex-1 py-1.5 rounded-lg bg-surface-card text-on-surface shadow-sm font-bold';

  const upcoming = document.getElementById('tab-upcoming-content');
  const past = document.getElementById('tab-past-content');
  const settings = document.getElementById('tab-settings-content');

  upcoming.classList.add('hidden');
  past.classList.add('hidden');
  settings.classList.add('hidden');

  if (tab === 'upcoming') upcoming.classList.remove('hidden');
  if (tab === 'past') past.classList.remove('hidden');
  if (tab === 'settings') settings.classList.remove('hidden');
}

function addInterestBadge() {
  const container = document.getElementById('profile-badges');
  const newBadges = ['🎮 Dota 2', '🍕 Pizza Night', '🎨 Figma Pro', '🏃 5K Morning Run'];
  const rand = newBadges[Math.floor(Math.random() * newBadges.length)];

  const span = document.createElement('span');
  span.className = 'px-2.5 py-1 rounded-full bg-indigo-50 border border-indigo-200 text-indigo-700 font-semibold text-[11px] animate-pulse';
  span.textContent = rand;

  container.insertBefore(span, container.lastElementChild);
  showToast(`Badge ${rand} ditambahkan ke profil!`, '⭐');
}

// =========================================================================
// Modal & Toast Helpers
// =========================================================================

function openCampusModal() {
  showToast('Kampus saat ini: BINUS Anggrek Campus', '📍');
}

function showToast(msg, icon = '✓') {
  const pill = document.getElementById('toast-pill');
  document.getElementById('toast-msg').textContent = msg;
  document.getElementById('toast-icon').textContent = icon;

  pill.classList.remove('opacity-0', '-translate-y-4');
  pill.classList.add('opacity-100', 'translate-y-0');

  setTimeout(() => {
    pill.classList.remove('opacity-100', 'translate-y-0');
    pill.classList.add('opacity-0', '-translate-y-4');
  }, 2400);
}

// Initialize on page load
window.addEventListener('DOMContentLoaded', () => {
  renderFeed();
});
