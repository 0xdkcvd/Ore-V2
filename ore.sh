#!/bin/bash

# Fungsi untuk memeriksa apakah skrip dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini memerlukan izin root untuk dijalankan."
    echo "Silakan coba menggunakan 'sudo -i' untuk beralih ke root, lalu jalankan skrip ini lagi."
    exit 1
fi

# Fungsi untuk instalasi node Solana
function install_node() {
    # Memperbarui sistem dan menginstal paket-paket yang diperlukan
    echo "Memperbarui paket-paket sistem..."
    sudo apt update && sudo apt upgrade -y
    echo "Menginstal alat dan dependensi yang diperlukan..."
    sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen

    # Menginstal Rust dan Cargo
    echo "Menginstal Rust dan Cargo..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env

    # Menginstal Solana CLI
    echo "Menginstal Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

    # Menambahkan Solana CLI ke PATH jika belum ada
    if ! command -v solana-keygen &> /dev/null; then
        echo "Menambahkan Solana CLI ke PATH..."
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    # Membuat pasangan kunci Solana
    echo "Membuat pasangan kunci Solana..."
    solana-keygen new --derivation-path m/44'/501'/0'/0' --force | tee solana-keygen-output.txt

    # Meminta konfirmasi dari pengguna setelah backup selesai
    echo "Pastikan Anda telah mencadangkan kata-kata pemulihan dan kunci pribadi yang ditampilkan di atas."
    echo "Setelah cadangan selesai, masukkan 'yes' untuk melanjutkan:"

    read -p "" user_confirmation

    if [[ "$user_confirmation" != "yes" ]]; then
        echo "Skrip dihentikan. Pastikan Anda mencadangkan informasi Anda sebelum menjalankan skrip lagi."
        exit 1
    fi

    # Menginstal Ore CLI
    echo "Menginstal Ore CLI..."
    cargo install ore-cli

    # Memeriksa dan menambahkan path Solana ke .bashrc jika belum ada
    grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

    # Memeriksa dan menambahkan path Cargo ke .bashrc jika belum ada
    grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

    # Memuat ulang .bashrc untuk menerapkan perubahan
    source ~/.bashrc

    # Meminta RPC address dan pengaturan lainnya dari pengguna
    read -p "Masukkan alamat RPC kustom, atau tekan Enter untuk menggunakan https://api.mainnet-beta.solana.com: " custom_rpc
    RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

    read -p "Masukkan jumlah thread yang ingin Anda gunakan untuk menambang (default 1): " custom_threads
    THREADS=${custom_threads:-1}

    read -p "Masukkan biaya prioritas transaksi (default 1): " custom_priority_fee
    PRIORITY_FEE=${custom_priority_fee:-1}

    # Memulai penambangan menggunakan screen dan Ore CLI
    session_name="ore"
    echo "Memulai penambangan dengan nama sesi $session_name..."

    start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'Proses keluar secara tidak normal, menunggu restart' >&2; sleep 1; done"
    screen -dmS "$session_name" bash -c "$start"

    echo "Proses penambangan telah dimulai di sesi screen bernama $session_name."
    echo "Gunakan 'screen -r $session_name' untuk terhubung kembali ke sesi ini."
}

# Fungsi untuk mengecek dan menginstal dependensi
function check_and_install_dependencies() {
    # Memeriksa apakah Rust dan Cargo sudah diinstal
    if ! command -v cargo &> /dev/null; then
        echo "Rust dan Cargo belum diinstal, sedang menginstal..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source $HOME/.cargo/env
    else
        echo "Rust dan Cargo sudah diinstal."
    fi

    # Memeriksa apakah Solana CLI sudah diinstal
    if ! command -v solana-keygen &> /dev/null; then
        echo "Solana CLI belum diinstal, sedang menginstal..."
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    else
        echo "Solana CLI sudah diinstal."
    fi

    # Memeriksa dan menginstal Ore CLI jika belum ada
    if ! ore -V &> /dev/null; then
        echo "Ore CLI belum diinstal, sedang menginstal..."
        cargo install ore-cli
    else
        echo "Ore CLI sudah diinstal."
    fi

    # Menambahkan path Solana ke .bashrc jika belum ada
    grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

    # Menambahkan path Cargo ke .bashrc jika belum ada
    grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

    # Memuat ulang .bashrc untuk menerapkan perubahan
    source ~/.bashrc
}

# Fungsi untuk menampilkan menu utama
function main_menu() {
    while true; do
        clear
        echo "================== Ore V2 Node Installation =================="
        echo "NANANUNU.xyz"
        echo "=============================================================="
        echo "Pilih operasi yang ingin Anda lakukan:"
        echo "1. Instalasi node baru"
        echo "2. Impor dompet dan mulai"
        echo "3. Mulai node tunggal"
        echo "4. Lihat hadiah penambangan"
        echo "5. Klaim hadiah penambangan"
        echo "6. Periksa log node"
        echo "7. Multiple wallet (instalasi lingkungan)"
        echo "8. Multiple wallet (tanpa memeriksa lingkungan)"
        echo "9. Multiple wallet (lihat hadiah)"
        echo "10. Multiple wallet (klaim hadiah)"
        echo "11. Ubah pengaturan RPC dan multiple wallet (otomatis)"
        echo "12. Benchmark kekuatan penambangan"
        echo "=============================================================="
        read -p "Masukkan pilihan (1-12): " OPTION

        case $OPTION in
        1) install_node ;;
        2) export_wallet ;;
        3) start ;;
        4) view_rewards ;;
        5) claim_rewards ;;
        6) check_logs ;;
        7) multiple ;;
        8) lonely ;;
        9) check_multiple ;;
        10) cliam_multiple ;;
        11) rerun_rpc ;;
        12) benchmark ;;
        esac

        echo "Tekan tombol apa saja untuk kembali ke menu utama..."
        read -n 1
    done
}

# Memanggil menu utama
main_menu
