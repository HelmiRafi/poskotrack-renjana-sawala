# PoskoTrack — Sistem Izin Keluar Posko KKN

Aplikasi web responsif untuk mendata izin keluar posko, foto bukti, jam keluar/kembali, kuota maksimal 2 catatan per orang per hari, dan rekap CSV untuk ketua/sekretaris.

## Fitur
- Dashboard ringkasan aktivitas hari ini dan status anggota di luar posko.
- Form tanggal, alasan, tujuan, jam keluar, jam kembali, dan unggah foto.
- Maksimal 2 catatan keluar per pengguna per hari (divalidasi di aplikasi dan database).
- Status “Sedang di luar” dan tombol “Catat kembali”.
- Rekap semua anggota, filter tanggal/nama, tautan foto bukti, ekspor CSV untuk Excel/Google Sheets.
- Login dan pendaftaran email, profil per pengguna, role anggota/ketua/sekretaris.
- UI responsif untuk HP dan desktop.
- Mode demo tanpa konfigurasi hanya untuk mencoba tampilan; datanya tidak tersinkron lintas perangkat.

## A. Jalankan lokal
1. Instal Node.js versi LTS.
2. Ekstrak ZIP lalu buka terminal di folder proyek.
3. Jalankan `npm install`.
4. Salin `.env.example` menjadi `.env` dan isi kredensial Supabase.
5. Jalankan `npm run dev`, buka URL yang tampil di terminal.

## B. Aktifkan database & login (gratis dengan batas layanan Supabase)
1. Buat proyek di https://supabase.com/.
2. Buka **SQL Editor**, jalankan isi `supabase/schema.sql`.
3. Buka **Storage** lalu buat bucket bernama `exit-proofs`. Untuk mengikuti konfigurasi awal ini, atur bucket sebagai **Public**. Foto bisa dilihat oleh siapa pun yang memiliki URL; jangan gunakan untuk bukti yang sensitif. Untuk privasi lebih kuat, jadikan bucket private dan ubah aplikasi agar memakai signed URLs.
4. Di **Project Settings → API**, salin Project URL dan `anon`/publishable key ke file `.env`:
   ```
   VITE_SUPABASE_URL=https://PROJECT_ID.supabase.co
   VITE_SUPABASE_ANON_KEY=ANON_KEY_ANDA
   ```
   Jangan pernah menaruh `service_role` key di frontend.
5. Di **Authentication → URL Configuration**, tambahkan URL lokal dan URL deployment ke Site URL / Redirect URLs sesuai kebutuhan.
6. Jalankan `npm run dev`, daftar akun setiap anggota memakai email masing-masing.

## C. Deploy gratis ke Vercel
1. Unggah folder proyek ini ke repositori GitHub.
2. Login ke https://vercel.com/ dan impor repositori.
3. Framework preset: Vite. Build command `npm run build`; output directory `dist`.
4. Tambahkan Environment Variables `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY`, lalu Deploy.
5. Set URL Vercel di Supabase Authentication → URL Configuration. Setiap anggota membuka URL yang sama dan login memakai akun masing-masing.

## D. Jadikan ketua / sekretaris
Akun baru otomatis berperan `anggota`. Setelah ketua dan sekretaris mendaftar, buka Supabase → Table Editor → `profiles`, ubah kolom `role` untuk akun yang tepat menjadi `ketua` atau `sekretaris`. Jangan berikan akses admin Supabase kepada anggota biasa.

## E. Penting untuk operasional
- Setiap catatan keluar dihitung sebagai satu kuota. Saat kembali, anggota menekan **Catat kembali** atau jam kembali bisa diisi saat membuat catatan.
- Rekap dapat diekspor menjadi CSV. Untuk laporan formal, buka CSV dengan Excel/Google Sheets dan simpan sebagai PDF.
- Pastikan semua anggota mengisi data sesuai kenyataan dan memahami aturan privasi foto.
- Ini starter project siap dikembangkan, bukan layanan hosting yang sudah dibuatkan akun atau dideploy. Anda perlu membuat proyek Supabase/Vercel dan memasukkan kredensial sendiri.
