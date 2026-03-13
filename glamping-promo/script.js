// ===== NAVBAR SCROLL EFFECT =====
const navbar = document.getElementById('navbar');

window.addEventListener('scroll', () => {
    if (window.scrollY > 60) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// ===== MOBILE NAV TOGGLE =====
const navToggle = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');

navToggle.addEventListener('click', () => {
    navLinks.classList.toggle('active');
    navToggle.classList.toggle('active');
});

// Close nav on link click
navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
        navLinks.classList.remove('active');
        navToggle.classList.remove('active');
    });
});

// ===== HERO PARTICLES =====
const particlesContainer = document.getElementById('particles');

function createParticles() {
    for (let i = 0; i < 20; i++) {
        const particle = document.createElement('div');
        particle.classList.add('particle');
        particle.style.left = Math.random() * 100 + '%';
        particle.style.animationDuration = (Math.random() * 10 + 8) + 's';
        particle.style.animationDelay = Math.random() * 10 + 's';
        particle.style.width = (Math.random() * 4 + 2) + 'px';
        particle.style.height = particle.style.width;
        particlesContainer.appendChild(particle);
    }
}

createParticles();

// ===== SCROLL ANIMATIONS =====
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('visible');
        }
    });
}, observerOptions);

// Add fade-in class to animated elements
document.querySelectorAll('.feature-card, .acc-card, .spring-card, .pricing-card, .testimonial-card, .gallery-item, .meal, .info-card').forEach(el => {
    el.classList.add('fade-in');
    observer.observe(el);
});

// ===== SMOOTH SCROLL FOR ANCHOR LINKS =====
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const offset = 80;
            const position = target.getBoundingClientRect().top + window.scrollY - offset;
            window.scrollTo({ top: position, behavior: 'smooth' });
        }
    });
});

// ===== BOOKING FORM =====
const bookingForm = document.getElementById('bookingForm');

bookingForm.addEventListener('submit', function (e) {
    e.preventDefault();

    const formData = new FormData(this);
    const data = Object.fromEntries(formData.entries());

    // Simple validation
    if (!data.name || !data.phone || !data.checkin || !data.checkout) {
        return;
    }

    // Show success message
    const successHTML = `
        <div class="form-success show">
            <h3>&#10004; Дякуємо, ${data.name}!</h3>
            <p>Вашу заявку на бронювання отримано.<br>
            Ми зв'яжемось з вами протягом години за номером ${data.phone}.</p>
            <p style="margin-top: 16px; font-size: 0.9rem; color: #6b6b6b;">
                Заїзд: ${data.checkin} | Виїзд: ${data.checkout}<br>
                Гості: ${data.guests} | Тип: ${getAccName(data.accommodation)}
            </p>
        </div>
    `;

    this.innerHTML = successHTML;
});

function getAccName(value) {
    const names = {
        cabin: 'Дерев\'яний будиночок',
        glamping: 'Глемпінг-намет Люкс',
        cottage: 'Сімейний котедж'
    };
    return names[value] || value;
}

// ===== SET MIN DATES FOR BOOKING =====
const checkinInput = document.getElementById('checkin');
const checkoutInput = document.getElementById('checkout');

if (checkinInput && checkoutInput) {
    const today = new Date().toISOString().split('T')[0];
    checkinInput.min = today;

    checkinInput.addEventListener('change', () => {
        const nextDay = new Date(checkinInput.value);
        nextDay.setDate(nextDay.getDate() + 1);
        checkoutInput.min = nextDay.toISOString().split('T')[0];

        if (checkoutInput.value && checkoutInput.value <= checkinInput.value) {
            checkoutInput.value = nextDay.toISOString().split('T')[0];
        }
    });
}

// ===== COUNTER ANIMATION =====
function animateCounters() {
    document.querySelectorAll('.stat-number').forEach(counter => {
        const text = counter.textContent;
        if (text.includes('+') || text.includes('%') || text.includes('x')) {
            return; // Keep static text for these
        }
    });
}

// Run on load
animateCounters();
