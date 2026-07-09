const Pages = {
    renderHome(profile) {
        document.getElementById('welcome-name').textContent = profile.username;
        document.getElementById('home-crypto').textContent = (profile.crypto || 0).toLocaleString() + ' CRM';
        document.getElementById('home-jobs').textContent = profile.jobs_completed || 0;
        document.getElementById('home-sold').textContent = profile.items_sold || 0;
        document.getElementById('home-earned').textContent = (profile.total_earned || 0).toLocaleString() + ' CRM';
    },

    renderAbout(profile) {
        document.getElementById('about-username').textContent = profile.username;
        document.getElementById('about-crypto').textContent = (profile.crypto || 0).toLocaleString() + ' CRM';
        document.getElementById('about-jobs').textContent = profile.jobs_completed || 0;
        document.getElementById('about-sold').textContent = profile.items_sold || 0;
        document.getElementById('about-earned').textContent = (profile.total_earned || 0).toLocaleString() + ' CRM';
    },

    updateTopbar(profile) {
        document.getElementById('alias-text').textContent = profile.username;
        document.getElementById('user-crypto').innerHTML =
            '<i class="fas fa-coins"></i> ' + (profile.crypto || 0).toLocaleString() + ' CRM';
    },

    renderCryptoPage(profile) {
        document.getElementById('crypto-total').textContent = (profile.crypto || 0).toLocaleString();
    },

    renderCryptoHistory(history) {
        const container = document.getElementById('crypto-history-list');
        if (!history || history.length === 0) {
            container.innerHTML = `
                <div class="market-empty">
                    <i class="fas fa-inbox"></i>
                    <p>No transactions yet</p>
                </div>`;
            return;
        }

        container.innerHTML = history.map(item => {
            const isPositive = item.type === 'add' || item.type === 'transfer_in';
            const icon = isPositive ? 'fa-plus' : 'fa-minus';
            const iconClass = item.type;
            const amountClass = isPositive ? 'positive' : 'negative';
            const prefix = isPositive ? '+' : '-';
            const time = new Date(item.created_at).toLocaleString();
            const desc = item.description || item.type.replace('_', ' ');

            return `
                <div class="crypto-history-item">
                    <div class="crypto-history-icon ${iconClass}">
                        <i class="fas ${icon}"></i>
                    </div>
                    <div class="crypto-history-info">
                        <span class="crypto-history-desc">${escapeHtml(desc)}</span>
                        <span class="crypto-history-time">${time}</span>
                    </div>
                    <span class="crypto-history-amount ${amountClass}">${prefix}${item.amount.toLocaleString()} CRM</span>
                </div>`;
        }).join('');
    },

    renderCryptoGraph(history) {
        const canvas = document.getElementById('crypto-graph');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        const width = canvas.width;
        const height = canvas.height;

        ctx.clearRect(0, 0, width, height);

        if (!history || history.length === 0) {
            ctx.fillStyle = '#888';
            ctx.font = '14px Segoe UI';
            ctx.textAlign = 'center';
            ctx.fillText('No data yet', width / 2, height / 2);
            return;
        }

        let balance = 0;
        const points = [];
        history.forEach(item => {
            if (item.type === 'add' || item.type === 'transfer_in') {
                balance += item.amount;
            } else {
                balance -= item.amount;
            }
            points.push(balance);
        });

        const maxVal = Math.max(...points, 1);
        const padding = 30;
        const graphW = width - padding * 2;
        const graphH = height - padding * 2;

        ctx.strokeStyle = '#2a2a3a';
        ctx.lineWidth = 1;
        for (let i = 0; i <= 4; i++) {
            const y = padding + (graphH / 4) * i;
            ctx.beginPath();
            ctx.moveTo(padding, y);
            ctx.lineTo(width - padding, y);
            ctx.stroke();
        }

        ctx.beginPath();
        ctx.strokeStyle = '#8b2fc9';
        ctx.lineWidth = 2;
        ctx.shadowColor = 'rgba(139, 47, 201, 0.5)';
        ctx.shadowBlur = 8;

        points.forEach((val, i) => {
            const x = padding + (graphW / Math.max(points.length - 1, 1)) * i;
            const y = padding + graphH - (val / maxVal) * graphH;
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        });
        ctx.stroke();
        ctx.shadowBlur = 0;

        const lastX = padding + graphW;
        const lastY = padding + graphH - (points[points.length - 1] / maxVal) * graphH;
        ctx.beginPath();
        ctx.arc(lastX, lastY, 4, 0, Math.PI * 2);
        ctx.fillStyle = '#e74c3c';
        ctx.fill();

        ctx.fillStyle = '#888';
        ctx.font = '11px Segoe UI';
        ctx.textAlign = 'left';
        ctx.fillText(maxVal.toLocaleString() + ' CRM', 2, padding + 10);
        ctx.fillText('0', 2, height - padding + 10);
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
                <span class="item-price">${listing.price.toLocaleString()} CRM</span>
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
