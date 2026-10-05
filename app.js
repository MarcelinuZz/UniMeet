const AppState = {
  currentUser: {
    name: "Marcelinus Wijaya Oey",
    email: "marcelinus.wijaya@binus.ac.id",
    nim: "2602194831",
    major: "Computer Science",
    classYear: "'24",
    campus: "BINUS Anggrek Campus",
    avatar: "MW",
    satPoints: 118,
    gpa: "3.84",
    reputation: 4.95,
    eventsJoined: 14,
    eventsHosted: 3
  },

  currentScreen: 1,
  screenHistory: [1],
  selectedCampus: "BINUS Anggrek Campus",
  activeCategory: "all",
  activeMentorCategory: "all",

  meetups: [
    {
      id: "meet-1",
      title: "Badminton Double Sparring 🏸",
      host: {
        name: "Oliver Wiryateja Herlianto",
        nim: "2602195542",
        major: "CS '24",
        campus: "Syahdan",
        rating: 4.9,
        hostedCount: 14,
        avatar: "OW",
        color: "#0047BA"
      },
      category: "sports",
      categoryLabel: "Sports",
      date: "Today, Friday",
      time: "18:30 - 20:30 WIB",
      location: "Sports Hall Lt. 3 - Court B (BINUS Anggrek)",
      cost: "Rp 15.000 / pax",
      maxSlots: 6,
      currentSlots: 4,
      isJoined: false,
      campusVerifiedOnly: true,
      description: "Sparring ganda santai intermediate! Lapangan sudah dibooking dan lunas lewat Binus Sports Club. Tinggal bawa raket dan shuttlecock sudah disiapin.",
      roster: [
        { name: "Oliver Wiryateja H.", role: "Host", major: "CS '24", avatar: "OW" },
        { name: "Jecsen", role: "Joined", major: "CS '24", avatar: "JC" },
        { name: "Melvin Goh", role: "Joined", major: "Cyber Sec '24", avatar: "MG" },
        { name: "Samuel Joseph Wijaya", role: "Joined", major: "Design '25", avatar: "SJ" }
      ]
    },
    {
      id: "meet-2",
      title: "Valorant 5v5 Custom & Boba 🎯",
      host: {
        name: "Melvin Goh",
        nim: "2602173310",
        major: "Cyber Sec '24",
        campus: "Anggrek",
        rating: 4.8,
        hostedCount: 9,
        avatar: "MG",
        color: "#EA580C"
      },
      category: "gaming",
      categoryLabel: "Gaming",
      date: "Tonight",
      time: "20:00 - 23:00 WIB",
      location: "Discord Voice & Syahdan Boba Alley",
      cost: "Gratis / Bayar Minum Sendiri",
      maxSlots: 10,
      currentSlots: 8,
      isJoined: true,
      campusVerifiedOnly: true,
      description: "Custom match santai 5v5 antar mahasiswa Binus. Rank Gold-Diamond welcome, no toxicity!",
      roster: [
        { name: "Melvin Goh", role: "Host", major: "Cyber Sec '24", avatar: "MG" },
        { name: "Marcelinus Wijaya Oey", role: "Joined (You)", major: "CS '24", avatar: "MW" },
        { name: "Oliver Wiryateja", role: "Joined", major: "CS '24", avatar: "OW" }
      ]
    },
    {
      id: "meet-3",
      title: "Calculus & UI/UX Peer Review 📐",
      host: {
        name: "Samuel Joseph Wijaya",
        nim: "2602165842",
        major: "IDT '25",
        campus: "Bekasi",
        rating: 5.0,
        hostedCount: 6,
        avatar: "SJ",
        color: "#4F46E5"
      },
      category: "study",
      categoryLabel: "Academic",
      date: "Tomorrow, Saturday",
      time: "14:00 - 16:30 WIB",
      location: "BINUS Anggrek Library 4th Fl. Silent Room 402",
      cost: "Free (Bawa Tumbler Sendiri)",
      maxSlots: 5,
      currentSlots: 3,
      isJoined: false,
      campusVerifiedOnly: true,
      description: "Belajar bareng bedah soal Calculus persiapan UAS dan sharing portofolio Figma design.",
      roster: [
        { name: "Samuel Joseph Wijaya", role: "Host", major: "IDT '25", avatar: "SJ" },
        { name: "Jecsen", role: "Joined", major: "CS '24", avatar: "JC" }
      ]
    },
    {
      id: "meet-4",
      title: "Flutter & Mobile App Code Jam 💻",
      host: {
        name: "Jecsen",
        nim: "2602189421",
        major: "CS '24",
        campus: "Kijang",
        rating: 4.85,
        hostedCount: 5,
        avatar: "JC",
        color: "#0284C7"
      },
      category: "study",
      categoryLabel: "Tech & Code",
      date: "Sunday",
      time: "13:00 - 16:00 WIB",
      location: "Co-working Space Lt. 2 Kampus Kijang",
      cost: "Free",
      maxSlots: 4,
      currentSlots: 2,
      isJoined: false,
      campusVerifiedOnly: true,
      description: "Hands-on build mini project Flutter & sharing pengalaman magang tech company.",
      roster: [
        { name: "Jecsen", role: "Host", major: "CS '24", avatar: "JC" }
      ]
    }
  ],

  mentors: [
    {
      id: "m-1",
      name: "Oliver Wiryateja Herlianto",
      major: "Computer Science",
      batch: "Binusian 2024",
      campus: "Syahdan / Anggrek",
      focus: "Software Eng & Cloud Computing",
      rating: "5.0 (24 reviews)",
      avatar: "OW",
      badge: "Top Mentor"
    },
    {
      id: "m-2",
      name: "Melvin Goh",
      major: "Cyber Security",
      batch: "Binusian 2024",
      campus: "Anggrek",
      focus: "Offensive Security & CTF Player",
      rating: "4.9 (18 reviews)",
      avatar: "MG",
      badge: "Industry Intern"
    },
    {
      id: "m-3",
      name: "Samuel Joseph Wijaya",
      major: "Interactive Design & Tech",
      batch: "Binusian 2025",
      campus: "Bekasi / Anggrek",
      focus: "UI/UX & Product Strategy",
      rating: "4.95 (19 reviews)",
      avatar: "SJ",
      badge: "Design Lead"
    },
    {
      id: "m-4",
      name: "Jecsen",
      major: "Computer Science",
      batch: "Binusian 2024",
      campus: "Kijang / Anggrek",
      focus: "Cross-Platform Mobile Dev",
      rating: "4.8 (12 reviews)",
      avatar: "JC",
      badge: "Scholarship Awardee"
    }
  ],

  chatMessages: [
    { sender: "Oliver Wiryateja (Host)", text: "Halo squad! Lapangan Badminton Court B udah resmi lunas ya. Bukti booking sudah terlampir di atas.", time: "16:45", isSelf: false },
    { sender: "Melvin Goh", text: "Mantap Li! Nanti gua bawa shuttlecock tambahan satu tabung Yonex.", time: "16:50", isSelf: false },
    { sender: "Jecsen", text: "Gua berangkat bareng dari kosan Syahdan jam 18:00, ada yang mau tebeng motor?", time: "17:02", isSelf: false },
    { sender: "Samuel Joseph", text: "Boleh tebeng Jecsen! Nanti gua tunggu di lobby ya.", time: "17:05", isSelf: false }
  ],

  poll: {
    question: "Pemanasan & stretching bareng mulai jam berapa guys?",
    totalVotes: 4,
    hasVoted: false,
    options: [
      { text: "18:15 WIB (15 menit sebelum sparring)", votes: 3, percentage: 75 },
      { text: "18:30 WIB (Tepat waktu langsung main)", votes: 1, percentage: 25 }
    ]
  }
};

function navigateTo(screenNumber) {
  if (screenNumber === AppState.currentScreen) return;

  AppState.screenHistory.push(screenNumber);
  AppState.currentScreen = screenNumber;

  renderScreens();
  updateNavState();
}

function navigateBack() {
  if (AppState.screenHistory.length > 1) {
    AppState.screenHistory.pop();
    const prev = AppState.screenHistory[AppState.screenHistory.length - 1];
    AppState.currentScreen = prev;
    renderScreens();
    updateNavState();
  }
}

function renderScreens() {
  const allScreens = document.querySelectorAll(".screen-view");
  allScreens.forEach((scr) => {
    const screenId = parseInt(scr.getAttribute("data-screen"));
    if (screenId === AppState.currentScreen) {
      scr.classList.add("active");
    } else {
      scr.classList.remove("active");
    }
  });

  const bottomNav = document.getElementById("app-bottom-nav");
  if (bottomNav) {
    if (AppState.currentScreen === 1) {
      bottomNav.style.display = "none";
    } else {
      bottomNav.style.display = "flex";
    }
  }

  document.querySelectorAll(".jump-button").forEach((btn) => {
    const scr = parseInt(btn.getAttribute("data-target"));
    if (scr === AppState.currentScreen) {
      btn.className = "jump-button tactile px-3 py-1.5 rounded-xl bg-indigo-600 text-white font-bold text-xs shadow-sm whitespace-nowrap";
    } else {
      btn.className = "jump-button tactile px-3 py-1.5 rounded-xl bg-slate-800 text-slate-400 font-medium text-xs hover:bg-slate-700 whitespace-nowrap";
    }
  });
}

function updateNavState() {
  document.querySelectorAll(".nav-item").forEach((item) => {
    const targetScreen = parseInt(item.getAttribute("data-screen"));
    if (targetScreen === AppState.currentScreen) {
      item.classList.add("active");
    } else {
      item.classList.remove("active");
    }
  });
}

let toastTimer = null;
function showToast(message, type = "success", icon = "✓") {
  const container = document.getElementById("toast-system");
  const msgEl = document.getElementById("toast-system-msg");
  const iconEl = document.getElementById("toast-system-icon");

  if (!container || !msgEl || !iconEl) return;

  msgEl.innerText = message;
  iconEl.innerText = icon;

  if (type === "warning") iconEl.className = "text-amber-400 font-bold";
  else if (type === "error") iconEl.className = "text-rose-400 font-bold";
  else iconEl.className = "text-emerald-400 font-bold";

  container.classList.add("visible");

  if (toastTimer) clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    container.classList.remove("visible");
  }, 2600);
}

function handleLogin() {
  showToast(`Selamat datang, ${AppState.currentUser.name}!`, "success", "🎓");
  navigateTo(2);
}

function setFilterCategory(category, buttonEl) {
  AppState.activeCategory = category;

  document.querySelectorAll(".feed-cat-btn").forEach((btn) => {
    btn.className = "feed-cat-btn tactile badge-pill bg-white text-slate-700 border border-slate-200";
  });
  if (buttonEl) {
    buttonEl.className = "feed-cat-btn tactile badge-pill bg-indigo-600 text-white shadow-sm";
  }

  renderMeetupFeed();
}

function switchCampus(campusName) {
  AppState.selectedCampus = campusName;
  const label = document.getElementById("current-campus-label");
  if (label) label.innerText = campusName + " ▾";
  closeModal('modal-campus');
  showToast(`Lokasi kampus dialihkan ke: ${campusName}`);
}

function renderMeetupFeed() {
  const container = document.getElementById("feed-meetups-list");
  if (!container) return;

  const filtered = AppState.activeCategory === "all"
    ? AppState.meetups
    : AppState.meetups.filter((m) => m.category === AppState.activeCategory);

  container.innerHTML = "";

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="text-center py-8 text-slate-400 text-xs">
        <p>Belum ada meetup di kategori ini.</p>
        <button onclick="navigateTo(4)" class="mt-2 text-indigo-600 font-bold">Buat Meetup Baru +</button>
      </div>
    `;
    return;
  }

  filtered.forEach((item) => {
    const card = document.createElement("div");
    card.className = "card-surface clickable p-3.5 space-y-2.5 tactile cursor-pointer";
    card.onclick = () => openEventDetail(item.id);

    const isFull = item.currentSlots >= item.maxSlots;

    card.innerHTML = `
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <div class="w-7 h-7 rounded-full text-white font-bold text-xs flex items-center justify-center" style="background-color: ${item.host.color};">
            ${item.host.avatar}
          </div>
          <div>
            <div class="text-xs font-bold text-slate-900">${item.host.name}</div>
            <div class="text-[10px] text-slate-500">${item.host.major} • ${item.host.campus} • ⭐ ${item.host.rating}</div>
          </div>
        </div>
        <span class="badge-pill bg-slate-100 text-slate-600">${item.categoryLabel}</span>
      </div>

      <div>
        <h4 class="text-xs font-extrabold text-slate-900 leading-snug">${item.title}</h4>
        <p class="text-[11px] text-slate-500 mt-0.5">📅 ${item.date}, ${item.time}</p>
        <p class="text-[11px] text-slate-500">📍 ${item.location}</p>
      </div>

      <div class="flex items-center justify-between pt-2 border-t border-slate-100 text-xs">
        <span class="font-bold ${isFull ? 'text-rose-600' : 'text-indigo-600'}">
          👥 ${item.currentSlots}/${item.maxSlots} spots filled
        </span>
        <button onclick="event.stopPropagation(); quickJoin('${item.id}')" class="tactile px-3 py-1 bg-indigo-600 text-white font-bold text-[11px] rounded-lg shadow-sm">
          ${item.isJoined ? 'Joined ✓' : 'Quick Join +'}
        </button>
      </div>
    `;
    container.appendChild(card);
  });
}

function quickJoin(meetupId) {
  const meetup = AppState.meetups.find(m => m.id === meetupId);
  if (!meetup) return;

  if (meetup.isJoined) {
    showToast("Kamu sudah tergabung di squad ini!", "success");
    navigateTo(5);
    return;
  }

  if (meetup.currentSlots >= meetup.maxSlots) {
    showToast("Maaf, kuota squad ini sudah penuh!", "warning", "⚠️");
    return;
  }

  meetup.isJoined = true;
  meetup.currentSlots += 1;
  meetup.roster.push({
    name: AppState.currentUser.name,
    role: "Joined (You)",
    major: AppState.currentUser.major + " " + AppState.currentUser.classYear,
    avatar: AppState.currentUser.avatar
  });

  renderMeetupFeed();
  showToast(`🎉 Berhasil bergabung ke "${meetup.title}"!`);
  navigateTo(5);
}

function openEventDetail(meetupId) {
  const item = AppState.meetups.find(m => m.id === meetupId) || AppState.meetups[0];
  
  document.getElementById("detail-title").innerText = item.title;
  document.getElementById("detail-time").innerText = `${item.date} • ${item.time}`;
  document.getElementById("detail-location").innerText = item.location;
  document.getElementById("detail-host-name").innerText = item.host.name;
  document.getElementById("detail-host-meta").innerText = `Host • ${item.host.major} • ⭐ ${item.host.rating} (${item.host.hostedCount} Hosted)`;
  document.getElementById("detail-host-avatar").innerText = item.host.avatar;
  document.getElementById("detail-host-avatar").style.backgroundColor = item.host.color;
  document.getElementById("detail-description").innerText = item.description;
  document.getElementById("detail-cost").innerText = item.cost;
  document.getElementById("detail-slots-count").innerText = `${item.currentSlots} of ${item.maxSlots} Joined`;

  const rosterBox = document.getElementById("detail-roster-list");
  if (rosterBox) {
    rosterBox.innerHTML = "";
    item.roster.forEach(r => {
      const row = document.createElement("div");
      row.className = "flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-100 text-xs";
      row.innerHTML = `
        <div class="flex items-center gap-2">
          <div class="w-6 h-6 rounded-full bg-indigo-600 text-white font-bold text-[10px] flex items-center justify-center">
            ${r.avatar}
          </div>
          <div>
            <div class="font-bold text-slate-800 text-[11px]">${r.name}</div>
            <div class="text-[9px] text-slate-400">${r.major}</div>
          </div>
        </div>
        <span class="badge-pill bg-emerald-100 text-emerald-700 text-[10px] font-bold">${r.role}</span>
      `;
      rosterBox.appendChild(row);
    });
  }

  const rsvpBtn = document.getElementById("detail-rsvp-btn");
  if (rsvpBtn) {
    if (item.isJoined) {
      rsvpBtn.innerText = "Buka Squad Chat ➔";
      rsvpBtn.onclick = () => navigateTo(5);
    } else {
      rsvpBtn.innerText = "RSVP & Join Squad ➔";
      rsvpBtn.onclick = () => quickJoin(item.id);
    }
  }

  navigateTo(3);
}

let hostCurrentSlots = 6;
function changeHostSlot(delta) {
  hostCurrentSlots += delta;
  if (hostCurrentSlots < 2) hostCurrentSlots = 2;
  if (hostCurrentSlots > 30) hostCurrentSlots = 30;
  const el = document.getElementById("host-slot-val");
  if (el) el.innerText = hostCurrentSlots;
}

function publishNewMeetup() {
  const titleInput = document.getElementById("host-input-title");
  const catInput = document.getElementById("host-select-category");
  const locationInput = document.getElementById("host-input-location");
  const timeInput = document.getElementById("host-input-time");

  const title = titleInput.value.trim() || "Campus Study & Sparring Meetup";
  const category = catInput.value || "study";
  const location = locationInput.value.trim() || "BINUS Anggrek Library";
  const time = timeInput.value.trim() || "Besok, 16:00 WIB";

  const newMeet = {
    id: "meet-" + (AppState.meetups.length + 1),
    title: title,
    host: {
      name: AppState.currentUser.name,
      nim: AppState.currentUser.nim,
      major: AppState.currentUser.major + " " + AppState.currentUser.classYear,
      campus: "Anggrek",
      rating: 5.0,
      hostedCount: 4,
      avatar: "MW",
      color: "#0047BA"
    },
    category: category,
    categoryLabel: category.toUpperCase(),
    date: "Upcoming",
    time: time,
    location: location,
    cost: "Free / Shared",
    maxSlots: hostCurrentSlots,
    currentSlots: 1,
    isJoined: true,
    campusVerifiedOnly: true,
    description: "Meetup dibuat oleh Marcelinus Wijaya Oey khusus untuk mahasiswa Binusian.",
    roster: [
      { name: AppState.currentUser.name, role: "Host (You)", major: "CS '24", avatar: "MW" }
    ]
  };

  AppState.meetups.unshift(newMeet);
  renderMeetupFeed();
  showToast(`Aktivitas "${title}" berhasil dipublish ke kampus!`, "success", "🚀");

  titleInput.value = "";
  navigateTo(2);
}

function sendLiveChat() {
  const input = document.getElementById("chat-type-input");
  const text = input.value.trim();
  if (!text) return;

  const msgBox = document.getElementById("chat-stream-box");
  
  const userMsg = document.createElement("div");
  userMsg.className = "flex flex-col items-end space-y-1";
  userMsg.innerHTML = `
    <div class="text-[10px] text-slate-400 font-semibold">${AppState.currentUser.name} (You) • Barusan</div>
    <div class="bg-indigo-600 text-white p-2.5 rounded-2xl rounded-tr-xs text-xs max-w-[85%] shadow-sm">
      ${text}
    </div>
  `;
  msgBox.appendChild(userMsg);
  input.value = "";
  msgBox.scrollTop = msgBox.scrollHeight;

  setTimeout(() => {
    const peers = [
      { name: "Oliver Wiryateja", text: "Siap Cel! Gua udah konfirmasi ke satpam sport hall juga ya.", avatar: "OW" },
      { name: "Melvin Goh", text: "Aman, gua meluncur sekarang dari kosan!", avatar: "MG" },
      { name: "Samuel Joseph", text: "Oke sip, gua bawa botol minum tambahan nih.", avatar: "SJ" }
    ];
    const pick = peers[Math.floor(Math.random() * peers.length)];

    const peerMsg = document.createElement("div");
    peerMsg.className = "flex flex-col items-start space-y-1";
    peerMsg.innerHTML = `
      <div class="text-[10px] text-indigo-700 font-bold">${pick.name} • Barusan</div>
      <div class="bg-white border border-slate-200 text-slate-800 p-2.5 rounded-2xl rounded-tl-xs text-xs max-w-[85%] shadow-sm">
        ${pick.text}
      </div>
    `;
    msgBox.appendChild(peerMsg);
    msgBox.scrollTop = msgBox.scrollHeight;
  }, 1000);
}

function votePoll(choiceIdx) {
  if (AppState.poll.hasVoted) {
    showToast("Kamu sudah memberikan suara pada voting ini!", "warning");
    return;
  }

  AppState.poll.hasVoted = true;
  AppState.poll.totalVotes += 1;
  AppState.poll.options[choiceIdx].votes += 1;

  const opt0 = AppState.poll.options[0];
  const opt1 = AppState.poll.options[1];
  const total = AppState.poll.totalVotes;

  opt0.percentage = Math.round((opt0.votes / total) * 100);
  opt1.percentage = 100 - opt0.percentage;

  document.getElementById("poll-total-votes").innerText = `${total} votes`;
  document.getElementById("poll-opt0-pct").innerText = `${opt0.percentage}% (${opt0.votes} votes)`;
  document.getElementById("poll-opt1-pct").innerText = `${opt1.percentage}% (${opt1.votes} votes)`;
  document.getElementById("poll-opt0-bar").style.width = `${opt0.percentage}%`;
  document.getElementById("poll-opt1-bar").style.width = `${opt1.percentage}%`;

  showToast(`Pilihan kamu berhasil dicatat! (${choiceIdx === 0 ? '18:15' : '18:30'})`);
}

function filterMentorByMajor(major, btn) {
  AppState.activeMentorCategory = major;
  document.querySelectorAll(".mentor-filter-pill").forEach(b => {
    b.className = "mentor-filter-pill tactile badge-pill bg-white text-slate-700 border border-slate-200";
  });
  if (btn) btn.className = "mentor-filter-pill tactile badge-pill bg-indigo-600 text-white shadow-sm";

  const cards = document.querySelectorAll(".mentor-card-item");
  cards.forEach(c => {
    const m = c.getAttribute("data-major");
    if (major === "all" || m === major) {
      c.style.display = "block";
    } else {
      c.style.display = "none";
    }
  });
}

function requestCoffeeChat(mentorName) {
  showToast(`Permintaan ngopi & bimbingan dengan ${mentorName} telah terkirim!`, "success", "☕");
}

function openQrPass() {
  const modal = document.getElementById("modal-qr-pass");
  if (modal) modal.classList.add("active");
}

function closeQrPass() {
  const modal = document.getElementById("modal-qr-pass");
  if (modal) modal.classList.remove("active");
}

function openModal(id) {
  const m = document.getElementById(id);
  if (m) m.classList.add("active");
}

function closeModal(id) {
  const m = document.getElementById(id);
  if (m) m.classList.remove("active");
}

function toggleDeviceMode() {
  const isMobileNative = document.body.classList.toggle("mobile-native-mode");
  const btn = document.getElementById("btn-toggle-device");
  if (btn) {
    btn.innerHTML = isMobileNative 
      ? "<span>📱</span> Kembalikan ke Frame iPhone" 
      : "<span>🖥️</span> Fullscreen Mobile Mode";
  }
  showToast(isMobileNative ? "Mode Fullscreen Layar Penuh Aktif" : "Mode Simulator iPhone Aktif");
}

document.addEventListener("DOMContentLoaded", () => {
  renderScreens();
  renderMeetupFeed();
  updateNavState();

  const chatInput = document.getElementById("chat-type-input");
  if (chatInput) {
    chatInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") sendLiveChat();
    });
  }
});
