document.addEventListener('DOMContentLoaded', () => {
    // ---- 1. Order Logic ----
    const orderForm = document.getElementById('orderForm');
    const orderStatus = document.getElementById('orderStatus');

    orderForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        // Hide previous messages
        orderStatus.className = 'status-message hidden';
        orderStatus.textContent = '';
        
        // Get Form Data
        const customerName = document.getElementById('customerName').value;
        const address = document.getElementById('address').value;
        const serviceType = document.getElementById('serviceType').value;

        // Simulate API Calls (AJAX/Fetch Boilerplate)
        // Adjust the URL depending on your local / remote backend routes
        try {
            /* 
            const response = await fetch('http://localhost:8080/api/orders', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ customerName, address, serviceType })
            });

            if (!response.ok) throw new Error('Network response was not ok');
            const data = await response.json();
            */
            
            // Simulation Timeout for Retro feel
            orderStatus.textContent = "Mengirim pesan lewat telegraf...";
            orderStatus.classList.remove('hidden');
            orderStatus.classList.add('neo-brutal');

            setTimeout(() => {
                orderStatus.textContent = `Pemesanan Berhasil, Nyonya/Tuan ${customerName}! Kurir kami akan segera menjemput ke ${address}.`;
                orderStatus.classList.remove('status-error');
                orderStatus.classList.add('status-success');
                orderForm.reset();
            }, 1000);

        } catch (error) {
            orderStatus.textContent = "Mohon maaf Nyonya/Tuan, sistem telegram kami sedang dalam perbaikan.";
            orderStatus.classList.remove('status-success');
            orderStatus.classList.add('status-error');
            console.error('Error submitting order:', error);
        }
    });

    // ---- 2. Wallet Logic ----
    const checkWalletBtn = document.getElementById('checkWalletBtn');
    const walletIdInput = document.getElementById('walletId');
    const walletResult = document.getElementById('walletResult');
    const walletBalance = document.getElementById('walletBalance');

    checkWalletBtn.addEventListener('click', async () => {
        const walletId = walletIdInput.value.trim();

        if (!walletId) {
            alert('Harap masukkan ID Pelanggan Anda terlebih dahulu.');
            return;
        }

        // Simulate Fetching Wallet Data
        try {
            /*
            const response = await fetch(`http://localhost:8080/api/wallet/${walletId}`);
            if (!response.ok) throw new Error('Not found');
            const data = await response.json();
            */

            // Simulation
            walletResult.classList.remove('hidden');
            
            // Random balance between 50rb and 500rb
            const randomBalance = Math.floor(Math.random() * (500000 - 50000 + 1) + 50000);
            
            // Format to IDR
            const formattedBalance = new Intl.NumberFormat('id-ID', {
                style: 'currency',
                currency: 'IDR'
            }).format(randomBalance);

            walletBalance.textContent = formattedBalance;

            // Optional: Micro-animation text pop
            walletBalance.style.transform = "scale(1.2)";
            walletBalance.style.transition = "transform 0.2s";
            setTimeout(() => {
                walletBalance.style.transform = "scale(1)";
            }, 300);

        } catch(error) {
            alert('Kami tidak dapat menemukan ID Pelanggan tersebut. Mohon periksa kembali catatannya.');
        }
    });
});
