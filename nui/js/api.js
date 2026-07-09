const API = {
    async fetch(endpoint, data) {
        try {
            const response = await fetch(`https://crime_laptop/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data || {})
            });
            return await response.json();
        } catch (err) {
            return null;
        }
    },

    async register(username) {
        return await this.fetch('register', { username });
    },

    async getProfile() {
        return await this.fetch('getProfile');
    },

    async changeAlias(newAlias) {
        return await this.fetch('changeAlias', { alias: newAlias });
    },

    async getListings(search, filter) {
        return await this.fetch('getListings', { search, filter });
    },

    async createListing(data) {
        return await this.fetch('createListing', data);
    },

    async buyListing(listingId) {
        return await this.fetch('buyListing', { id: listingId });
    },

    async transferCrypto(toUsername, amount) {
        return await this.fetch('transferCrypto', { toUsername, amount });
    },

    async getCryptoHistory() {
        return await this.fetch('getCryptoHistory');
    },

    async getCryptoGraph() {
        return await this.fetch('getCryptoGraph');
    },

    async close() {
        return await this.fetch('close');
    }
};
