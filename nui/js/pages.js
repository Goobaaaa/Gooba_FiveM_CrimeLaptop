const Pages = {
    renderHome(profile) {
        document.getElementById('welcome-name').textContent = profile.username;
        document.getElementById('home-balance').textContent = '$' + (profile.balance || 0).toLocaleString();
        document.getElementById('home-jobs').textContent = profile.jobs_completed || 0;
        document.getElementById('home-sold').textContent = profile.items_sold || 0;
        document.getElementById('home-earned').textContent = '$' + (profile.total_earned || 0).toLocaleString();
    },

    renderAbout(profile) {
        document.getElementById('about-username').textContent = profile.username;
        document.getElementById('about-balance').textContent = '$' + (profile.balance || 0).toLocaleString();
        document.getElementById('about-jobs').textContent = profile.jobs_completed || 0;
        document.getElementById('about-sold').textContent = profile.items_sold || 0;
        document.getElementById('about-earned').textContent = '$' + (profile.total_earned || 0).toLocaleString();
    },

    updateTopbar(profile) {
        document.getElementById('alias-text').textContent = profile.username;
        document.getElementById('user-balance').innerHTML =
            '<i class="fas fa-wallet"></i> $' + (profile.balance || 0).toLocaleString();
    },

    renderListings(listings) {
        const container = document.getElementById('market-listings');
        if (!listings || listings.length === 0) {
            container.innerHTML = `
                <div class="market-empty">
                    <i class="fas fa-box-open"></i>
                    <p>No listings available</p>
                </div>`;
            return;
        }

        container.innerHTML = listings.map(listing => `
            <div class="market-row" data-id="${listing.id}">
                <span class="seller-name">${escapeHtml(listing.seller_username)}</span>
                <span>${escapeHtml(listing.item_label)} (${escapeHtml(listing.item_name)})</span>
                <span>${listing.amount}</span>
                <span class="item-price">$${listing.price.toLocaleString()}</span>
                <span>
                    <button class="btn-buy" onclick="App.buyListing(${listing.id})">
                        <i class="fas fa-shopping-cart"></i> Buy
                    </button>
                </span>
            </div>
        `).join('');
    },

    populateFilter(listings) {
        const select = document.getElementById('market-filter');
        const items = [...new Set(listings.map(l => l.item_name))];
        select.innerHTML = '<option value="all">All Items</option>';
        items.forEach(item => {
            const label = listings.find(l => l.item_name === item)?.item_label || item;
            select.innerHTML += `<option value="${item}">${label}</option>`;
        });
    }
};

function escapeHtml(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}
