// ===== CURSOR GLOW =====
const cursorGlow = document.getElementById('cursorGlow');
let mouseX = 0, mouseY = 0, glowX = 0, glowY = 0;

if (window.matchMedia('(hover: hover)').matches) {
    document.addEventListener('mousemove', (e) => {
        mouseX = e.clientX;
        mouseY = e.clientY;
        cursorGlow.classList.add('active');
    });

    function animateGlow() {
        glowX += (mouseX - glowX) * 0.08;
        glowY += (mouseY - glowY) * 0.08;
        cursorGlow.style.left = glowX + 'px';
        cursorGlow.style.top = glowY + 'px';
        requestAnimationFrame(animateGlow);
    }
    animateGlow();
}

// ===== NAVBAR =====
const navbar = document.getElementById('navbar');
let lastScroll = 0;

window.addEventListener('scroll', () => {
    const current = window.scrollY;
    navbar.classList.toggle('scrolled', current > 50);
    lastScroll = current;
}, { passive: true });

// ===== MOBILE NAV =====
const navToggle = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');

navToggle.addEventListener('click', () => {
    navLinks.classList.toggle('active');
});

navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => navLinks.classList.remove('active'));
});

// ===== SMOOTH SCROLL =====
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});

// ===== SCROLL REVEAL =====
const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('visible');
        }
    });
}, { threshold: 0.1, rootMargin: '0px 0px -60px 0px' });

// Add reveal to section headers
document.querySelectorAll('.section-header').forEach(el => {
    el.classList.add('reveal');
    revealObserver.observe(el);
});

// Add stagger reveal to grids
document.querySelectorAll('.features-grid, .acc-grid, .spring-bento, .pricing-grid, .testimonials-slider, .gallery-masonry').forEach(el => {
    el.classList.add('reveal-stagger');
    revealObserver.observe(el);
});

// Add reveal to other elements
document.querySelectorAll('.food-layout, .promo-banner, .booking-layout, .food-timeline, .food-visual').forEach(el => {
    el.classList.add('reveal');
    revealObserver.observe(el);
});

// ===== MAGNETIC HOVER FOR CARDS =====
document.querySelectorAll('[data-hover]').forEach(card => {
    card.addEventListener('mousemove', (e) => {
        const rect = card.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        const centerX = rect.width / 2;
        const centerY = rect.height / 2;
        const rotateX = ((y - centerY) / centerY) * -3;
        const rotateY = ((x - centerX) / centerX) * 3;

        card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-4px)`;
    });

    card.addEventListener('mouseleave', () => {
        card.style.transform = '';
    });
});

// ===== BOOKING FORM =====
const bookingForm = document.getElementById('bookingForm');

bookingForm.addEventListener('submit', function(e) {
    e.preventDefault();

    const formData = new FormData(this);
    const data = Object.fromEntries(formData.entries());

    if (!data.name || !data.phone || !data.checkin || !data.checkout) return;

    const accNames = {
        cabin: "Будиночок",
        glamping: "Глемпінг Люкс",
        cottage: "Сімейний котедж"
    };

    this.innerHTML = `
        <div class="form-success show">
            <h3>&#10004; Дякуємо, ${data.name}!</h3>
            <p>Вашу заявку отримано. Ми зв'яжемось протягом години за номером <strong>${data.phone}</strong>.</p>
            <p style="margin-top: 16px; font-size: 0.85rem; color: var(--c-text-3);">
                ${data.checkin} &rarr; ${data.checkout} &middot; ${data.guests} гост. &middot; ${accNames[data.accommodation] || data.accommodation}
            </p>
        </div>
    `;
});

// ===== SET DATE CONSTRAINTS =====
const checkinInput = document.getElementById('checkin');
const checkoutInput = document.getElementById('checkout');

if (checkinInput && checkoutInput) {
    const today = new Date().toISOString().split('T')[0];
    checkinInput.min = today;

    checkinInput.addEventListener('change', () => {
        const nextDay = new Date(checkinInput.value);
        nextDay.setDate(nextDay.getDate() + 1);
        const minCheckout = nextDay.toISOString().split('T')[0];
        checkoutInput.min = minCheckout;

        if (checkoutInput.value && checkoutInput.value <= checkinInput.value) {
            checkoutInput.value = minCheckout;
        }
    });
}

// ===== PARALLAX ORBS =====
window.addEventListener('scroll', () => {
    const scrolled = window.scrollY;
    document.querySelectorAll('.orb').forEach((orb, i) => {
        const speed = (i + 1) * 0.03;
        orb.style.transform = `translateY(${scrolled * speed}px)`;
    });
}, { passive: true });
