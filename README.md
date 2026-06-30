# 🇹🇭 Thai App Market — ตลาดแอปไทย

> เว็บขายแอปพลิเคชันสไตล์ไทยโมเดิร์น สำหรับครีเอเตอร์สายคอนเทนต์
> รองรับทั้ง **Supabase (Production)** และ **localStorage (Development)**

---

## ✨ ฟีเจอร์

| ฟีเจอร์ | รายละเอียด |
|---------|-----------|
| 🎨 ลายไทยโมเดิร์น | SVG Pattern ลายกระหนก (Kranok) ประยุกต์ |
| 🎬 ปุ่มเอฟเฟกต์ Ripple | ripple + hover glow + scale bounce |
| 🔐 ระบบสมาชิก | Register/Login ผ่าน Supabase Auth |
| 🛒 ตะกร้าสินค้า | เพิ่ม/ลด/ลบ ซิงค์กับ Supabase Database |
| 💳 ชำระเงินจำลอง | ฟอร์ม + หน้าสำเร็จ |
| 📱 Responsive | Mobile / Tablet / Desktop |

---

## 🚀 Deploy บน Vercel + Supabase (ฟรี 24 ชม.)

### ขั้นตอนที่ 1: สร้าง Supabase Project

1. ไปที่ **[supabase.com](https://supabase.com)** → **Start new project**
2. ตั้งชื่อ project เช่น `thaiapp-market`
3. จดจำ **Database Password** ไว้
4. รอจน project พร้อม (ประมาณ 1-2 นาที)

### ขั้นตอนที่ 2: รัน Schema

1. ไปที่ **Supabase Dashboard → SQL Editor**
2. เปิดไฟล์ `supabase/schema.sql` (ในโปรเจกต์นี้)
3. วางโค้ดทั้งหมด แล้วกด **Run**
4. ระบบจะสร้างตารางและเพิ่มข้อมูลสินค้าตัวอย่างให้อัตโนมัติ

### ขั้นตอนที่ 3: จับค่า API Keys

1. ไปที่ **Supabase Dashboard → Settings → API**
2. จดค่าเหล่านี้:
   - **Project URL** (เช่น `https://abc123.supabase.co`)
   - **anon public** (一串ตัวอักษรยาวๆ)

### ขั้นตอนที่ 4: Deploy ไป Vercel

#### วิธีที่ 1: ใช้ Git (แนะนำ)
```bash
git init
git add .
git commit -m "first commit"
# สร้าง repo บน GitHub แล้ว push
git remote add origin https://github.com/yourusername/thaiapp-market.git
git push -u origin main
```

จากนั้น:
1. ไปที่ **[vercel.com](https://vercel.com)** → **Add New Project**
2. เชื่อมต่อ GitHub repo
3. ไปที่ **Settings → Environment Variables** แล้วเพิ่ม:
   - `SUPABASE_URL` = Project URL จากข้อ 3
   - `SUPABASE_ANON_KEY` = anon public key
4. กด **Deploy** ✨

#### วิธีที่ 2: ใช้ Vercel CLI
```bash
# ติดตั้ง Vercel CLI
npm install -g vercel

# login
vercel login

# deploy
vercel --prod

# ระหว่างที่ถาม ให้ตั้งค่า Environment Variables:
#   SUPABASE_URL = https://your-project.supabase.co
#   SUPABASE_ANON_KEY = your-anon-key
```

### ✅ เสร็จสิ้น!

เว็บคุณจะออนไลน์ที่ `https://thaiapp-market.vercel.app` (หรือชื่อที่ Vercel สุ่มให้)

---

## 🛠️ การพัฒนาในเครื่อง local

### เปิดไฟล์ตรงๆ (ไม่ต้องใช้เซิร์ฟเวอร์)
```bash
# เปิด index.html ในเบราว์เซอร์
start index.html   # Windows
open index.html    # Mac
```

### หรือใช้ HTTP Server (แนะนำ)
```bash
npx serve .
# แล้วเปิด http://localhost:3000
```

> **หมายเหตุ:** ถ้าไม่ตั้งค่า Supabase ระบบจะใช้ localStorage อัตโนมัติ
> ฟีเจอร์ทั้งหมดทำงานได้ปกติ แต่ข้อมูลจะอยู่แค่ในเครื่องคุณเท่านั้น

---

## 📁 โครงสร้างไฟล์

```
📂 thaiapp-market/
├── 📄 index.html          # 👈 เว็บไซต์หลัก (HTML + CSS + JS ในไฟล์เดียว)
├── 📄 package.json        # npm config
├── 📄 vercel.json         # Vercel deployment config
├── 📄 .env.example        # ตัวอย่าง Environment Variables
├── 📂 api/
│   └── 📄 config.js       # Vercel Serverless Function (inject env vars)
├── 📂 supabase/
│   └── 📄 schema.sql      # Database schema + seed data
└── 📄 README.md           # ไฟล์นี้
```

---

## 🧪 โหมดการทำงาน

### โหมด 1: localStorage (Development)
- **เมื่อ:** ไม่ได้ตั้งค่า Supabase
- **ข้อดี:** เปิดไฟล์ตรงๆ ก็ใช้ได้ ไม่ต้องพึ่ง backend
- **ข้อเสีย:** ข้อมูลหายเมื่อเปลี่ยนเครื่องหรือล้างแคช

### โหมด 2: Supabase (Production)
- **เมื่อ:** ตั้งค่า `SUPABASE_URL` + `SUPABASE_ANON_KEY`
- **ข้อดี:** ข้อมูลอยู่บนคลาวด์ ใช้ได้ทุกที่ ทุกอุปกรณ์
- **การเชื่อมต่อ:** Browser → Vercel Serverless Function → Supabase

---

## 🔮 ของที่อยากเพิ่มในอนาคต

- [ ] ระบบ License Key สำหรับเปิดใช้งานแอป
- [ ] ส่งอีเมลยืนยัน + ใบเสร็จอัตโนมัติ
- [ ] ระบบ Subscription / ต่ออายุ
- [ ] Admin Dashboard
- [ ] รองรับหลายภาษา (EN/CN)
- [ ] PWA (ติดตั้งบนมือถือได้)
- [ ] ค้นหา + กรองแอปขั้นสูง
- [ ] Dark Mode

---

## 📞 ติดต่อ

- Email: support@thaiappmarket.com
- Website: [https://thaiapp-market.vercel.app](https://thaiapp-market.vercel.app)

---

> 🇹🇭 Thai App Market — สร้างด้วย ❤️ เพื่อครีเอเตอร์ไทย
