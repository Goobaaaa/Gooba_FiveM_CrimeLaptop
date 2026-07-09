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
                if (data.hasProfile) {
                    this.profile = data.profile;
                    this.showMain();
                } else if (data.message) {
                    const errorEl = document.getElementById('login-error');
                    errorEl.textContent = data.message;
                    errorEl.classList.remove('hidden');
                    document.getElementById('login-btn').disabled = false;
                    document.getElementById('login-btn').innerHTML = '<i class="fas fa-sign-in-alt"></i> Register';
                } else {
                    this.isOpen = true;
                    document.getElementById('laptop').classList.remove('hidden');
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

            case 'inventoryData':
                this.renderInventoryDropdown(data.items);
                break;

            case 'pendingListings':
                this.renderPendingListings(data.listings);
                break;

            case 'myListingsData':
                this.renderMyListings(data.listings);
                break;

            case 'showDropbox':
                document.getElementById('dropbox-modal').classList.remove('hidden');
                break;

            case 'cryptoHistory':
                Pages.renderCryptoHistory(data.history);
                break;

            case 'cryptoGraph':
                Pages.renderCryptoGraph(data.history);
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
            API.getInventory();
        });

        document.getElementById('close-modal').addEventListener('click', () => {
            document.getElementById('create-listing-modal').classList.add('hidden');
        });

        document.getElementById('submit-listing').addEventListener('click', () => {
            this.submitListing();
        });

        document.getElementById('listing-item-select').addEventListener('change', (e) => {
            const option = e.target.selectedOptions[0];
            const max = option ? parseInt(option.dataset.count) || 0 : 0;
            document.getElementById('listing-max-amount').textContent = max;
            document.getElementById('listing-amount').max = max;
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

        document.getElementById('btn-transfer-crypto').addEventListener('click', () => {
            document.getElementById('transfer-crypto-modal').classList.remove('hidden');
        });

        document.getElementById('close-transfer-modal').addEventListener('click', () => {
            document.getElementById('transfer-crypto-modal').classList.add('hidden');
        });

        document.getElementById('submit-transfer').addEventListener('click', () => {
            this.submitTransfer();
        });

        document.getElementById('btn-refresh-crypto').addEventListener('click', () => {
            this.loadCryptoPage();
        });

        document.getElementById('close-dropbox-modal').addEventListener('click', () => {
            document.getElementById('dropbox-modal').classList.add('hidden');
            API.closeDropbox();
        });

        document.querySelectorAll('.market-tab').forEach(tab => {
            tab.addEventListener('click', () => {
                document.querySelectorAll('.market-tab').forEach(t => t.classList.remove('active'));
                tab.classList.add('active');
                document.querySelectorAll('.market-tab-content').forEach(c => c.classList.remove('active'));
                document.getElementById('market-tab-' + tab.dataset.marketTab).classList.remove('hidden');
                document.getElementById('market-tab-' + tab.dataset.marketTab).classList.add('active');

                if (tab.dataset.marketTab === 'mylistings') {
                    this.loadMyListings();
                }
            });
        });

        document.getElementById('btn-refresh-mylistings').addEventListener('click', () => {
            this.loadMyListings();
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
        document.getElementById('login-btn').disabled = true;
        document.getElementById('login-btn').innerHTML = '<i class="fas fa-spinner fa-spin"></i> Creating...';

        await API.register(username);
    },

    showLogin() {
        document.getElementById('login-screen').classList.remove('hidden');
        document.getElementById('main-interface').classList.add('hidden');
        document.getElementById('username-input').value = '';
        document.getElementById('login-error').classList.add('hidden');
        document.getElementById('login-btn').disabled = false;
        document.getElementById('login-btn').innerHTML = '<i class="fas fa-sign-in-alt"></i> Register';
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
        Pages.renderCryptoPage(this.profile);
    },

    navigateTo(page) {
        this.currentPage = page;

        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.toggle('active', item.dataset.page === page);
        });

        document.querySelectorAll('.page').forEach(p => {
            p.classList.toggle('active', p.id === 'page-' + page);
        });

        const titles = { home: 'Home', blackmarket: 'Black Market', crypto: 'Crypto', jobs: 'Jobs', about: 'About' };
        document.getElementById('page-title').textContent = titles[page] || page;

        if (page === 'blackmarket') {
            this.loadListings();
        }

        if (page === 'crypto') {
            this.loadCryptoPage();
        }
    },

    async loadListings() {
        const search = document.getElementById('market-search')?.value || '';
        const filter = document.getElementById('market-filter')?.value || 'all';
        await API.getListings(search, filter);
    },

    async loadMyListings() {
        await API.getMyListings();
    },

    renderMyListings(listings) {
        const container = document.getElementById('mylistings-list');
        if (!listings || listings.length === 0) {
            container.innerHTML = `
                <div class="market-empty">
                    <i class="fas fa-inbox"></i>
                    <p>No listings yet</p>
                </div>`;
            return;
        }

        container.innerHTML = listings.map(listing => `
            <div class="market-row" data-id="${listing.id}">
                <span>${escapeHtml(listing.item_label)} (${escapeHtml(listing.item_name)})</span>
                <span>${listing.amount}</span>
                <span class="item-price">${listing.price.toLocaleString()} CRM</span>
                <span><span class="status-badge ${listing.status}">${listing.status}</span></span>
                <span>
                    ${listing.status === 'active' ? `<button class="btn-cancel" onclick="App.cancelListing(${listing.id})"><i class="fas fa-times"></i> Cancel</button>` : ''}
                    ${listing.status === 'pending' ? '<span class="status-badge pending">Go to Dropbox</span>' : ''}
                </span>
            </div>
        `).join('');
    },

    async loadCryptoPage() {
        if (this.profile) {
            Pages.renderCryptoPage(this.profile);
        }
        await API.getCryptoHistory();
        await API.getCryptoGraph();
    },

    renderInventoryDropdown(items) {
        const select = document.getElementById('listing-item-select');
        select.innerHTML = '<option value="">Select an item...</option>';
        if (!items || items.length === 0) {
            select.innerHTML = '<option value="">No items in inventory</option>';
            return;
        }
        items.forEach(item => {
            select.innerHTML += `<option value="${item.name}" data-label="${item.label}" data-count="${item.count}">${item.label} (${item.count})</option>`;
        });
    },

    renderPendingListings(listings) {
        const container = document.getElementById('pending-listings-list');
        if (!listings || listings.length === 0) {
            container.innerHTML = `
                <div class="market-empty">
                    <i class="fas fa-inbox"></i>
                    <p>No pending listings</p>
                </div>`;
            return;
        }

        container.innerHTML = listings.map(listing => `
            <div class="pending-item">
                <div class="pending-item-info">
                    <span class="pending-item-name">${escapeHtml(listing.item_label)}</span>
                    <span class="pending-item-details">x${listing.amount} - ${listing.price} CRM</span>
                </div>
                <button class="btn-deposit" onclick="App.depositListing(${listing.id})">
                    <i class="fas fa-upload"></i> Deposit
                </button>
            </div>
        `).join('');
    },

    async submitListing() {
        const select = document.getElementById('listing-item-select');
        const selectedOption = select.selectedOptions[0];
        const itemName = select.value;
        const itemLabel = selectedOption ? selectedOption.dataset.label : '';
        const maxAmount = parseInt(selectedOption ? selectedOption.dataset.count : 0) || 0;
        const amount = parseInt(document.getElementById('listing-amount').value) || 1;
        const price = parseInt(document.getElementById('listing-price').value) || 0;

        if (!itemName) {
            this.showNotification('Please select an item from your inventory', 'error');
            return;
        }

        if (amount < 1) {
            this.showNotification('Amount must be at least 1', 'error');
            return;
        }

        if (amount > maxAmount) {
            this.showNotification('You only have ' + maxAmount + ' of this item', 'error');
            return;
        }

        if (price < 1) {
            this.showNotification('Price must be at least 1 CRM', 'error');
            return;
        }

        const result = await API.createListing({ itemName, itemLabel, amount, price });

        if (result && result.success) {
            document.getElementById('create-listing-modal').classList.add('hidden');
            document.getElementById('listing-amount').value = '1';
            document.getElementById('listing-price').value = '';
            select.innerHTML = '<option value="">Select an item...</option>';
            this.showNotification('Listing created. Visit a Secure Dropbox to deposit.', 'success');
        } else {
            this.showNotification(result?.message || 'Failed to create listing', 'error');
        }
    },

    async depositListing(listingId) {
        const result = await API.depositListing(listingId);
        if (result && result.success) {
            this.showNotification('Item deposited successfully', 'success');
            document.getElementById('dropbox-modal').classList.add('hidden');
            API.closeDropbox();
        } else {
            this.showNotification(result?.message || 'Failed to deposit item', 'error');
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

    async cancelListing(listingId) {
        const result = await API.cancelListing(listingId);
        if (result && result.success) {
            this.showNotification('Listing cancelled', 'success');
            this.loadMyListings();
        } else {
            this.showNotification(result?.message || 'Failed to cancel listing', 'error');
        }
    },

    async submitTransfer() {
        const toUsername = document.getElementById('transfer-to-username').value.trim();
        const amount = parseInt(document.getElementById('transfer-amount').value) || 0;

        if (!toUsername) {
            this.showNotification('Please enter a recipient alias', 'error');
            return;
        }

        if (amount <= 0) {
            this.showNotification('Please enter a valid amount', 'error');
            return;
        }

        await API.transferCrypto(toUsername, amount);
        document.getElementById('transfer-crypto-modal').classList.add('hidden');
        document.getElementById('transfer-to-username').value = '';
        document.getElementById('transfer-amount').value = '';
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
