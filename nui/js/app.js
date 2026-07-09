const App = {
    profile: null,
    currentPage: 'home',
    isOpen: false,

    init() {
        this.bindEvents();
        window.addEventListener('message', this.onMessage.bind(this));
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isOpen) {
                this.closeLaptop();
            }
        });
    },

    onMessage(event) {
        const data = event.data;

        switch (data.action) {
            case 'open':
                this.isOpen = true;
                this.profile = null;
                document.getElementById('laptop').classList.remove('hidden');

                if (data.hasProfile) {
                    this.profile = data.profile;
                    this.showMain();
                } else {
                    this.showLogin();
                }
                break;

            case 'close':
                this.isOpen = false;
                document.getElementById('laptop').classList.add('hidden');
                break;

            case 'profileData':
                this.profile = data.profile;
                this.updateAllPages();
                break;

            case 'listingsData':
                Pages.renderListings(data.listings);
                Pages.populateFilter(data.listings || []);
                break;

            case 'notify':
                this.showNotification(data.message, data.type);
                break;
        }
    },

    bindEvents() {
        document.getElementById('login-btn').addEventListener('click', () => {
            this.register();
        });

        document.getElementById('username-input').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.register();
        });

        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', () => {
                this.navigateTo(item.dataset.page);
            });
        });

        document.getElementById('close-laptop').addEventListener('click', () => {
            this.closeLaptop();
        });

        document.getElementById('btn-refresh-market').addEventListener('click', () => {
            this.loadListings();
        });

        document.getElementById('btn-create-listing').addEventListener('click', () => {
            document.getElementById('create-listing-modal').classList.remove('hidden');
        });

        document.getElementById('close-modal').addEventListener('click', () => {
            document.getElementById('create-listing-modal').classList.add('hidden');
        });

        document.getElementById('submit-listing').addEventListener('click', () => {
            this.submitListing();
        });

        document.getElementById('btn-change-alias').addEventListener('click', () => {
            document.getElementById('change-alias-modal').classList.remove('hidden');
        });

        document.getElementById('close-alias-modal').addEventListener('click', () => {
            document.getElementById('change-alias-modal').classList.add('hidden');
        });

        document.getElementById('submit-alias').addEventListener('click', () => {
            this.submitAlias();
        });

        document.getElementById('market-search').addEventListener('input', () => {
            this.loadListings();
        });

        document.getElementById('market-filter').addEventListener('change', () => {
            this.loadListings();
        });
    },

    async register() {
        const input = document.getElementById('username-input');
        const username = input.value.trim();
        const errorEl = document.getElementById('login-error');

        if (!username) {
            errorEl.textContent = 'Please enter an alias';
            errorEl.classList.remove('hidden');
            return;
        }

        if (username.length < 3) {
            errorEl.textContent = 'Alias must be at least 3 characters';
            errorEl.classList.remove('hidden');
            return;
        }

        errorEl.classList.add('hidden');
        const result = await API.register(username);

        if (result && result.success) {
            this.profile = result.profile;
            this.showMain();
        } else {
            errorEl.textContent = result?.message || 'Registration failed';
            errorEl.classList.remove('hidden');
        }
    },

    showLogin() {
        document.getElementById('login-screen').classList.remove('hidden');
        document.getElementById('main-interface').classList.add('hidden');
        document.getElementById('username-input').value = '';
        document.getElementById('login-error').classList.add('hidden');
    },

    showMain() {
        document.getElementById('login-screen').classList.add('hidden');
        document.getElementById('main-interface').classList.remove('hidden');
        this.updateAllPages();
        this.navigateTo('home');
    },

    async updateAllPages() {
        if (!this.profile) return;

        Pages.updateTopbar(this.profile);
        Pages.renderHome(this.profile);
        Pages.renderAbout(this.profile);
    },

    navigateTo(page) {
        this.currentPage = page;

        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.toggle('active', item.dataset.page === page);
        });

        document.querySelectorAll('.page').forEach(p => {
            p.classList.toggle('active', p.id === 'page-' + page);
        });

        const titles = { home: 'Home', blackmarket: 'Black Market', jobs: 'Jobs', about: 'About' };
        document.getElementById('page-title').textContent = titles[page] || page;

        if (page === 'blackmarket') {
            this.loadListings();
        }
    },

    async loadListings() {
        const search = document.getElementById('market-search')?.value || '';
        const filter = document.getElementById('market-filter')?.value || 'all';
        await API.getListings(search, filter);
    },

    async submitListing() {
        const itemName = document.getElementById('listing-item-name').value.trim();
        const itemLabel = document.getElementById('listing-item-label').value.trim();
        const amount = parseInt(document.getElementById('listing-amount').value) || 1;
        const price = parseInt(document.getElementById('listing-price').value) || 0;

        if (!itemName || !itemLabel || !price) {
            this.showNotification('Please fill in all fields', 'error');
            return;
        }

        if (price < 100) {
            this.showNotification('Minimum price is $100', 'error');
            return;
        }

        const result = await API.createListing({ itemName, itemLabel, amount, price });

        if (result && result.success) {
            document.getElementById('create-listing-modal').classList.add('hidden');
            document.getElementById('listing-item-name').value = '';
            document.getElementById('listing-item-label').value = '';
            document.getElementById('listing-amount').value = '1';
            document.getElementById('listing-price').value = '';
            this.showNotification('Listing created successfully', 'success');
            this.loadListings();
        } else {
            this.showNotification(result?.message || 'Failed to create listing', 'error');
        }
    },

    async buyListing(listingId) {
        const result = await API.buyListing(listingId);

        if (result && result.success) {
            this.showNotification('Purchase successful', 'success');
            this.loadListings();
            this.refreshProfile();
        } else {
            this.showNotification(result?.message || 'Purchase failed', 'error');
        }
    },

    async submitAlias() {
        const newAlias = document.getElementById('new-alias-input').value.trim();

        if (!newAlias) {
            this.showNotification('Please enter a new alias', 'error');
            return;
        }

        if (newAlias.length < 3) {
            this.showNotification('Alias must be at least 3 characters', 'error');
            return;
        }

        const result = await API.changeAlias(newAlias);

        if (result && result.success) {
            this.profile.username = newAlias;
            this.updateAllPages();
            document.getElementById('change-alias-modal').classList.add('hidden');
            document.getElementById('new-alias-input').value = '';
            this.showNotification('Alias changed successfully', 'success');
        } else {
            this.showNotification(result?.message || 'Failed to change alias', 'error');
        }
    },

    async refreshProfile() {
        await API.getProfile();
    },

    async closeLaptop() {
        this.isOpen = false;
        document.getElementById('laptop').classList.add('hidden');
        await API.close();
    },

    showNotification(message, type) {
        const existing = document.querySelector('.nui-notification');
        if (existing) existing.remove();

        const notif = document.createElement('div');
        notif.className = 'nui-notification ' + (type || 'info');
        notif.innerHTML = `<span>${message}</span>`;
        notif.style.cssText = `
            position: fixed; bottom: 20px; right: 20px; z-index: 9999;
            padding: 12px 24px; border-radius: 8px; font-size: 13px;
            color: #fff; animation: fadeIn 0.3s;
            background: ${type === 'success' ? '#27ae60' : type === 'error' ? '#e74c3c' : '#8b2fc9'};
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        `;
        document.body.appendChild(notif);

        setTimeout(() => notif.remove(), 3000);
    }
};

document.addEventListener('DOMContentLoaded', () => App.init());
